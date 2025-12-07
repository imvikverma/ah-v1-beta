# Setup Cloudflare D1 Database for Worker
# This script creates the D1 database and sets up the schema

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$workerDir = Join-Path $projectRoot "worker"

Write-Host "=== Setting up Cloudflare D1 Database ===" -ForegroundColor Cyan
Write-Host ""

# Check if wrangler is installed (globally or locally)
$wranglerCmd = "wrangler"
$useNpx = $false

try {
    $wranglerVersion = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Wrangler found (global): $wranglerVersion" -ForegroundColor Green
    } else {
        throw "Wrangler not found globally"
    }
} catch {
    # Try local installation
    Set-Location $workerDir
    
    # Check if node_modules exists and has wrangler
    $wranglerLocal = (Test-Path "node_modules\.bin\wrangler.cmd") -or (Test-Path "node_modules\.bin\wrangler")
    
    if ($wranglerLocal) {
        $wranglerCmd = "npx wrangler"
        $useNpx = $true
        $wranglerVersion = npx wrangler --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Wrangler found (local): $wranglerVersion" -ForegroundColor Green
        } else {
            throw "Wrangler not found locally"
        }
    } else {
        Write-Host "⚠️  Wrangler not found, installing locally..." -ForegroundColor Yellow
        npm install 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $wranglerCmd = "npx wrangler"
            $useNpx = $true
            Write-Host "✅ Wrangler installed locally" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please install manually:" -ForegroundColor Yellow
            Write-Host "  cd worker" -ForegroundColor Cyan
            Write-Host "  npm install" -ForegroundColor Cyan
            exit 1
        }
    }
}

Set-Location $workerDir

# Step 1: Create D1 database
Write-Host "[1/4] Creating D1 database..." -ForegroundColor Yellow
if ($useNpx) {
    Set-Location $workerDir
    $dbOutput = npx wrangler d1 create aurum-harmony-db 2>&1
} else {
    $dbOutput = wrangler d1 create aurum-harmony-db 2>&1
}
$dbOutputString = $dbOutput | Out-String

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database created successfully" -ForegroundColor Green
    
    # Extract database ID from output
    if ($dbOutputString -match 'database_id.*=.*"([^"]+)"') {
        $databaseId = $matches[1]
        Write-Host "   Database ID: $databaseId" -ForegroundColor Gray
        
        # Update wrangler.toml
        Write-Host "`n[2/4] Updating wrangler.toml..." -ForegroundColor Yellow
        $wranglerToml = Join-Path $projectRoot "wrangler.toml"
        $wranglerContent = Get-Content $wranglerToml -Raw
        
        if ($wranglerContent -match 'database_id\s*=\s*""') {
            $wranglerContent = $wranglerContent -replace 'database_id\s*=\s*""', "database_id = `"$databaseId`""
            Set-Content -Path $wranglerToml -Value $wranglerContent -NoNewline
            Write-Host "✅ Updated wrangler.toml with database ID" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Could not auto-update wrangler.toml" -ForegroundColor Yellow
            Write-Host "   Please manually update database_id in wrangler.toml to: $databaseId" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Could not extract database ID from output" -ForegroundColor Yellow
        Write-Host "   Please check the output above and manually update wrangler.toml" -ForegroundColor Gray
    }
} else {
    if ($dbOutputString -match 'already exists') {
        Write-Host "⚠️  Database already exists" -ForegroundColor Yellow
        Write-Host "   Using existing database..." -ForegroundColor Gray
    } else {
        Write-Host "❌ Failed to create database" -ForegroundColor Red
        Write-Host $dbOutputString -ForegroundColor Red
        exit 1
    }
}

# Step 3: Create schema
Write-Host "`n[3/4] Creating database schema..." -ForegroundColor Yellow
$schemaFile = Join-Path $workerDir "schema.sql"
if (Test-Path $schemaFile) {
    if ($useNpx) {
        Set-Location $workerDir
        $schemaResult = npx wrangler d1 execute aurum-harmony-db --file=$schemaFile 2>&1
    } else {
        $schemaResult = wrangler d1 execute aurum-harmony-db --file=$schemaFile 2>&1
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Schema created successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Schema creation had issues:" -ForegroundColor Yellow
        Write-Host $schemaResult -ForegroundColor Red
        Write-Host "   (Some errors may be expected if tables already exist)" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Schema file not found: $schemaFile" -ForegroundColor Red
    exit 1
}

# Step 4: Set JWT secret
Write-Host "`n[4/4] Setting up JWT secret..." -ForegroundColor Yellow
Write-Host "   Generating JWT secret..." -ForegroundColor Gray

# Generate a random secret (simplified - in production use openssl)
$jwtSecret = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

Write-Host "   Secret generated (save this securely!)" -ForegroundColor Gray
Write-Host ""
Write-Host "Set JWT secret with:" -ForegroundColor Yellow
if ($useNpx) {
    Write-Host "  cd worker" -ForegroundColor Cyan
    Write-Host "  npx wrangler secret put JWT_SECRET" -ForegroundColor Cyan
} else {
    Write-Host "  wrangler secret put JWT_SECRET" -ForegroundColor Cyan
}
Write-Host "  (When prompted, paste: $jwtSecret)" -ForegroundColor Gray
Write-Host ""
Write-Host "Or set it in Cloudflare Dashboard:" -ForegroundColor Yellow
Write-Host "  Workers & Pages → aurum-api → Settings → Variables and Secrets" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Set JWT_SECRET (see above)" -ForegroundColor White
Write-Host "  2. Migrate data from SQLite (optional):" -ForegroundColor White
Write-Host "     .\scripts\migrate_to_d1.ps1" -ForegroundColor Gray
Write-Host "  3. Deploy worker:" -ForegroundColor White
Write-Host "     .\scripts\deploy_worker.ps1" -ForegroundColor Gray
Write-Host ""

Set-Location $projectRoot
