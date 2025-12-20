# Quick script to update database_id in wrangler.toml
# Usage: .\scripts\update_d1_database_id.ps1 "your-database-id-here"

param(
    [Parameter(Mandatory=$false)]
    [string]$DatabaseId = ""
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$wranglerToml = Join-Path $projectRoot "wrangler.toml"

Write-Host "=== Update D1 Database ID ===" -ForegroundColor Cyan
Write-Host ""

if (-not $DatabaseId -or $DatabaseId.Trim() -eq "") {
    Write-Host "Current wrangler.toml database_id:" -ForegroundColor Yellow
    $currentToml = Get-Content $wranglerToml -Raw
    if ($currentToml -match 'database_id = "([^"]*)"') {
        $currentId = $matches[1]
        if ($currentId -eq "") {
            Write-Host "  ❌ Not set (empty)" -ForegroundColor Red
        } else {
            Write-Host "  ✅ Current: $currentId" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "To get Database ID:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://dash.cloudflare.com/" -ForegroundColor Gray
    Write-Host "  2. Navigate: Workers & Pages → D1" -ForegroundColor Gray
    Write-Host "  3. Find: aurum-harmony-db" -ForegroundColor Gray
    Write-Host "  4. Copy the Database ID (UUID format)" -ForegroundColor Gray
    Write-Host ""
    $DatabaseId = Read-Host "Enter Database ID (or press Enter to cancel)"
    
    if (-not $DatabaseId -or $DatabaseId.Trim() -eq "") {
        Write-Host "❌ Cancelled" -ForegroundColor Yellow
        exit 0
    }
}

$DatabaseId = $DatabaseId.Trim()

# Validate UUID format
if ($DatabaseId -notmatch '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$') {
    Write-Host "⚠️  Warning: Database ID doesn't look like a valid UUID" -ForegroundColor Yellow
    Write-Host "   Format should be: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ForegroundColor Gray
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "❌ Cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Update wrangler.toml
Write-Host "`nUpdating wrangler.toml..." -ForegroundColor Yellow
$tomlContent = Get-Content $wranglerToml -Raw

# Replace any existing database_id (empty or set)
if ($tomlContent -match 'database_id\s*=\s*"[^"]*"') {
    $tomlContent = $tomlContent -replace 'database_id\s*=\s*"[^"]*"', "database_id = `"$DatabaseId`""
} else {
    # If pattern not found, try to add it after database_name
    $tomlContent = $tomlContent -replace '(database_name\s*=\s*"aurum-harmony-db")', "`$1`ndatabase_id = `"$DatabaseId`""
}

Set-Content $wranglerToml -Value $tomlContent -NoNewline

Write-Host "✅ Updated wrangler.toml!" -ForegroundColor Green
Write-Host "   Database ID: $DatabaseId" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Migrate schema: .\scripts\migrate_d1_schema.ps1" -ForegroundColor White
Write-Host "  2. Deploy worker: .\start-all.ps1 → Option 4" -ForegroundColor White

