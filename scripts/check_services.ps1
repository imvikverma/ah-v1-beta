# Quick Service Status Check
# Shows which services are running and which PowerShell windows are open

Write-Host "=== AurumHarmony Service Status ===" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Backend Status:" -ForegroundColor Yellow
try {
    $backendPort = Test-NetConnection -ComputerName localhost -Port 5000 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    if ($backendPort) {
        Write-Host "  Backend is running on port 5000" -ForegroundColor Green
        try {
            $health = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            if ($health.StatusCode -eq 200) {
                $content = $health.Content | ConvertFrom-Json
                Write-Host "  Backend API is responding: $($content.status)" -ForegroundColor Green
            } else {
                Write-Host "  Backend API returned status: $($health.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Backend port is open but API check failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "     This might be a temporary issue - backend may still be starting up" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Backend is NOT running" -ForegroundColor Red
        Write-Host "     Start with: .\start-all.ps1 -> Option 2" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not check backend status" -ForegroundColor Red
}
Write-Host ""

# Check if frontend is running
Write-Host "Frontend Status:" -ForegroundColor Yellow
try {
    $frontendPort = Test-NetConnection -ComputerName localhost -Port 58643 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
    if ($frontendPort) {
        Write-Host "  Frontend is running on port 58643" -ForegroundColor Green
    } else {
        Write-Host "  Frontend is NOT running" -ForegroundColor Red
        Write-Host "     Start with: .\start-all.ps1 -> Option 3" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not check frontend status" -ForegroundColor Red
}
Write-Host ""

# Check PowerShell processes
Write-Host "PowerShell Processes:" -ForegroundColor Yellow
$allPowerShell = Get-Process powershell -ErrorAction SilentlyContinue
$backendCount = 0
$flutterCount = 0
$autoDeployCount = 0

foreach ($proc in $allPowerShell) {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
        if ($cmdLine -like "*start_backend_silent*") {
            $backendCount++
        }
        if ($cmdLine -like "*start_flutter_silent*") {
            $flutterCount++
        }
        if ($cmdLine -like "*auto_deploy*") {
            $autoDeployCount++
        }
    } catch {
        # Skip if we can't get command line
    }
}

if ($backendCount -gt 0) {
    Write-Host "  Backend PowerShell window(s) running: $backendCount" -ForegroundColor Green
    Write-Host "     These are minimized - safe to minimize/hide, but DO NOT close them!" -ForegroundColor Gray
    Write-Host "     Closing will stop the backend service." -ForegroundColor Gray
} else {
    Write-Host "  No backend PowerShell process found" -ForegroundColor Yellow
}

if ($flutterCount -gt 0) {
    Write-Host "  Flutter PowerShell window(s) running: $flutterCount" -ForegroundColor Green
    Write-Host "     These are minimized - safe to minimize/hide, but DO NOT close them!" -ForegroundColor Gray
    Write-Host "     Closing will stop the frontend service." -ForegroundColor Gray
} else {
    Write-Host "  No Flutter PowerShell process found" -ForegroundColor Yellow
}

if ($autoDeployCount -gt 0) {
    Write-Host "  Auto-deploy watcher running: $autoDeployCount" -ForegroundColor Green
    Write-Host "     This runs in hidden mode - you will not see it." -ForegroundColor Gray
} else {
    Write-Host "  Auto-deploy watcher not running" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "About PowerShell Windows:" -ForegroundColor Yellow
Write-Host "  - Backend/Flutter scripts run in MINIMIZED windows" -ForegroundColor White
Write-Host "  - You can minimize them further or hide them" -ForegroundColor White
Write-Host "  - DO NOT CLOSE them - closing stops the service!" -ForegroundColor Red
Write-Host "  - Safe to minimize/hide - services keep running" -ForegroundColor Green
Write-Host ""
Write-Host "To stop services properly:" -ForegroundColor Yellow
Write-Host "  - Close the PowerShell windows (this stops the service)" -ForegroundColor White
Write-Host "  - Or use Task Manager to end the PowerShell processes" -ForegroundColor White
Write-Host ""
