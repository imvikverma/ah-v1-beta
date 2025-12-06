# AurumHarmony Master Launcher with Error Logging
# This version logs errors to files for troubleshooting

$logDir = "$PSScriptRoot\..\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ngrokLog = "$logDir\ngrok_$timestamp.log"
$flutterLog = "$logDir\flutter_$timestamp.log"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   AurumHarmony Service Launcher       " -ForegroundColor Cyan
Write-Host "   (with error logging)                " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select a service to start:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Flask Backend (port 5000)" -ForegroundColor White
Write-Host "  2. Ngrok Tunnel" -ForegroundColor White
Write-Host "  3. Flask Backend + Ngrok (both)" -ForegroundColor White
Write-Host "  4. Flutter Dev Server" -ForegroundColor White
Write-Host "  5. Flask Backend + Ngrok + Flutter (all three)" -ForegroundColor Cyan
Write-Host "  6. Test HDFC Sky Credentials" -ForegroundColor White
Write-Host "  7. Test Kotak Neo Credentials" -ForegroundColor White
Write-Host "  8. Exit" -ForegroundColor White
Write-Host ""
Write-Host "Note: Errors will be logged to logs/ directory" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Enter your choice (1-8)"

switch ($choice) {
    "1" {
        Write-Host "`nStarting Flask Backend..." -ForegroundColor Green
        & "..\scripts\start_backend.ps1"
    }
    "2" {
        Write-Host "`nStarting Ngrok Tunnel..." -ForegroundColor Green
        Write-Host "Logging to: $ngrokLog" -ForegroundColor Gray
        & "..\scripts\start_ngrok.ps1" *> $ngrokLog
    }
    "3" {
        Write-Host "`nStarting Flask Backend + Ngrok..." -ForegroundColor Green
        Start-Process powershell -ArgumentList @(
            "-NoExit",
            "-Command",
            "cd '$PSScriptRoot\..'; .\scripts\start_backend.ps1"
        )
        Start-Sleep -Seconds 3
        Write-Host "Logging ngrok to: $ngrokLog" -ForegroundColor Gray
        & "..\scripts\start_ngrok.ps1" *> $ngrokLog
    }
    "4" {
        Write-Host "`nStarting Flutter Dev Server..." -ForegroundColor Green
        Write-Host "Logging to: $flutterLog" -ForegroundColor Gray
        & "..\scripts\start_flutter.ps1" *> $flutterLog
    }
    "5" {
        Write-Host "`nStarting ALL services (Backend + Ngrok + Flutter)..." -ForegroundColor Cyan
        Write-Host "This will open 3 separate windows." -ForegroundColor Yellow
        Write-Host ""
        
        # Start Flask Backend in new window
        Write-Host "Starting Flask Backend..." -ForegroundColor Green
        Start-Process powershell -ArgumentList @(
            "-NoExit",
            "-Command",
            "cd '$PSScriptRoot\..'; .\scripts\start_backend.ps1"
        )
        
        # Wait for backend to start
        Start-Sleep -Seconds 3
        
        # Start Ngrok in new window with logging
        Write-Host "Starting Ngrok Tunnel (logging to: $ngrokLog)..." -ForegroundColor Green
        Start-Process powershell -ArgumentList @(
            "-NoExit",
            "-Command",
            "cd '$PSScriptRoot\..'; .\scripts\start_ngrok.ps1 *> '$ngrokLog'"
        )
        
        # Wait a moment
        Start-Sleep -Seconds 2
        
        # Start Flutter in new window with logging
        Write-Host "Starting Flutter Dev Server (logging to: $flutterLog)..." -ForegroundColor Green
        Start-Process powershell -ArgumentList @(
            "-NoExit",
            "-Command",
            "cd '$PSScriptRoot\..'; .\scripts\start_flutter.ps1 *> '$flutterLog'"
        )
        
        Write-Host "`n✅ All services started!" -ForegroundColor Green
        Write-Host "   - Flask Backend: http://localhost:5000" -ForegroundColor Yellow
        Write-Host "   - Admin Panel: http://localhost:5001" -ForegroundColor Yellow
        Write-Host "   - Ngrok: Check the ngrok window for URL" -ForegroundColor Yellow
        Write-Host "   - Flutter: Check the Flutter window for URL" -ForegroundColor Yellow
        Write-Host "`nLog files:" -ForegroundColor Cyan
        Write-Host "   - Ngrok: $ngrokLog" -ForegroundColor White
        Write-Host "   - Flutter: $flutterLog" -ForegroundColor White
        Write-Host "`nPress any key to exit this launcher..."
        Read-Host
    }
    "6" {
        Write-Host "`nTesting HDFC Sky Credentials..." -ForegroundColor Green
        python "..\scripts\tests\test_hdfc_credentials.py"
        Write-Host "`nPress any key to continue..."
        Read-Host
    }
    "7" {
        Write-Host "`nTesting Kotak Neo Credentials..." -ForegroundColor Green
        python "..\config\get_kotak_token.py"
        Write-Host "`nPress any key to continue..."
        Read-Host
    }
    "8" {
        Write-Host "`nExiting..." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "`nInvalid choice. Please select 1-8." -ForegroundColor Red
        Write-Host "Press any key to continue..."
        Read-Host
        & $PSCommandPath
    }
}
