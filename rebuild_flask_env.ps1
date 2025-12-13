# AurumHarmony Flask Environment Rebuild Script
# Rebuilds virtual environment with Python 3.11.9
# Date: 2025-12-12

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AurumHarmony Flask Environment Rebuild" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Check for Python 3.11
Write-Host "[1] Checking for Python 3.11..." -ForegroundColor Yellow
$python311Paths = @(
    "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
    "C:\Python311\python.exe",
    "C:\Program Files\Python311\python.exe"
)

$python311 = $null
foreach ($path in $python311Paths) {
    if (Test-Path $path) {
        $python311 = $path
        Write-Host "   [OK] Found Python 3.11 at: $path" -ForegroundColor Green
        $version = & $path --version
        Write-Host "   Version: $version" -ForegroundColor Gray
        break
    }
}

if (-not $python311) {
    Write-Host "   [ERROR] Python 3.11 not found!" -ForegroundColor Red
    Write-Host "`n   Please download and install Python 3.11.9 from:" -ForegroundColor Yellow
    Write-Host "   https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe`n" -ForegroundColor Cyan
    Write-Host "   See: _local\PYTHON_311_SETUP_GUIDE.md for instructions" -ForegroundColor Gray
    exit 1
}

# Step 2: Stop running processes
Write-Host "`n[2] Stopping running processes..." -ForegroundColor Yellow
Get-Process python*,dart*,flutter* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   [OK] Processes stopped" -ForegroundColor Green

# Step 3: Backup current .venv
Write-Host "`n[3] Backing up current virtual environment..." -ForegroundColor Yellow
if (Test-Path ".venv") {
    $backupName = ".venv-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Rename-Item .venv $backupName
    Write-Host "   [OK] Backed up to: $backupName" -ForegroundColor Green
} else {
    Write-Host "   [INFO] No existing .venv found (skipping backup)" -ForegroundColor Gray
}

# Step 4: Create new virtual environment
Write-Host "`n[4] Creating new virtual environment with Python 3.11..." -ForegroundColor Yellow
& $python311 -m venv .venv
if ($LASTEXITCODE -ne 0) {
    Write-Host "   [ERROR] Failed to create virtual environment" -ForegroundColor Red
    exit 1
}
Write-Host "   [OK] Virtual environment created" -ForegroundColor Green

# Step 5: Activate virtual environment
Write-Host "`n[5] Activating virtual environment..." -ForegroundColor Yellow
$activateScript = ".\.venv\Scripts\Activate.ps1"
if (-not (Test-Path $activateScript)) {
    Write-Host "   [ERROR] Activation script not found" -ForegroundColor Red
    exit 1
}
& $activateScript
Write-Host "   [OK] Virtual environment activated" -ForegroundColor Green

# Verify Python version in venv
$venvPython = python --version 2>&1
Write-Host "   Python in venv: $venvPython" -ForegroundColor Gray

# Step 6: Upgrade pip
Write-Host "`n[6] Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip setuptools wheel --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] pip upgraded" -ForegroundColor Green
} else {
    Write-Host "   [WARN] pip upgrade had issues (continuing...)" -ForegroundColor Yellow
}

# Step 7: Install requirements
Write-Host "`n[7] Installing packages from requirements.txt..." -ForegroundColor Yellow
Write-Host "   This may take 5-10 minutes..." -ForegroundColor Gray
pip install -r requirements.txt
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] All packages installed" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Package installation failed" -ForegroundColor Red
    Write-Host "   Check error messages above" -ForegroundColor Yellow
    exit 1
}

# Step 8: Verify key packages
Write-Host "`n[8] Verifying installations..." -ForegroundColor Yellow
$packagesToCheck = @("Flask", "tensorflow", "SQLAlchemy", "flask-cors")
$allGood = $true
foreach ($pkg in $packagesToCheck) {
    $version = pip show $pkg 2>&1 | Select-String "Version:"
    if ($version) {
        Write-Host "   [OK] $pkg : $version" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] $pkg not installed!" -ForegroundColor Red
        $allGood = $false
    }
}

# Step 9: Test Flask import
Write-Host "`n[9] Testing Flask import..." -ForegroundColor Yellow
$testResult = python -c "import flask; print(f'Flask {flask.__version__} OK')" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] $testResult" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Flask import failed: $testResult" -ForegroundColor Red
    $allGood = $false
}

# Step 10: Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "  ✅ REBUILD COMPLETE!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Test backend: python -m aurum_harmony.master_codebase.Master_AurumHarmony_261125" -ForegroundColor White
    Write-Host "  2. Or use:       .\start-all.ps1 (Option 4)" -ForegroundColor White
    Write-Host "`nExpected improvements:" -ForegroundColor Cyan
    Write-Host "  - Faster startup (5-8s)" -ForegroundColor Gray
    Write-Host "  - No encoding errors" -ForegroundColor Gray
    Write-Host "  - No dotenv warnings" -ForegroundColor Gray
    Write-Host "  - Production-ready stability" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️  REBUILD COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "Some packages may need manual attention." -ForegroundColor Yellow
    Write-Host "Check error messages above." -ForegroundColor Gray
}

Write-Host "`n"

