# AurumHarmony Flutter Frontend Startup Script
# Double-click this file or run: .\start_flutter.ps1

cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"

# Check if Flutter is installed
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "❌ ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "To install Flutter:" -ForegroundColor Yellow
    Write-Host "  1. Download from https://flutter.dev/docs/get-started/install/windows" -ForegroundColor White
    Write-Host "  2. Extract and add to PATH" -ForegroundColor White
    Write-Host "  3. Run: flutter doctor" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ ERROR: pubspec.yaml not found. Are you in the Flutter app directory?" -ForegroundColor Red
    Write-Host "   Current directory: $PWD" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Installing/updating Flutter dependencies..." -ForegroundColor Cyan
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ERROR: Failed to get Flutter dependencies" -ForegroundColor Red
        Write-Host "   Exit code: $LASTEXITCODE" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Host "❌ ERROR: Exception while getting dependencies: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Starting Flutter web app..." -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  The URL will appear below - CLICK IT!" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

try {
    flutter run -d web-server
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ ERROR: Flutter run failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "  - Port already in use (try: flutter run -d web-server --web-port 8080)" -ForegroundColor White
        Write-Host "  - Flutter not properly installed (run: flutter doctor)" -ForegroundColor White
        Write-Host "  - Missing dependencies (run: flutter pub get)" -ForegroundColor White
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Exception while running Flutter: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}