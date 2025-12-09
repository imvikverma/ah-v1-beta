# Complete D1 Database Setup for Cloudflare Worker
# Combines: database creation, schema migration, and optional data sync
# All operations use --remote flag to avoid local database crashes

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$workerDir = Join-Path $projectRoot "worker"
$wranglerToml = Join-Path $projectRoot "wrangler.toml"
$schemaFile = Join-Path $workerDir "schema.sql"
$sqliteDb = Join-Path $projectRoot "aurum_harmony.db"

Write-Host "=== Complete D1 Database Setup ===" -ForegroundColor Cyan
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

# Check authentication
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
    Write-Host "To authenticate, run:" -ForegroundColor Cyan
    Write-Host "  cd worker" -ForegroundColor White
    Write-Host "  npx wrangler login" -ForegroundColor White
    Write-Host "  cd .." -ForegroundColor White
    Write-Host "  .\scripts\setup_d1_complete.ps1" -ForegroundColor White
    exit 1
} else {
    Write-Host "✅ Authenticated" -ForegroundColor Green
}

# Step 1: Check if database exists
Write-Host "`n[1/4] Checking D1 Database..." -ForegroundColor Yellow
$tomlContent = Get-Content $wranglerToml -Raw
$databaseId = $null

if ($tomlContent -match 'database_id = "([^"]+)"') {
    $databaseId = $matches[1]
    if ($databaseId.Trim() -ne "") {
        Write-Host "✅ Database ID found: $databaseId" -ForegroundColor Green
        Write-Host "   Database name: aurum-harmony-db" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Database ID is empty in wrangler.toml" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Database ID not set in wrangler.toml" -ForegroundColor Yellow
}

# Step 2: Create database if needed
if (-not $databaseId -or $databaseId.Trim() -eq "") {
    Write-Host "`n[2/4] Creating D1 Database..." -ForegroundColor Yellow
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
            $databaseId = $potentialIds[-1].Groups[1].Value
        }
    }
    
    if ($databaseId) {
        Write-Host "✅ Database created!" -ForegroundColor Green
        Write-Host "   Database ID: $databaseId" -ForegroundColor Gray
        
        # Update wrangler.toml
        Write-Host "`nUpdating wrangler.toml..." -ForegroundColor Yellow
        $tomlContent = Get-Content $wranglerToml -Raw
        $tomlContent = $tomlContent -replace 'database_id = ""', "database_id = `"$databaseId`""
        $tomlContent = $tomlContent -replace 'database_id\s*=\s*"[^"]*"', "database_id = `"$databaseId`""
        Set-Content $wranglerToml -Value $tomlContent -NoNewline
        Write-Host "✅ wrangler.toml updated with database ID" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Could not automatically extract database ID from output" -ForegroundColor Yellow
        Write-Host "`nFull output:" -ForegroundColor Gray
        Write-Host $createOutput -ForegroundColor Gray
        Write-Host ""
        Write-Host "Please look for 'database_id' in the output above." -ForegroundColor Yellow
        Write-Host "It should look like: database_id = `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`"" -ForegroundColor Gray
        Write-Host ""
        $databaseId = Read-Host "Enter the database_id manually (or press Enter to skip)"
        if ($databaseId -and $databaseId.Trim() -ne "") {
            $tomlContent = Get-Content $wranglerToml -Raw
            $tomlContent = $tomlContent -replace 'database_id = ""', "database_id = `"$databaseId.Trim()`""
            $tomlContent = $tomlContent -replace 'database_id\s*=\s*"[^"]*"', "database_id = `"$databaseId.Trim()`""
            Set-Content $wranglerToml -Value $tomlContent -NoNewline
            Write-Host "✅ wrangler.toml updated" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Skipping database_id update. You can add it manually to wrangler.toml" -ForegroundColor Yellow
            Write-Host "   Look for the database_id in the output above and update wrangler.toml" -ForegroundColor Gray
            exit 1
        }
    }
} else {
    Write-Host "`n[2/4] Database already exists, skipping creation" -ForegroundColor Green
}

# Step 3: Migrate Schema
Write-Host "`n[3/4] Migrating database schema..." -ForegroundColor Yellow
if (-not (Test-Path $schemaFile)) {
    Write-Host "❌ Schema file not found: $schemaFile" -ForegroundColor Red
    exit 1
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
Write-Host "`n[4/4] Data Migration (Optional)..." -ForegroundColor Yellow
if (Test-Path $sqliteDb) {
    Write-Host "SQLite database found: $sqliteDb" -ForegroundColor Green
    $syncChoice = Read-Host "Would you like to sync data from SQLite to D1? (y/N)"
    
    if ($syncChoice -eq "y" -or $syncChoice -eq "Y") {
        Write-Host "`nSyncing data from SQLite to D1..." -ForegroundColor Yellow
        
        # Use the existing sync script
        $syncScript = Join-Path $projectRoot "scripts\sync_sqlite_to_d1.ps1"
        if (Test-Path $syncScript) {
            & $syncScript
        } else {
            Write-Host "⚠️  Sync script not found. Skipping data migration." -ForegroundColor Yellow
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
Write-Host "  1. Deploy worker: .\start-all.ps1 → Option 4 → Deploy Worker" -ForegroundColor White
Write-Host "  2. Test login: The worker should now work with D1 database!" -ForegroundColor White
Write-Host ""
Write-Host "💡 Note: Make sure JWT_SECRET is set in Cloudflare Dashboard:" -ForegroundColor Yellow
Write-Host "   wrangler secret put JWT_SECRET" -ForegroundColor Gray

