# Quick check if Flutter frontend is running

$ErrorActionPreference = "Continue"

Write-Host "`n🔍 Checking Flutter Frontend Status..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "http://localhost:58643" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "`n✅ Flutter app is running!" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Cyan
    Write-Host "   URL: http://localhost:58643" -ForegroundColor Cyan
    Write-Host "`n✅ Ready to use!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "`n⚠️  Server responding but route not found" -ForegroundColor Yellow
        Write-Host "   (Flutter might still be compiling)" -ForegroundColor Gray
    } elseif ($_.Exception.Message -match "connection") {
        Write-Host "`n❌ Flutter app is not running" -ForegroundColor Red
        Write-Host "`n🔧 To start it:" -ForegroundColor Yellow
        Write-Host "   .\scripts\start_flutter_silent.ps1" -ForegroundColor Cyan
        Write-Host "   OR" -ForegroundColor Gray
        Write-Host "   cd aurum_harmony\frontend\flutter_app" -ForegroundColor Cyan
        Write-Host "   flutter run -d chrome --web-port=58643" -ForegroundColor Cyan
    } else {
        Write-Host "`n⚠️  Error checking status: $_" -ForegroundColor Cyan
    }
}

