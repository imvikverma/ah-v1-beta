# Fix and Verify System - Comprehensive Health Check
# Ensures everything is working smoothly before real testing

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
Write-Host "║     System Fix & Verification                        ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$fixes = @()

# Step 1: Check Virtual Environment
Write-Host "[1] Checking Virtual Environment..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Gray

$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    Write-Host "  ✅ Virtual environment found" -ForegroundColor Green
    & $venvPath
} else {
    Write-Host "  ❌ Virtual environment not found!" -ForegroundColor Red
    $issues += "Virtual environment missing"
}

# Step 2: Check Python Dependencies
Write-Host "`n[2] Checking Python Dependencies..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────" -ForegroundColor Gray

$dependencies = @("flask", "jwt", "bcrypt", "requests", "pandas", "numpy")
$missingDeps = @()

foreach ($dep in $dependencies) {
    try {
        $result = python -c "import $dep" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ $dep" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $dep (missing)" -ForegroundColor Red
            $missingDeps += $dep
        }
    } catch {
        Write-Host "  ❌ $dep (error checking)" -ForegroundColor Red
        $missingDeps += $dep
    }
}

if ($missingDeps.Count -gt 0) {
    $issues += "Missing dependencies: $($missingDeps -join ', ')"
    Write-Host "`n  💡 Installing missing dependencies..." -ForegroundColor Cyan
    pip install -q $missingDeps
    $fixes += "Installed missing dependencies"
}

# Step 3: Check Backend Entry Point
Write-Host "`n[3] Checking Backend Entry Point..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────" -ForegroundColor Gray

$backendPath = Join-Path $projectRoot "aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"
if (Test-Path $backendPath) {
    Write-Host "  ✅ Backend entry point found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Backend entry point not found!" -ForegroundColor Red
    $issues += "Backend entry point missing"
}

# Step 4: Check Flutter Frontend
Write-Host "`n[4] Checking Flutter Frontend..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────" -ForegroundColor Gray

$flutterPubspec = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\pubspec.yaml"
if (Test-Path $flutterPubspec) {
    Write-Host "  ✅ Flutter app found" -ForegroundColor Green
    
    # Check if pub get has been run
    $flutterLib = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib"
    if (Test-Path $flutterLib) {
        Write-Host "  ✅ Flutter lib directory exists" -ForegroundColor Green
    }
} else {
    Write-Host "  ❌ Flutter app not found!" -ForegroundColor Red
    $issues += "Flutter app missing"
}

# Step 5: Check Critical Files
Write-Host "`n[5] Checking Critical Files..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────" -ForegroundColor Gray

$criticalFiles = @(
    "requirements.txt",
    "wrangler.toml",
    ".gitignore",
    "README.md"
)

foreach ($file in $criticalFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file (not found)" -ForegroundColor Yellow
    }
}

# Step 6: Check Login Fix Files
Write-Host "`n[6] Checking Login Fix Files..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Gray

$loginFiles = @(
    "aurum_harmony\frontend\flutter_app\lib\services\auth_service.dart",
    "aurum_harmony\frontend\flutter_app\lib\services\db_admin_service.dart",
    "aurum_harmony\frontend\flutter_app\lib\screens\admin_screen.dart",
    "aurum_harmony\frontend\flutter_app\lib\screens\reports_screen.dart"
)

foreach ($file in $loginFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✅ $(Split-Path -Leaf $file)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $(Split-Path -Leaf $file) (missing)" -ForegroundColor Red
        $issues += "Login fix file missing: $file"
    }
}

# Step 7: Check Git Status
Write-Host "`n[7] Checking Git Status..." -ForegroundColor Yellow
Write-Host "─────────────────────────────" -ForegroundColor Gray

try {
    $gitStatus = git status --short 2>&1
    if ($LASTEXITCODE -eq 0) {
        $modifiedFiles = ($gitStatus | Measure-Object -Line).Lines
        if ($modifiedFiles -gt 0) {
            Write-Host "  ⚠️  $modifiedFiles uncommitted change(s)" -ForegroundColor Yellow
            Write-Host "  💡 Run: git status to see details" -ForegroundColor Cyan
        } else {
            Write-Host "  ✅ Working directory clean" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  ⚠️  Could not check git status" -ForegroundColor Yellow
}

# Step 8: Check Worker Configuration
Write-Host "`n[8] Checking Worker Configuration..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────" -ForegroundColor Gray

$wranglerPath = Join-Path $projectRoot "wrangler.toml"
if (Test-Path $wranglerPath) {
    $wranglerContent = Get-Content $wranglerPath -Raw
    if ($wranglerContent -match "aurum-api-v2") {
        Write-Host "  ✅ Worker configured for v2" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Worker may not be configured for v2" -ForegroundColor Yellow
        $issues += "Worker configuration may need update"
    }
} else {
    Write-Host "  ❌ wrangler.toml not found!" -ForegroundColor Red
    $issues += "Worker configuration missing"
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Summary                                             ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "✅ All checks passed! System is ready." -ForegroundColor Green
} else {
    Write-Host "⚠️  Found $($issues.Count) issue(s):" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  • $issue" -ForegroundColor Red
    }
}

if ($fixes.Count -gt 0) {
    Write-Host "`n✅ Fixes Applied:" -ForegroundColor Green
    foreach ($fix in $fixes) {
        Write-Host "  • $fix" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review any issues above" -ForegroundColor White
Write-Host "  2. Test backend: .\scripts\start_backend_silent.ps1" -ForegroundColor White
Write-Host "  3. Test frontend: flutter run -d chrome" -ForegroundColor White
Write-Host "  4. Commit changes: git add . && git commit -m 'Fix: System improvements'" -ForegroundColor White
Write-Host ""

