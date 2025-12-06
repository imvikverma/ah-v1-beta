# Restart Flutter with Clean Build
# This clears cache and rebuilds the app

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterAppPath = Join-Path $projectRoot 'aurum_harmony\frontend\flutter_app'

Write-Host 'Cleaning Flutter build cache...' -ForegroundColor Cyan
Set-Location $flutterAppPath
flutter clean

Write-Host 'Getting dependencies...' -ForegroundColor Cyan
flutter pub get

Write-Host 'Starting Flutter web server...' -ForegroundColor Green
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
Write-Host ''

flutter run -d web-server --web-port 8080

