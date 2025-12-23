# Fix Login Dependencies
# Installs missing dependencies causing auth blueprint to fail

$ErrorActionPreference = "Continue"

# Get project root
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
Set-Location $projectRoot

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Fixing Login Dependencies                          ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Activate venv
if (Test-Path ".venv\Scripts\Activate.ps1") {
    & ".venv\Scripts\Activate.ps1"
    Write-Host "[OK] Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Virtual environment not found!" -ForegroundColor Red
    Write-Host "Run rebuild_flask_env.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[1] Installing Missing Dependencies..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────" -ForegroundColor Gray

# Missing modules from logs: jwt, dotenv
$missingModules = @("PyJWT", "python-dotenv")

foreach ($module in $missingModules) {
    Write-Host "  Installing $module..." -ForegroundColor Gray
    pip install $module --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $module installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to install $module" -ForegroundColor Red
    }
}

Write-Host "`n[2] Verifying Installation..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray

$verifyScript = @"
import sys
modules = ['jwt', 'dotenv']
missing = []
for mod in modules:
    try:
        __import__(mod)
        print(f'✅ {mod}')
    except ImportError:
        missing.append(mod)
        print(f'❌ {mod}')

if missing:
    sys.exit(1)
"@

$verifyScript | python
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ All dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Some dependencies still missing" -ForegroundColor Yellow
}

Write-Host "`n[3] Checking requirements.txt..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Gray

$requirementsPath = Join-Path $projectRoot "requirements.txt"
if (Test-Path $requirementsPath) {
    $requirements = Get-Content $requirementsPath -Raw
    $needsUpdate = $false
    
    if ($requirements -notmatch "PyJWT|pyjwt") {
        Write-Host "  ⚠️  PyJWT not in requirements.txt" -ForegroundColor Yellow
        Add-Content $requirementsPath "`nPyJWT>=2.8.0"
        $needsUpdate = $true
    }
    
    if ($requirements -notmatch "python-dotenv") {
        Write-Host "  ⚠️  python-dotenv not in requirements.txt" -ForegroundColor Yellow
        Add-Content $requirementsPath "`npython-dotenv>=1.0.0"
        $needsUpdate = $true
    }
    
    if ($needsUpdate) {
        Write-Host "  ✅ requirements.txt updated" -ForegroundColor Green
    } else {
        Write-Host "  ✅ requirements.txt already includes dependencies" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️  requirements.txt not found" -ForegroundColor Yellow
}

Write-Host "`n✅ Dependencies Fixed!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Restart Flask backend: .\start-all.ps1 (Option 5, then Option 1)" -ForegroundColor White
Write-Host "  2. Test login endpoint: curl -X POST http://localhost:5000/api/auth/login" -ForegroundColor White
Write-Host "  3. Verify auth blueprint is registered (check startup logs)" -ForegroundColor White
Write-Host ""

