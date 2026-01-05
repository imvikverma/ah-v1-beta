# Auto Report Generator
# Generates reports at regular intervals during the test

param(
    [int]$IntervalMinutes = 15
)

$projectRoot = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
$venvPath = Join-Path $projectRoot ".venv"
$python = Join-Path $venvPath "Scripts\python.exe"
$reportScript = Join-Path $projectRoot "scripts\generate_comprehensive_report.py"

Write-Host "Auto Report Generator Started" -ForegroundColor Cyan
Write-Host "Generating reports every $IntervalMinutes minutes..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$reportCount = 0

while ($true) {
    $reportCount++
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "[$timestamp] Generating Report #$reportCount..." -ForegroundColor Cyan
    
    try {
        & $python $reportScript
        Write-Host "[OK] Report #$reportCount generated successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to generate report: $_" -ForegroundColor Red
    }
    
    Write-Host "Waiting $IntervalMinutes minutes until next report..." -ForegroundColor Gray
    Write-Host ""
    
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
