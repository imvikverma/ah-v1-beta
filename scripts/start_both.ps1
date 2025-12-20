# Start Backend and Frontend with Health Check
# This script ensures proper startup sequencing

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   AurumHarmony Sequential Startup" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Start Backend
Write-Host "[1/3] Starting Flask Backend..." -ForegroundColor Green
Write-Host "      Port: 5000" -ForegroundColor Gray

$backendScript = Join-Path $projectRoot "scripts\start_backend_silent.ps1"
$backendProcess = Start-Process -FilePath "pwsh.exe" `
    -ArgumentList "-NoExit", "-WindowStyle", "Minimized", "-File", "`"$backendScript`"" `
    -WindowStyle Minimized `
    -PassThru

if ($backendProcess) {
    Write-Host "      ✅ Backend process started (PID: $($backendProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "      ❌ Failed to start backend" -ForegroundColor Red
    exit 1
}

# Step 2: Wait for Backend Health Check
Write-Host "`n[2/3] Waiting for backend to be ready..." -ForegroundColor Yellow
Write-Host "      Testing: http://localhost:5000/api/health" -ForegroundColor Gray
Write-Host "      " -NoNewline

$maxAttempts = 30
$attempt = 0
$backendReady = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    Start-Sleep -Seconds 1
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" `
            -TimeoutSec 2 `
            -UseBasicParsing `
            -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            $backendReady = $true
            Write-Host "`n      ✅ Backend ready after $attempt seconds!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}

if (-not $backendReady) {
    Write-Host "`n      ⚠️  Backend health check timed out" -ForegroundColor Yellow
    Write-Host "      Starting frontend anyway..." -ForegroundColor Gray
}

# Step 3: Start Frontend
Write-Host "`n[3/3] Starting Flutter Web App..." -ForegroundColor Green
Write-Host "      Port: 58643" -ForegroundColor Gray

$flutterScript = Join-Path $projectRoot "scripts\start_flutter_silent.ps1"
$flutterProcess = Start-Process -FilePath "pwsh.exe" `
    -ArgumentList "-NoExit", "-WindowStyle", "Minimized", "-File", "`"$flutterScript`"" `
    -WindowStyle Minimized `
    -PassThru

if ($flutterProcess) {
    Write-Host "      ✅ Flutter process started (PID: $($flutterProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "      ❌ Failed to start flutter" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   ✅ Startup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "URLs:" -ForegroundColor Yellow
Write-Host "  • Backend:  http://localhost:5000" -ForegroundColor White
Write-Host "  • Frontend: http://localhost:58643" -ForegroundColor White
Write-Host "  • Admin:    http://localhost:58643/#/admin" -ForegroundColor White

Write-Host "`nLogs:" -ForegroundColor Yellow
Write-Host "  • Backend:  _local\logs\backend.log" -ForegroundColor Gray
Write-Host "  • Flutter:  _local\logs\flutter.log" -ForegroundColor Gray

Write-Host "`nWindows minimized - check taskbar to restore" -ForegroundColor Gray
Write-Host "Press any key to exit this window..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

