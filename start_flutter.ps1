# AurumHarmony Flutter Frontend Startup Script
# Double-click this file or run: .\start_flutter.ps1

cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"

Write-Host "Installing/updating Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "Starting Flutter web app..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Use web-server to avoid "Launching lib \chrome" message
flutter run -d web-server --web-port=58643

