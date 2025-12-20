# Diagnose Cloudflare Worker Issues
# Helps identify what's wrong with the API worker

Write-Host "=== Cloudflare Worker Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# 1. Check if worker directory exists
Write-Host "[1/6] Checking Worker Structure..." -ForegroundColor Yellow
$workerDir = Join-Path $projectRoot "worker"
$workerSrc = Join-Path $workerDir "src\index.ts"
$wranglerToml = Join-Path $projectRoot "wrangler.toml"

if (-not (Test-Path $workerDir)) {
    Write-Host "  ❌ Worker directory not found!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✅ Worker directory exists" -ForegroundColor Green
}

if (-not (Test-Path $workerSrc)) {
    Write-Host "  ❌ worker/src/index.ts not found!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✅ Worker source file exists" -ForegroundColor Green
}

if (-not (Test-Path $wranglerToml)) {
    Write-Host "  ❌ wrangler.toml not found!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✅ wrangler.toml exists" -ForegroundColor Green
}

# 2. Check wrangler.toml configuration
Write-Host "`n[2/6] Checking wrangler.toml..." -ForegroundColor Yellow
$wranglerContent = Get-Content $wranglerToml -Raw
if ($wranglerContent -match 'main\s*=\s*"worker/src/index.ts"') {
    Write-Host "  ✅ Main entry point configured correctly" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Main entry point might be incorrect" -ForegroundColor Yellow
    Write-Host "     Expected: main = `"worker/src/index.ts`"" -ForegroundColor Gray
}

# 3. Check if wrangler is installed
Write-Host "`n[3/6] Checking Wrangler CLI..." -ForegroundColor Yellow
try {
    $wranglerVersion = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Wrangler installed: $wranglerVersion" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Wrangler not found or not working" -ForegroundColor Red
        Write-Host "     Install with: npm install -g wrangler" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ Wrangler not found" -ForegroundColor Red
    Write-Host "     Install with: npm install -g wrangler" -ForegroundColor Gray
}

# 4. Check TypeScript compilation
Write-Host "`n[4/6] Checking TypeScript compilation..." -ForegroundColor Yellow
Set-Location $workerDir
if (Test-Path "node_modules") {
    Write-Host "  ✅ node_modules exists" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  node_modules not found - run: npm install" -ForegroundColor Yellow
}

try {
    $tscCheck = npx tsc --noEmit 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ TypeScript compiles without errors" -ForegroundColor Green
    } else {
        Write-Host "  ❌ TypeScript compilation errors:" -ForegroundColor Red
        Write-Host $tscCheck -ForegroundColor Red
    }
} catch {
    Write-Host "  ⚠️  Could not check TypeScript (tsc not found)" -ForegroundColor Yellow
}

Set-Location $projectRoot

# 5. Test Worker endpoint
Write-Host "`n[5/6] Testing Worker Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Worker is responding!" -ForegroundColor Green
        $content = $response.Content | ConvertFrom-Json
        Write-Host "     Status: $($content.status)" -ForegroundColor Gray
        Write-Host "     Service: $($content.service)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Worker returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Worker is NOT responding" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Possible causes:" -ForegroundColor Yellow
    Write-Host "     • Worker not deployed" -ForegroundColor White
    Write-Host "     • Build failed" -ForegroundColor White
    Write-Host "     • DNS not configured" -ForegroundColor White
    Write-Host "     • Worker code has errors" -ForegroundColor White
}

# 6. Check local backend as alternative
Write-Host "`n[6/6] Checking Local Backend (Alternative)..." -ForegroundColor Yellow
try {
    $localResponse = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($localResponse.StatusCode -eq 200) {
        Write-Host "  ✅ Local backend is working!" -ForegroundColor Green
        Write-Host "     Use this for development: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "     Frontend: http://localhost:58643" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ⚠️  Local backend not running" -ForegroundColor Yellow
    Write-Host "     Start with: .\start-all.ps1 -> Option 1" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. If Worker not responding, check Cloudflare Dashboard:" -ForegroundColor White
Write-Host "     https://dash.cloudflare.com -> Workers & Pages -> aurum-api" -ForegroundColor Gray
Write-Host "  2. Check 'Deployments' tab for build errors" -ForegroundColor White
Write-Host "  3. For development, use localhost backend instead:" -ForegroundColor White
Write-Host "     Frontend: http://localhost:58643" -ForegroundColor Cyan
Write-Host "     Backend: http://localhost:5000" -ForegroundColor Cyan
Write-Host ""
