# Fix Flutter Dependency and File Lock Issues
# Stops Flutter processes, cleans locked directories, and updates dependencies

$ErrorActionPreference = "Continue"

# Get project root
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) { break }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) { break }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) { break }
    $projectRoot = $parent
    $depth++
}

$flutterDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     🔧 Fixing Flutter Issues                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop Flutter processes
Write-Host "[1/4] Stopping Flutter/Dart processes..." -ForegroundColor Yellow
$procs = Get-Process -Name dart,flutter -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ Stopped $($procs.Count) process(es)" -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "   ℹ️  No Flutter processes running" -ForegroundColor Gray
}

# Step 2: Clean locked ephemeral directories
Write-Host "`n[2/4] Cleaning locked ephemeral directories..." -ForegroundColor Yellow
$ephemeralDirs = @(
    "linux\flutter\ephemeral",
    "ios\Flutter\ephemeral",
    "macos\Flutter\ephemeral",
    "windows\flutter\ephemeral"
)

$cleaned = 0
foreach ($dir in $ephemeralDirs) {
    $fullPath = Join-Path $flutterDir $dir
    if (Test-Path $fullPath) {
        try {
            Remove-Item -Recurse -Force $fullPath -ErrorAction Stop
            Write-Host "   ✅ Cleaned: $dir" -ForegroundColor Green
            $cleaned++
        } catch {
            Write-Host "   ⚠️  Could not clean: $dir (may be locked)" -ForegroundColor Yellow
        }
    }
}

if ($cleaned -gt 0) {
    Write-Host "   ✅ Cleaned $cleaned directory(ies)" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No directories to clean" -ForegroundColor Gray
}

# Step 3: Flutter clean
Write-Host "`n[3/4] Running flutter clean..." -ForegroundColor Yellow
Set-Location $flutterDir
$cleanOutput = flutter clean 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Flutter clean completed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Flutter clean had warnings (may be locked files)" -ForegroundColor Yellow
}

# Step 4: Update dependencies
Write-Host "`n[4/4] Updating Flutter dependencies..." -ForegroundColor Yellow
$pubOutput = flutter pub get 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Dependencies updated" -ForegroundColor Green
    
    # Check for outdated packages
    if ($pubOutput -match "packages have newer versions") {
        Write-Host "   ⚠️  Some packages have newer versions available" -ForegroundColor Yellow
        Write-Host "   💡 Run 'flutter pub outdated' to see details" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ Failed to update dependencies" -ForegroundColor Red
    Write-Host "   Error: $pubOutput" -ForegroundColor Red
    exit 1
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     ✅ Flutter Issues Fixed!                           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "💡 You can now start Flutter with:" -ForegroundColor Cyan
Write-Host "   .\scripts\start_flutter_silent.ps1" -ForegroundColor White
Write-Host ""

Set-Location $projectRoot

