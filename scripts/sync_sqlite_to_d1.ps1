# Sync Data from SQLite to D1 Database
# Exports data from local SQLite and imports to D1

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$workerDir = Join-Path $projectRoot "worker"
$sqliteDb = Join-Path $projectRoot "aurum_harmony.db"

Write-Host "=== Sync SQLite to D1 Database ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $sqliteDb)) {
    Write-Host "❌ SQLite database not found: $sqliteDb" -ForegroundColor Red
    exit 1
}

Write-Host "Found SQLite database: $sqliteDb" -ForegroundColor Green

# Check if wrangler is available
$wranglerCmd = "wrangler"
$useNpx = $false

try {
    $wranglerVersion = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wranglerCmd = "wrangler"
    } else {
        throw "Not found"
    }
} catch {
    Set-Location $workerDir
    if (Test-Path "node_modules\.bin\wrangler.cmd") {
        $wranglerCmd = "npx wrangler"
        $useNpx = $true
    } else {
        Write-Host "❌ Wrangler not found. Please install it first." -ForegroundColor Red
        exit 1
    }
}

Set-Location $projectRoot

# Check authentication before syncing
Write-Host "Checking Cloudflare authentication..." -ForegroundColor Yellow
$authCheck = if ($useNpx) {
    Set-Location $workerDir
    npx wrangler whoami 2>&1 | Out-String
} else {
    wrangler whoami 2>&1 | Out-String
}
Set-Location $projectRoot

if ($authCheck -match "You are not authenticated" -or $authCheck -match "CLOUDFLARE_API_TOKEN" -or $LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not authenticated with Cloudflare" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To authenticate, run:" -ForegroundColor Cyan
    Write-Host "  cd worker" -ForegroundColor White
    Write-Host "  npx wrangler login" -ForegroundColor White
    Write-Host "  cd .." -ForegroundColor White
    Write-Host "  .\scripts\sync_sqlite_to_d1.ps1" -ForegroundColor White
    exit 1
} else {
    Write-Host "✅ Authenticated" -ForegroundColor Green
}

# Create Python export script
$exportScript = @"
import sqlite3
import json
from datetime import datetime

db_path = r"$sqliteDb"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

print("Exporting users...")
users = []
cursor.execute("SELECT * FROM users")
for row in cursor.fetchall():
    user = dict(row)
    user['is_admin'] = 1 if user.get('is_admin') else 0
    user['is_active'] = 1 if user.get('is_active') else 0
    users.append(user)
print(f"Found {len(users)} users")

print("Exporting sessions...")
sessions = []
cursor.execute("SELECT * FROM sessions")
for row in cursor.fetchall():
    sessions.append(dict(row))
print(f"Found {len(sessions)} sessions")

print("Exporting broker credentials...")
credentials = []
cursor.execute("SELECT * FROM broker_credentials")
for row in cursor.fetchall():
    cred = dict(row)
    cred['is_active'] = 1 if cred.get('is_active') else 0
    credentials.append(cred)
print(f"Found {len(credentials)} credentials")

conn.close()

# Generate SQL
sql_statements = []

for user in users:
    cols = ', '.join([f'`{k}`' for k in user.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in user.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO users ({cols}) VALUES ({values});")

for session in sessions:
    cols = ', '.join([f'`{k}`' for k in session.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in session.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO sessions ({cols}) VALUES ({values});")

for cred in credentials:
    cols = ', '.join([f'`{k}`' for k in cred.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in cred.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO broker_credentials ({cols}) VALUES ({values});")

output_file = r"$projectRoot\worker\data_migration.sql"
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('-- Data migration from SQLite to D1\n')
    f.write('-- Generated: ' + datetime.now().isoformat() + '\n\n')
    f.write('\n'.join(sql_statements))

print(f"\n✅ Export complete: {output_file}")
print(f"Total statements: {len(sql_statements)}")
"@

$exportScriptPath = Join-Path $projectRoot "_local\temp_export_data.py"
$exportScriptPathDir = Split-Path $exportScriptPath
if (-not (Test-Path $exportScriptPathDir)) {
    New-Item -ItemType Directory -Path $exportScriptPathDir -Force | Out-Null
}
Set-Content $exportScriptPath -Value $exportScript

Write-Host "Exporting data from SQLite..." -ForegroundColor Yellow
python $exportScriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Export failed" -ForegroundColor Red
    exit 1
}

$migrationFile = Join-Path $projectRoot "worker\data_migration.sql"
if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not created" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Data exported!" -ForegroundColor Green
Write-Host "`nImporting to D1 (remote)..." -ForegroundColor Yellow
Write-Host "   Note: Database will be temporarily unavailable during import" -ForegroundColor DarkGray

# Use --remote flag to avoid local database crashes
# Auto-confirm the prompt by piping 'y' to the command
if ($useNpx) {
    Set-Location $workerDir
    Write-Host "   Running: npx wrangler d1 execute aurum-harmony-db --remote --file=data_migration.sql" -ForegroundColor Gray
    "y" | npx wrangler d1 execute aurum-harmony-db --remote --file=$migrationFile
} else {
    Write-Host "   Running: wrangler d1 execute aurum-harmony-db --remote --file=$migrationFile" -ForegroundColor Gray
    "y" | wrangler d1 execute aurum-harmony-db --remote --file=$migrationFile
}

Set-Location $projectRoot

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Data sync complete!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Import may have failed. Check output above." -ForegroundColor Yellow
}

# Cleanup
if (Test-Path $exportScriptPath) {
    Remove-Item $exportScriptPath -Force
}

