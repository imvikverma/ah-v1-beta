# Clean rebuild of Flutter app to clear any cached content

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Clean Flutter Rebuild               " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "$PSScriptRoot\..\aurum_harmony\frontend\flutter_app"

Write-Host "Step 1: Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean

Write-Host "`nStep 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nStep 3: Building web app..." -ForegroundColor Yellow
flutter build web --release

Write-Host "`n✅ Clean rebuild complete!" -ForegroundColor Green
Write-Host ""
Write-Host "To run the app:" -ForegroundColor Cyan
Write-Host "  flutter run -d web-server" -ForegroundColor White
Write-Host ""
Write-Host "Or use the launcher:" -ForegroundColor Cyan
Write-Host "  .\zzz-quick-access\start-all.ps1 (option 4)" -ForegroundColor White
Write-Host ""

Set-Location "$PSScriptRoot\.."
Read-Host "Press Enter to exit"
