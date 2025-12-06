# AurumHarmony Ngrok Startup Script
# Double-click this file or run: .\start_ngrok.ps1

cd 'D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest'

Write-Host 'Checking if backend is running on port 5000...' -ForegroundColor Cyan
$backendCheck = Test-NetConnection -ComputerName localhost -Port 5000 -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $backendCheck) {
    Write-Host 'WARNING: Backend does not appear to be running on port 5000' -ForegroundColor Yellow
    Write-Host '   Starting ngrok anyway - make sure backend is running!' -ForegroundColor Yellow
    Write-Host ''
}

Write-Host 'Starting ngrok tunnel to backend (port 5000)...' -ForegroundColor Green
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
Write-Host ''

# Check if ngrok is installed
$ngrokPath = Get-Command ngrok -ErrorAction SilentlyContinue
if (-not $ngrokPath) {
    Write-Host 'ERROR: ngrok is not installed or not in PATH' -ForegroundColor Red
    Write-Host ''
    Write-Host 'To install ngrok:' -ForegroundColor Yellow
    Write-Host '  1. Download from https://ngrok.com/download' -ForegroundColor White
    Write-Host '  2. Extract and add to PATH, or' -ForegroundColor White
    Write-Host '  3. Run: .\scripts\setup\setup_ngrok_authtoken.ps1' -ForegroundColor White
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}

# Check for existing ngrok processes
Write-Host 'Checking for existing ngrok processes...' -ForegroundColor Cyan
$ngrokProcesses = Get-Process -Name ngrok -ErrorAction SilentlyContinue
if ($ngrokProcesses) {
    Write-Host 'Found existing ngrok process(es). Free tier allows only 1 session.' -ForegroundColor Yellow
    Write-Host '   Stopping existing ngrok processes...' -ForegroundColor Yellow
    $ngrokProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host 'Existing processes stopped' -ForegroundColor Green
    Write-Host ''
}

# Start ngrok agent endpoint connected to Cloud Endpoint
# The --url flag connects this agent to your Cloud Endpoint
# This makes the endpoint persistent (works even if agent restarts)
# Default internal URL is https://default.internal (check your Cloud Endpoint traffic policy)
try {
    Write-Host 'Connecting agent endpoint to Cloud Endpoint...' -ForegroundColor Cyan
    Write-Host 'Cloud Endpoint URL: https://top-manatee-busy.ngrok-free.app' -ForegroundColor Gray
    Write-Host 'Internal URL: https://default.internal' -ForegroundColor Gray
    Write-Host ''
    ngrok http 5000 --url https://default.internal
} catch {
    Write-Host ''
    Write-Host 'ERROR starting ngrok:' $_ -ForegroundColor Red
    Write-Host ''
    Write-Host 'Troubleshooting:' -ForegroundColor Yellow
    Write-Host '  1. Make sure no other ngrok sessions are running' -ForegroundColor White
    Write-Host '  2. Check your ngrok authtoken is set: ngrok config check' -ForegroundColor White
    Write-Host '  3. Verify Cloud Endpoint is active in ngrok dashboard' -ForegroundColor White
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}
