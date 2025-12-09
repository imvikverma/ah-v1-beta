# Simple D1 Schema Migration Script
# Migrates the database schema to D1 (assumes database already exists)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$workerDir = Join-Path $projectRoot "worker"
$schemaFile = Join-Path $workerDir "schema.sql"
$wranglerToml = Join-Path $projectRoot "wrangler.toml"

Write-Host "=== D1 Schema Migration ===" -ForegroundColor Cyan
Write-Host ""

# Check if schema file exists
if (-not (Test-Path $schemaFile)) {
    Write-Host "❌ Schema file not found: $schemaFile" -ForegroundColor Red
    exit 1
}

# Check if wrangler.toml exists
if (-not (Test-Path $wranglerToml)) {
    Write-Host "❌ wrangler.toml not found: $wranglerToml" -ForegroundColor Red
    Write-Host "   Please ensure wrangler.toml exists in the project root" -ForegroundColor Yellow
    exit 1
}

# Check database_id
$tomlContent = Get-Content $wranglerToml -Raw
if ($tomlContent -notmatch 'database_id = "([^"]+)"') {
    Write-Host "⚠️  Database ID not set in wrangler.toml" -ForegroundColor Yellow
    Write-Host "   The database may not exist yet." -ForegroundColor Gray
    Write-Host "   Run: .\scripts\setup_d1_database.ps1 first" -ForegroundColor Cyan
    exit 1
}

$databaseId = $matches[1]
Write-Host "✅ Database ID found: $databaseId" -ForegroundColor Green
Write-Host "   Database name: aurum-harmony-db" -ForegroundColor Gray
Write-Host ""

# Find wrangler
$wranglerCmd = $null
$useNpx = $false

# Try global wrangler first
try {
    $null = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wranglerCmd = "wrangler"
        Write-Host "✅ Using global wrangler" -ForegroundColor Green
    }
} catch {
    # Try local npx
    Set-Location $workerDir
    if (Test-Path "node_modules\.bin\wrangler.cmd") {
        $wranglerCmd = "npx wrangler"
        $useNpx = $true
        Write-Host "✅ Using local wrangler (npx)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Wrangler not found. Installing..." -ForegroundColor Yellow
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $wranglerCmd = "npx wrangler"
                $useNpx = $true
                Write-Host "✅ Wrangler installed" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to install wrangler" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "❌ npm not found. Please install Node.js or wrangler globally" -ForegroundColor Red
            Write-Host "   Install: npm install -g wrangler" -ForegroundColor Cyan
            exit 1
        }
    }
}

Set-Location $projectRoot

# Check authentication before migrating
Write-Host "`nChecking Cloudflare authentication..." -ForegroundColor Yellow
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
    Write-Host "To authenticate, choose one:" -ForegroundColor Cyan
    Write-Host "  Option 1: Interactive login (recommended)" -ForegroundColor White
    Write-Host "    cd worker" -ForegroundColor Gray
    Write-Host "    npx wrangler login" -ForegroundColor Gray
    Write-Host "    cd .." -ForegroundColor Gray
    Write-Host "    .\scripts\migrate_d1_schema.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Option 2: Set API token" -ForegroundColor White
    Write-Host "    Get token from: https://dash.cloudflare.com/profile/api-tokens" -ForegroundColor Gray
    Write-Host "    Create token with: Account → D1 → Edit permissions" -ForegroundColor Gray
    Write-Host "    Then set: `$env:CLOUDFLARE_API_TOKEN = 'your-token-here'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "After authenticating, run this script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ Authenticated" -ForegroundColor Green
    if ($authCheck -match "email|account") {
        Write-Host "   $($authCheck.Trim())" -ForegroundColor DarkGray
    }
}

# Migrate schema
Write-Host "`n[1/1] Migrating schema..." -ForegroundColor Yellow
Write-Host "   Schema file: $schemaFile" -ForegroundColor Gray

# Use --remote flag to avoid local database crashes
# Auto-confirm the prompt by piping 'y' to the command
Write-Host "   Note: Database will be temporarily unavailable during migration" -ForegroundColor DarkGray
if ($useNpx) {
    Set-Location $workerDir
    Write-Host "   Running: npx wrangler d1 execute aurum-harmony-db --remote --file=schema.sql" -ForegroundColor Gray
    Write-Host "   (Using --remote to execute on Cloudflare database)" -ForegroundColor DarkGray
    "y" | npx wrangler d1 execute aurum-harmony-db --remote --file=schema.sql
} else {
    Write-Host "   Running: wrangler d1 execute aurum-harmony-db --remote --file=$schemaFile" -ForegroundColor Gray
    Write-Host "   (Using --remote to execute on Cloudflare database)" -ForegroundColor DarkGray
    "y" | wrangler d1 execute aurum-harmony-db --remote --file=$schemaFile
}

Set-Location $projectRoot

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Schema migrated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Deploy worker: .\start-all.ps1 → Option 4 → Deploy Worker" -ForegroundColor White
    Write-Host "  2. Test login: Worker should now work with D1 database!" -ForegroundColor White
} else {
    Write-Host "`n❌ Schema migration failed" -ForegroundColor Red
    Write-Host "   Check the output above for errors" -ForegroundColor Yellow
    exit 1
}

