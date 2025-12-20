# Script to move all instructional files from root to _local/documentation/
# Run this script to ensure all files are properly organized

$projectRoot = "d:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
Set-Location $projectRoot

Write-Host "=== Moving instructional .md files ===" -ForegroundColor Cyan

# Move all instructional markdown files
$patterns = @(
    "WORKER_*.md",
    "QUICK_START*.md",
    "CLOUDFLARE_*.md",
    "TESTING_*.md",
    "STATUS_*.md",
    "WHY_*.md"
)

foreach ($pattern in $patterns) {
    $files = Get-ChildItem -Path "." -Filter $pattern -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $dest = Join-Path "_local\documentation" $file.Name
        Move-Item $file.FullName -Destination $dest -Force
        Write-Host "  Moved: $($file.Name)" -ForegroundColor Green
    }
}

# Move specific files
if (Test-Path "requirements.md") {
    Move-Item "requirements.md" -Destination "_local\documentation\requirements_notes.md" -Force
    Write-Host "  Moved: requirements.md" -ForegroundColor Green
}

if (Test-Path "tatus") {
    Move-Item "tatus" -Destination "_local\documentation\tatus" -Force
    Write-Host "  Moved: tatus" -ForegroundColor Green
}

Write-Host "`n=== Removing duplicate .ps1 files ===" -ForegroundColor Cyan

if (Test-Path "start_backend.ps1") {
    Remove-Item "start_backend.ps1" -Force
    Write-Host "  Removed: start_backend.ps1" -ForegroundColor Yellow
}

if (Test-Path "start_flutter.ps1") {
    Remove-Item "start_flutter.ps1" -Force
    Write-Host "  Removed: start_flutter.ps1" -ForegroundColor Yellow
}

Write-Host "`n=== Moving development files ===" -ForegroundColor Cyan

if (Test-Path "app.py") {
    Move-Item "app.py" -Destination "_local\development\test_broker_tokens.py" -Force
    Write-Host "  Moved: app.py" -ForegroundColor Green
}

if (Test-Path "AurumHarmonyTest.code-workspace") {
    Move-Item "AurumHarmonyTest.code-workspace" -Destination "_local\development\" -Force
    Write-Host "  Moved: workspace file" -ForegroundColor Green
}

Write-Host "`n=== Final root directory (should only have production files) ===" -ForegroundColor Cyan
Get-ChildItem -Path "." -File | Where-Object { $_.Extension -in @(".md", ".ps1", ".py") } | Select-Object Name | Format-Table -AutoSize

Write-Host "`n✓ Cleanup complete! Please refresh your IDE (F5 or restart)." -ForegroundColor Green
