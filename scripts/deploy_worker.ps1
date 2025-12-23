# Deploy Cloudflare Worker
# Simple deployment script

$ErrorActionPreference = "Continue"
# Get project root (works from any location)
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) { break }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) { break }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) { break }
    $projectRoot = $parent
    $depth++
}
$workerDir = Join-Path $projectRoot "worker"

Write-Host "=== Deploying Cloudflare Worker ===" -ForegroundColor Cyan
Write-Host ""

# Check if worker directory exists
if (-not (Test-Path $workerDir)) {
    Write-Host "❌ Worker directory not found!" -ForegroundColor Red
    Write-Host "Run: .\scripts\fix_worker.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if wrangler is installed (globally or locally)
$wranglerCmd = "wrangler"

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
        $wranglerVersion = npx wrangler --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Wrangler found (local): $wranglerVersion" -ForegroundColor Green
        } else {
            Write-Host "❌ Wrangler not found. Installing locally..." -ForegroundColor Yellow
            npm install 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $wranglerCmd = "npx wrangler"
                Write-Host "✅ Wrangler installed" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
                exit 1
            }
        }
    } else {
        Write-Host "⚠️  Wrangler not found. Installing locally..." -ForegroundColor Yellow
        npm install 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $wranglerCmd = "npx wrangler"
            Write-Host "✅ Wrangler installed" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
            exit 1
        }
    }
}

# Navigate to worker directory
Set-Location $workerDir

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Test TypeScript compilation
Write-Host "`nChecking TypeScript..." -ForegroundColor Yellow
try {
    $tscOutput = npx tsc --noEmit 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ TypeScript compiles successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  TypeScript errors found:" -ForegroundColor Yellow
        Write-Host $tscOutput -ForegroundColor Red
        $continue = Read-Host "Continue with deployment anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "Deployment cancelled" -ForegroundColor Yellow
            exit 1
        }
    }
} catch {
    Write-Host "⚠️  Could not check TypeScript (continuing anyway)" -ForegroundColor Yellow
}

# Deploy
Write-Host "`nDeploying to Cloudflare..." -ForegroundColor Yellow
Write-Host "Worker: aurum-api" -ForegroundColor Gray
Write-Host "URL: https://api.ah.saffronbolt.in" -ForegroundColor Gray
Write-Host ""

Invoke-Expression "$wranglerCmd deploy"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Testing endpoint..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    try {
        Write-Host "Testing health endpoint..." -ForegroundColor Gray
        $healthResponse = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health" -TimeoutSec 10 -UseBasicParsing
        if ($healthResponse.StatusCode -eq 200) {
            Write-Host "✅ Health endpoint working!" -ForegroundColor Green
            $content = $healthResponse.Content | ConvertFrom-Json
            Write-Host "   Status: $($content.status)" -ForegroundColor Gray
            Write-Host "   Service: $($content.service)" -ForegroundColor Gray
            Write-Host "   Version: $($content.version)" -ForegroundColor Gray
        }
        
        Write-Host "`nTesting login endpoint (should return 501 for bcrypt)..." -ForegroundColor Gray
        try {
            $loginBody = @{email="test@test.com";password="test"} | ConvertTo-Json
            $loginResponse = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            Write-Host "   Status: $($loginResponse.StatusCode)" -ForegroundColor Gray
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 501) {
                Write-Host "   ✅ Login endpoint working (returns 501 for bcrypt - correct!)" -ForegroundColor Green
            } elseif ($statusCode -eq 401) {
                Write-Host "   ✅ Login endpoint working (returns 401 for invalid credentials - correct!)" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Login endpoint returned: $statusCode" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️  Worker not responding yet (may take a few seconds)" -ForegroundColor Yellow
    }
    
    Write-Host "`n💡 Worker deployed successfully!" -ForegroundColor Green
    Write-Host "   URL: https://api.ah.saffronbolt.in" -ForegroundColor Cyan
    Write-Host "   Login will automatically fallback to Flask backend (localhost:5000)" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Check the error messages above" -ForegroundColor Yellow
    exit 1
}

Set-Location $projectRoot
