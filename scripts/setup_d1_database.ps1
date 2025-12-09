# Setup D1 Database for Cloudflare Worker
# Creates D1 database, migrates schema, and optionally syncs data from SQLite

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$workerDir = Join-Path $projectRoot "worker"
$wranglerToml = Join-Path $projectRoot "wrangler.toml"
$schemaFile = Join-Path $workerDir "schema.sql"
$sqliteDb = Join-Path $projectRoot "aurum_harmony.db"

Write-Host "=== D1 Database Setup for AurumHarmony ===" -ForegroundColor Cyan
Write-Host ""

# Check if wrangler is available
$wranglerCmd = "wrangler"
$useNpx = $false

try {
    $wranglerVersion = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Wrangler found: $wranglerVersion" -ForegroundColor Green
    } else {
        throw "Wrangler not found globally"
    }
} catch {
    Set-Location $workerDir
    if (Test-Path "node_modules\.bin\wrangler.cmd") {
        $wranglerCmd = "npx wrangler"
        $useNpx = $true
        Write-Host "✅ Wrangler found (local): $(npx wrangler --version 2>&1)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Wrangler not found. Installing..." -ForegroundColor Yellow
        npm install 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $wranglerCmd = "npx wrangler"
            $useNpx = $true
            Write-Host "✅ Wrangler installed" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
            exit 1
        }
    }
}

Set-Location $projectRoot

# Step 1: Create D1 Database
Write-Host "`n[1/4] Creating D1 Database..." -ForegroundColor Yellow
Write-Host "Database name: aurum-harmony-db" -ForegroundColor Gray

Write-Host "Creating D1 database..." -ForegroundColor Gray
$createOutput = if ($useNpx) {
    Set-Location $workerDir
    npx wrangler d1 create aurum-harmony-db 2>&1 | Tee-Object -Variable fullOutput
    $fullOutput | Out-String
} else {
    wrangler d1 create aurum-harmony-db 2>&1 | Tee-Object -Variable fullOutput
    $fullOutput | Out-String
}

Set-Location $projectRoot

# Try multiple patterns to extract database_id
$databaseId = $null

# Pattern 1: database_id = "xxx"
if ($createOutput -match 'database_id\s*=\s*"([^"]+)"') {
    $databaseId = $matches[1]
}

# Pattern 2: "database_id": "xxx" (JSON format)
if (-not $databaseId -and $createOutput -match '"database_id"\s*:\s*"([^"]+)"') {
    $databaseId = $matches[1]
}

# Pattern 3: database_id: xxx (YAML format)
if (-not $databaseId -and $createOutput -match 'database_id:\s*([a-f0-9\-]+)') {
    $databaseId = $matches[1]
}

# Pattern 4: Look for UUID-like pattern after "database_id"
if (-not $databaseId -and $createOutput -match 'database_id[^\w]*([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') {
    $databaseId = $matches[1]
}

# Pattern 5: Look for any UUID in the output (last resort)
if (-not $databaseId -and $createOutput -match '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') {
    $potentialIds = [regex]::Matches($createOutput, '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})')
    if ($potentialIds.Count -gt 0) {
        # Take the last UUID found (usually the database_id)
        $databaseId = $potentialIds[-1].Groups[1].Value
    }
}

if ($databaseId) {
    Write-Host "✅ Database created!" -ForegroundColor Green
    Write-Host "   Database ID: $databaseId" -ForegroundColor Gray
    
    # Update wrangler.toml
    Write-Host "`n[2/4] Updating wrangler.toml..." -ForegroundColor Yellow
    $tomlContent = Get-Content $wranglerToml -Raw
    $tomlContent = $tomlContent -replace 'database_id = ""', "database_id = `"$databaseId`""
    Set-Content $wranglerToml -Value $tomlContent -NoNewline
    Write-Host "✅ wrangler.toml updated with database ID" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not automatically extract database ID from output" -ForegroundColor Yellow
    Write-Host "`nFull output:" -ForegroundColor Gray
    Write-Host $createOutput -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please look for 'database_id' in the output above." -ForegroundColor Yellow
    Write-Host "It should look like: database_id = \"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\"" -ForegroundColor Gray
    Write-Host ""
    $databaseId = Read-Host "Enter the database_id manually (or press Enter to skip)"
    if ($databaseId -and $databaseId.Trim() -ne "") {
        $tomlContent = Get-Content $wranglerToml -Raw
        $tomlContent = $tomlContent -replace 'database_id = ""', "database_id = `"$databaseId.Trim()`""
        Set-Content $wranglerToml -Value $tomlContent -NoNewline
        Write-Host "✅ wrangler.toml updated" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Skipping database_id update. You can add it manually to wrangler.toml" -ForegroundColor Yellow
        Write-Host "   Look for the database_id in the output above and update wrangler.toml" -ForegroundColor Gray
    }
}

# Step 3: Migrate Schema
Write-Host "`n[3/4] Migrating database schema..." -ForegroundColor Yellow
if (-not (Test-Path $schemaFile)) {
    Write-Host "❌ Schema file not found: $schemaFile" -ForegroundColor Red
    exit 1
}

# Check authentication before migrating
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
    Write-Host "  .\scripts\setup_d1_database.ps1" -ForegroundColor White
    exit 1
} else {
    Write-Host "✅ Authenticated" -ForegroundColor Green
}

Write-Host "Running schema migration (remote)..." -ForegroundColor Gray
Write-Host "   Note: Database will be temporarily unavailable during migration" -ForegroundColor DarkGray
# Use --remote flag to avoid local database crashes
# Auto-confirm the prompt by piping 'y' to the command
if ($useNpx) {
    Set-Location $workerDir
    Write-Host "   Running: npx wrangler d1 execute aurum-harmony-db --remote --file=schema.sql" -ForegroundColor Gray
    "y" | npx wrangler d1 execute aurum-harmony-db --remote --file=$schemaFile
} else {
    Write-Host "   Running: wrangler d1 execute aurum-harmony-db --remote --file=$schemaFile" -ForegroundColor Gray
    "y" | wrangler d1 execute aurum-harmony-db --remote --file=$schemaFile
}

Set-Location $projectRoot

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Schema migrated successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Schema migration may have failed. Check output above." -ForegroundColor Yellow
}

# Step 4: Sync Data from SQLite (Optional)
Write-Host "`n[4/4] Data Migration..." -ForegroundColor Yellow
if (Test-Path $sqliteDb) {
    Write-Host "Found SQLite database: $sqliteDb" -ForegroundColor Gray
    $syncData = Read-Host "Do you want to sync data from SQLite to D1? (y/N)"
    
    if ($syncData -eq "y" -or $syncData -eq "Y") {
        Write-Host "`nCreating data migration script..." -ForegroundColor Gray
        
        # Create Python script to export SQLite data
        $exportScript = @"
import sqlite3
import json
import sys
from datetime import datetime

db_path = r"$sqliteDb"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

# Export users
print("Exporting users...")
users = []
cursor.execute("SELECT * FROM users")
for row in cursor.fetchall():
    user = dict(row)
    # Convert dates to ISO strings
    if user.get('date_of_birth'):
        user['date_of_birth'] = user['date_of_birth']
    if user.get('anniversary'):
        user['anniversary'] = user['anniversary']
    if user.get('created_at'):
        user['created_at'] = user['created_at']
    if user.get('updated_at'):
        user['updated_at'] = user['updated_at']
    # Convert booleans to integers for D1
    user['is_admin'] = 1 if user.get('is_admin') else 0
    user['is_active'] = 1 if user.get('is_active') else 0
    users.append(user)

print(f"Found {len(users)} users")

# Export sessions
print("Exporting sessions...")
sessions = []
cursor.execute("SELECT * FROM sessions")
for row in cursor.fetchall():
    session = dict(row)
    sessions.append(session)

print(f"Found {len(sessions)} sessions")

# Export broker_credentials
print("Exporting broker credentials...")
credentials = []
cursor.execute("SELECT * FROM broker_credentials")
for row in cursor.fetchall():
    cred = dict(row)
    if cred.get('is_active'):
        cred['is_active'] = 1 if cred.get('is_active') else 0
    credentials.append(cred)

print(f"Found {len(credentials)} broker credentials")

conn.close()

# Generate SQL insert statements
sql_statements = []

# Insert users
for user in users:
    cols = ', '.join([f'`{k}`' for k in user.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in user.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO users ({cols}) VALUES ({values});")

# Insert sessions
for session in sessions:
    cols = ', '.join([f'`{k}`' for k in session.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in session.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO sessions ({cols}) VALUES ({values});")

# Insert broker_credentials
for cred in credentials:
    cols = ', '.join([f'`{k}`' for k in cred.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in cred.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO broker_credentials ({cols}) VALUES ({values});")

# Write to file
output_file = r"$projectRoot\worker\data_migration.sql"
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('-- Data migration from SQLite to D1\n')
    f.write('-- Generated: ' + datetime.now().isoformat() + '\n\n')
    f.write('\n'.join(sql_statements))

print(f"\n✅ Data export complete!")
print(f"SQL file: {output_file}")
print(f"Total statements: {len(sql_statements)}")
"@

        $exportScriptPath = Join-Path $projectRoot "_local\temp_export_data.py"
        $exportScriptPathDir = Split-Path $exportScriptPath
        if (-not (Test-Path $exportScriptPathDir)) {
            New-Item -ItemType Directory -Path $exportScriptPathDir -Force | Out-Null
        }
        Set-Content $exportScriptPath -Value $exportScript
        
        Write-Host "Running data export..." -ForegroundColor Gray
        python $exportScriptPath
        
        if ($LASTEXITCODE -eq 0) {
            $migrationFile = Join-Path $projectRoot "worker\data_migration.sql"
            if (Test-Path $migrationFile) {
                Write-Host "✅ Data export complete!" -ForegroundColor Green
                Write-Host "`nImporting data to D1 (remote)..." -ForegroundColor Gray
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
                    Write-Host "✅ Data imported successfully!" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  Data import may have failed. Check output above." -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ Migration file not created" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Data export failed" -ForegroundColor Red
        }
        
        # Cleanup
        if (Test-Path $exportScriptPath) {
            Remove-Item $exportScriptPath -Force
        }
    } else {
        Write-Host "Skipping data migration. You can run it later with:" -ForegroundColor Gray
        Write-Host "  .\scripts\sync_sqlite_to_d1.ps1" -ForegroundColor Cyan
    }
} else {
    Write-Host "SQLite database not found: $sqliteDb" -ForegroundColor Yellow
    Write-Host "Skipping data migration." -ForegroundColor Gray
}

Write-Host "`n✅ D1 Database Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy worker: .\start-all.ps1 → Option 6" -ForegroundColor White
Write-Host "  2. Test login: The worker should now work with D1 database!" -ForegroundColor White
Write-Host ""
Write-Host "💡 Note: Make sure JWT_SECRET is set in Cloudflare Dashboard:" -ForegroundColor Yellow
Write-Host "   wrangler secret put JWT_SECRET" -ForegroundColor Gray
