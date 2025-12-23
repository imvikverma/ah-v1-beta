# List All Generated Trading Reports
# Shows all available reports and allows viewing them

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
Set-Location $projectRoot

$reportsDir = Join-Path $projectRoot "_local\reports"

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Trading Reports List                                 ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $reportsDir)) {
    Write-Host "📁 Reports directory not found: $reportsDir" -ForegroundColor Yellow
    Write-Host "   Creating directory..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Host "   ✅ Directory created" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Generate your first report:" -ForegroundColor Cyan
    Write-Host "   .\scripts\generate_trading_report.ps1 -UserId <user_id>" -ForegroundColor White
    Write-Host ""
    exit 0
}

$reports = Get-ChildItem -Path $reportsDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if ($reports.Count -eq 0) {
    Write-Host "📭 No reports found in: $reportsDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Generate your first report:" -ForegroundColor Cyan
    Write-Host "   .\scripts\generate_trading_report.ps1 -UserId <user_id>" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host "📊 Found $($reports.Count) report(s):" -ForegroundColor Green
Write-Host ""

$index = 1
foreach ($report in $reports) {
    Write-Host "[$index] $($report.Name)" -ForegroundColor Cyan
    Write-Host "     Date: $($report.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "     Size: $([math]::Round($report.Length / 1KB, 2)) KB" -ForegroundColor Gray
    
    # Try to read and display summary
    try {
        $content = Get-Content $report.FullName -Raw | ConvertFrom-Json
        if ($content.total_trades) {
            Write-Host "     Trades: $($content.total_trades) | P&L: ₹$($content.net_profit)" -ForegroundColor White
        }
    } catch {
        # Ignore parse errors
    }
    Write-Host ""
    $index++
}

Write-Host "💡 To view a report:" -ForegroundColor Yellow
Write-Host "   Get-Content _local\reports\<filename>.json | ConvertFrom-Json | Format-List" -ForegroundColor White
Write-Host ""
Write-Host "💡 To generate a new report:" -ForegroundColor Yellow
Write-Host "   .\scripts\generate_trading_report.ps1 -UserId <user_id>" -ForegroundColor White
Write-Host ""

