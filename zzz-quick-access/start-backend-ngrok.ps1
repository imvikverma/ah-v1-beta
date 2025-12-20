# Quick launcher for Flask Backend + Ngrok (both services)
# Starts backend in separate window, then ngrok

Set-Location $PSScriptRoot\..

Write-Host "Starting Flask Backend in new window..." -ForegroundColor Green
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PWD'; .\scripts\start_backend.ps1"
)

Write-Host "Waiting 3 seconds for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Starting Ngrok tunnel..." -ForegroundColor Green
& ".\scripts\start_ngrok.ps1"
