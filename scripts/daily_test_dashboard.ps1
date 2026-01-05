# Daily Test Dashboard
# Shows comprehensive view of all tests run today

$projectRoot = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
$logsDir = Join-Path $projectRoot "_local\logs"
$reportsDir = Join-Path $projectRoot "_local\reports"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "DAILY TEST DASHBOARD" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$today = Get-Date -Format "yyyyMMdd"

# Find all test files from today
$testLogs = Get-ChildItem -Path $logsDir -Filter "*test*.log" | Where-Object { $_.LastWriteTime.Date -eq (Get-Date).Date } | Sort-Object LastWriteTime -Descending
$testResults = Get-ChildItem -Path $logsDir -Filter "*test*.json" | Where-Object { $_.LastWriteTime.Date -eq (Get-Date).Date } | Sort-Object LastWriteTime -Descending
$testReports = Get-ChildItem -Path $reportsDir -Filter "*report*.json" | Where-Object { $_.LastWriteTime.Date -eq (Get-Date).Date } | Sort-Object LastWriteTime -Descending

Write-Host "Today's Test Activity:" -ForegroundColor Yellow
Write-Host "  Log Files: $($testLogs.Count)" -ForegroundColor Gray
Write-Host "  Result Files: $($testResults.Count)" -ForegroundColor Gray
Write-Host "  Report Files: $($testReports.Count)" -ForegroundColor Gray
Write-Host ""

# Show latest test status
if ($testLogs) {
    $latestLog = $testLogs[0]
    Write-Host "Latest Test Log: $($latestLog.Name)" -ForegroundColor Cyan
    Write-Host "Last Updated: $($latestLog.LastWriteTime)" -ForegroundColor Gray
    Write-Host ""
    
    # Show last few lines
    $lastLines = Get-Content $latestLog.FullName -Tail 10 -ErrorAction SilentlyContinue
    if ($lastLines) {
        Write-Host "Recent Activity:" -ForegroundColor Yellow
        $lastLines | ForEach-Object {
            if ($_ -match "ERROR|FAILED") {
                Write-Host "  $_" -ForegroundColor Red
            } elseif ($_ -match "WARNING") {
                Write-Host "  $_" -ForegroundColor Yellow
            } elseif ($_ -match "FILLED|OK|PASSED|COMPLETED") {
                Write-Host "  $_" -ForegroundColor Green
            } else {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }
    Write-Host ""
}

# Show aggregate results if available
$aggregateResults = Get-ChildItem -Path $logsDir -Filter "multi_test_aggregate_results_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($aggregateResults) {
    Write-Host "Aggregate Results Available:" -ForegroundColor Green
    Write-Host "  File: $($aggregateResults.Name)" -ForegroundColor Gray
    Write-Host "  Last Updated: $($aggregateResults.LastWriteTime)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "View aggregate results:" -ForegroundColor Cyan
    Write-Host "  python scripts\view_aggregate_results.py" -ForegroundColor White
    Write-Host ""
}

# Show latest report
if ($testReports) {
    $latestReport = $testReports[0]
    Write-Host "Latest Report: $($latestReport.Name)" -ForegroundColor Green
    Write-Host "  Location: $($latestReport.FullName)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Quick Commands:" -ForegroundColor Yellow
Write-Host "  Check Status: .\scripts\check_test_status.ps1" -ForegroundColor White
Write-Host "  View Aggregates: python scripts\view_aggregate_results.py" -ForegroundColor White
Write-Host "  Generate Report: python scripts\generate_comprehensive_report.py" -ForegroundColor White
Write-Host "  Run More Tests: .\scripts\run_continuous_tests.ps1 -NumRuns 3 -DurationMinutes 20" -ForegroundColor White
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
