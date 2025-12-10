# Restart Flutter with Clean Build
# This clears cache and rebuilds the app

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterAppPath = Join-Path $projectRoot 'aurum_harmony\frontend\flutter_app'

Write-Host 'Cleaning Flutter build cache...' -ForegroundColor Cyan
Set-Location $flutterAppPath
$cleanOutput = flutter clean 2>&1 | Out-String
# Filter out confusing "Removed X of Y files" messages (Flutter sometimes reports inconsistent counts)
$cleanOutput = $cleanOutput -replace 'Removed \d+ of \d+ files?', 'Cleaned build files'
$cleanOutput = $cleanOutput -replace 'Removed \d+ files?', 'Cleaned build files'
Write-Host '   ✅ Clean completed' -ForegroundColor Green

Write-Host 'Getting dependencies...' -ForegroundColor Cyan
flutter pub get

Write-Host 'Starting Flutter web server...' -ForegroundColor Green
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
Write-Host ''

flutter run -d web-server --web-port 8080

