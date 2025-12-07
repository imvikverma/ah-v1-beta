# AurumHarmony System Verification Script
# Comprehensive check of all components

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AurumHarmony System Verification" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allChecks = @{
    "PowerShell Version" = $false
    "Virtual Environment" = $false
    "Python Packages" = $false
    "Database" = $false
    "Backend Scripts" = $false
    "Frontend Scripts" = $false
    "Backend Running" = $false
    "Frontend Running" = $false
    "Backend API" = $false
    "Deployment Scripts" = $false
    "Logs Directory" = $false
}

# 1. Check PowerShell Version
Write-Host "[1/11] Checking PowerShell Version..." -ForegroundColor Cyan
$psVersion = $PSVersionTable.PSVersion
$psEdition = $PSVersionTable.PSEdition
Write-Host "  PowerShell: $psVersion ($psEdition)" -ForegroundColor Gray
if ($psVersion.Major -ge 7) {
    $allChecks["PowerShell Version"] = $true
    Write-Host "  ✅ PowerShell 7+ (Recommended)" -ForegroundColor Green
} elseif ($psVersion.Major -ge 5) {
    $allChecks["PowerShell Version"] = $true
    Write-Host "  ✅ PowerShell 5.1+ (Compatible)" -ForegroundColor Green
    Write-Host "  💡 Consider upgrading to PowerShell 7+ for better performance" -ForegroundColor Yellow
} else {
    Write-Host "  ⚠️  PowerShell version may be too old (Recommended: 7+)" -ForegroundColor Yellow
}
Write-Host ""

# 2. Check Virtual Environment
Write-Host "[2/11] Checking Virtual Environment..." -ForegroundColor Cyan
$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    $allChecks["Virtual Environment"] = $true
    Write-Host "  ✅ Virtual environment found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Virtual environment not found" -ForegroundColor Red
    Write-Host "     Run: python -m venv .venv" -ForegroundColor Yellow
}
Write-Host ""

# 3. Check Python Packages
Write-Host "[3/11] Checking Python Packages..." -ForegroundColor Cyan
$pythonExe = Join-Path $projectRoot ".venv\Scripts\python.exe"
if (Test-Path $pythonExe) {
    try {
        $testResult = & $pythonExe -c "import flask, flask_sqlalchemy, jwt, bcrypt; print('OK')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $allChecks["Python Packages"] = $true
            Write-Host "  ✅ Required packages installed" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Missing packages: $testResult" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Error checking packages: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠️  Python executable not found" -ForegroundColor Yellow
}
Write-Host ""

# 4. Check Database
Write-Host "[4/11] Checking Database..." -ForegroundColor Cyan
$dbPath = Join-Path $projectRoot "aurum_harmony\database\aurum_harmony.db"
if (Test-Path $dbPath) {
    $dbSize = (Get-Item $dbPath).Length
    Write-Host "  ✅ Database exists ($([math]::Round($dbSize/1KB, 2)) KB)" -ForegroundColor Green
    $allChecks["Database"] = $true
} else {
    Write-Host "  ⚠️  Database not found (will be created on first run)" -ForegroundColor Yellow
    $allChecks["Database"] = $true  # Not critical, will be created
}
Write-Host ""

# 5. Check Backend Scripts
Write-Host "[5/11] Checking Backend Scripts..." -ForegroundColor Cyan
$backendScript = Join-Path $projectRoot "scripts\start_backend_silent.ps1"
$mainApp = Join-Path $projectRoot "aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"
if ((Test-Path $backendScript) -and (Test-Path $mainApp)) {
    $allChecks["Backend Scripts"] = $true
    Write-Host "  ✅ Backend scripts found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Backend scripts missing" -ForegroundColor Red
    if (-not (Test-Path $backendScript)) { Write-Host "     Missing: $backendScript" -ForegroundColor Yellow }
    if (-not (Test-Path $mainApp)) { Write-Host "     Missing: $mainApp" -ForegroundColor Yellow }
}
Write-Host ""

# 6. Check Frontend Scripts
Write-Host "[6/11] Checking Frontend Scripts..." -ForegroundColor Cyan
$flutterScript = Join-Path $projectRoot "scripts\start_flutter_silent.ps1"
$flutterApp = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\pubspec.yaml"
if ((Test-Path $flutterScript) -and (Test-Path $flutterApp)) {
    $allChecks["Frontend Scripts"] = $true
    Write-Host "  ✅ Frontend scripts found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Frontend scripts missing" -ForegroundColor Red
    if (-not (Test-Path $flutterScript)) { Write-Host "     Missing: $flutterScript" -ForegroundColor Yellow }
    if (-not (Test-Path $flutterApp)) { Write-Host "     Missing: $flutterApp" -ForegroundColor Yellow }
}
Write-Host ""

# 7. Check if Backend is Running
Write-Host "[7/11] Checking Backend Status..." -ForegroundColor Cyan
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect("localhost", 5000, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
    $backendPort = $false
    if ($wait) {
        $tcpClient.EndConnect($connect)
        $backendPort = $true
    }
    $tcpClient.Close()
    if ($backendPort) {
        $allChecks["Backend Running"] = $true
        Write-Host "  ✅ Backend is running on port 5000" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Backend is not running" -ForegroundColor Yellow
        Write-Host "     Start with: .\start-all.ps1 → Option 2" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  Could not check backend port" -ForegroundColor Yellow
}
Write-Host ""

# 8. Check if Frontend is Running
Write-Host "[8/11] Checking Frontend Status..." -ForegroundColor Cyan
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect("localhost", 58643, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
    $frontendPort = $false
    if ($wait) {
        $tcpClient.EndConnect($connect)
        $frontendPort = $true
    }
    $tcpClient.Close()
    if ($frontendPort) {
        $allChecks["Frontend Running"] = $true
        Write-Host "  ✅ Frontend is running on port 58643" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Frontend is not running" -ForegroundColor Yellow
        Write-Host "     Start with: .\start-all.ps1 → Option 3" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  Could not check frontend port" -ForegroundColor Yellow
}
Write-Host ""

# 9. Test Backend API
Write-Host "[9/11] Testing Backend API..." -ForegroundColor Cyan
if ($allChecks["Backend Running"]) {
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        if ($healthResponse.StatusCode -eq 200) {
            $allChecks["Backend API"] = $true
            Write-Host "  ✅ Backend API responding" -ForegroundColor Green
            $content = $healthResponse.Content | ConvertFrom-Json
            Write-Host "     Status: $($content.status)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ⚠️  Backend API not responding: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Skipping API test (backend not running)" -ForegroundColor Yellow
}
Write-Host ""

# 10. Check Deployment Scripts
Write-Host "[10/11] Checking Deployment Scripts..." -ForegroundColor Cyan
$deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
$autoDeployScript = Join-Path $projectRoot "scripts\auto_deploy.ps1"
if ((Test-Path $deployScript) -and (Test-Path $autoDeployScript)) {
    $allChecks["Deployment Scripts"] = $true
    Write-Host "  ✅ Deployment scripts found" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Some deployment scripts missing" -ForegroundColor Yellow
    if (-not (Test-Path $deployScript)) { Write-Host "     Missing: $deployScript" -ForegroundColor Yellow }
    if (-not (Test-Path $autoDeployScript)) { Write-Host "     Missing: $autoDeployScript" -ForegroundColor Yellow }
}
Write-Host ""

# 11. Check Logs Directory
Write-Host "[11/11] Checking Logs Directory..." -ForegroundColor Cyan
$logsDir = Join-Path $projectRoot "logs"
if (Test-Path $logsDir) {
    $allChecks["Logs Directory"] = $true
    Write-Host "  ✅ Logs directory exists" -ForegroundColor Green
    $logFiles = Get-ChildItem $logsDir -File | Select-Object -First 5
    if ($logFiles) {
        Write-Host "     Log files:" -ForegroundColor Gray
        foreach ($log in $logFiles) {
            $size = [math]::Round($log.Length/1KB, 2)
            Write-Host "       - $($log.Name) ($size KB)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ⚠️  Logs directory not found (will be created)" -ForegroundColor Yellow
    $allChecks["Logs Directory"] = $true  # Not critical
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($allChecks.Values | Where-Object { $_ -eq $true }).Count
$total = $allChecks.Count
$percentage = [math]::Round(($passed / $total) * 100, 1)

Write-Host "Checks Passed: $passed / $total ($percentage%)" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" })
Write-Host ""

foreach ($check in $allChecks.GetEnumerator() | Sort-Object Name) {
    $status = if ($check.Value) { "✅" } else { "❌" }
    $color = if ($check.Value) { "Green" } else { "Red" }
    Write-Host "  $status $($check.Key)" -ForegroundColor $color
}

Write-Host ""

# Recommendations
if (-not $allChecks["Backend Running"] -or -not $allChecks["Frontend Running"]) {
    Write-Host "Recommendations:" -ForegroundColor Yellow
    if (-not $allChecks["Backend Running"]) {
        Write-Host "  → Start backend: .\start-all.ps1 → Option 2" -ForegroundColor Cyan
    }
    if (-not $allChecks["Frontend Running"]) {
        Write-Host "  → Start frontend: .\start-all.ps1 → Option 3" -ForegroundColor Cyan
    }
    Write-Host "  → Or start both: .\start-all.ps1 → Option 1 (Auto-Start)" -ForegroundColor Cyan
    Write-Host ""
}

if ($percentage -ge 80) {
    Write-Host "✅ System is ready to use!" -ForegroundColor Green
} elseif ($percentage -ge 60) {
    Write-Host "⚠️  System is mostly ready, but some components need attention." -ForegroundColor Yellow
} else {
    Write-Host "❌ System needs setup. Please address the issues above." -ForegroundColor Red
}

Write-Host ""

