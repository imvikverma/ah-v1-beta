# Quick Status Check for Live Market Test

$projectRoot = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
$logsDir = Join-Path $projectRoot "_local\logs"

Write-Host "Checking Live Market Test Status..." -ForegroundColor Cyan
Write-Host ""

# Find latest log file
$logFiles = Get-ChildItem -Path $logsDir -Filter "live_market_test_*.log" | Sort-Object LastWriteTime -Descending
if ($logFiles) {
    $latestLog = $logFiles[0]
    Write-Host "Latest Log: $($latestLog.Name)" -ForegroundColor Yellow
    Write-Host "Last Updated: $($latestLog.LastWriteTime)" -ForegroundColor Gray
    Write-Host ""
    
    # Show last 15 lines
    Write-Host "Recent Activity:" -ForegroundColor Cyan
    Get-Content $latestLog.FullName -Tail 15 | ForEach-Object {
        if ($_ -match "ERROR") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "WARNING") {
            Write-Host $_ -ForegroundColor Yellow
        } elseif ($_ -match "FILLED|OK|PASSED") {
            Write-Host $_ -ForegroundColor Green
        } else {
            Write-Host $_ -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No log files found. Test may not be running." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Checking for results..." -ForegroundColor Cyan
$resultFiles = Get-ChildItem -Path $logsDir -Filter "live_market_test_results_*.json" | Sort-Object LastWriteTime -Descending
if ($resultFiles) {
    Write-Host "Latest Results: $($resultFiles[0].Name)" -ForegroundColor Green
    Write-Host "Last Updated: $($resultFiles[0].LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "No results file yet. Test may still be running." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To generate comprehensive report, run:" -ForegroundColor Cyan
Write-Host "  python scripts\generate_comprehensive_report.py" -ForegroundColor White
