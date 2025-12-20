# Migration script for signup improvements
# Adds: username, profile_picture_url, email_verified, email_verification_token, terms_accepted, terms_accepted_at

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workerDir = Join-Path $projectRoot "worker"
$migrationFile = Join-Path $workerDir "schema_migration_signup_improvements.sql"

Write-Host "=== Signup Improvements Database Migration ===" -ForegroundColor Cyan
Write-Host ""

# Check if migration file exists
if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

# Check if wrangler is available
$useNpx = $true
$wranglerCheck = Get-Command npx -ErrorAction SilentlyContinue
if (-not $wranglerCheck) {
    $wranglerCheck = Get-Command wrangler -ErrorAction SilentlyContinue
    if ($wranglerCheck) {
        $useNpx = $false
    } else {
        Write-Host "❌ wrangler not found. Install with: npm install -g wrangler" -ForegroundColor Red
        exit 1
    }
}

# Check authentication
Write-Host "[1/2] Checking Cloudflare authentication..." -ForegroundColor Yellow
if ($useNpx) {
    Set-Location $workerDir
    $authCheck = npx wrangler whoami 2>&1 | Out-String
} else {
    $authCheck = wrangler whoami 2>&1 | Out-String
}
Set-Location $projectRoot

if ($authCheck -match "You are not authenticated" -or $authCheck -match "CLOUDFLARE_API_TOKEN" -or $LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not authenticated with Cloudflare" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To authenticate, run:" -ForegroundColor Cyan
    Write-Host "  cd worker" -ForegroundColor White
    Write-Host "  npx wrangler login" -ForegroundColor White
    Write-Host "  cd .." -ForegroundColor White
    Write-Host "  .\scripts\migrate_signup_improvements.ps1" -ForegroundColor White
    exit 1
} else {
    Write-Host "✅ Authenticated" -ForegroundColor Green
}

# Run migration
Write-Host ""
Write-Host "[2/2] Running D1 database migration..." -ForegroundColor Yellow
Write-Host "   File: schema_migration_signup_improvements.sql" -ForegroundColor Gray
Write-Host "   Note: Database will be temporarily unavailable during migration" -ForegroundColor DarkGray

if ($useNpx) {
    Set-Location $workerDir
    Write-Host "   Running: npx wrangler d1 execute aurum-harmony-db --remote --file=schema_migration_signup_improvements.sql" -ForegroundColor Gray
    "y" | npx wrangler d1 execute aurum-harmony-db --remote --file=schema_migration_signup_improvements.sql
} else {
    Set-Location $workerDir
    Write-Host "   Running: wrangler d1 execute aurum-harmony-db --remote --file=schema_migration_signup_improvements.sql" -ForegroundColor Gray
    "y" | wrangler d1 execute aurum-harmony-db --remote --file=schema_migration_signup_improvements.sql
}

Set-Location $projectRoot

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "New fields added to users table:" -ForegroundColor Cyan
    Write-Host "   • username (TEXT, indexed)" -ForegroundColor Gray
    Write-Host "   • profile_picture_url (TEXT)" -ForegroundColor Gray
    Write-Host "   • email_verified (INTEGER, default 0)" -ForegroundColor Gray
    Write-Host "   • email_verification_token (TEXT)" -ForegroundColor Gray
    Write-Host "   • terms_accepted (INTEGER, default 0)" -ForegroundColor Gray
    Write-Host "   • terms_accepted_at (TEXT)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Update Flask User model (if using SQLite)" -ForegroundColor White
    Write-Host "   2. Deploy worker: .\start-all.ps1 → Option 4 → Option 2" -ForegroundColor White
    Write-Host "   3. Test signup flow with new fields" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "⚠️  Migration may have failed. Check output above." -ForegroundColor Yellow
    Write-Host "   Note: If columns already exist, this is expected." -ForegroundColor Gray
}

