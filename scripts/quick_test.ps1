# Quick Status Check Script
Write-Host "=== AurumHarmony Quick Status ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow

# Check if services are running
Write-Host "`nService Status:" -ForegroundColor Cyan
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect("localhost", 5000, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
    $backend = $false
    if ($wait) {
        $tcpClient.EndConnect($connect)
        $backend = $true
    }
    $tcpClient.Close()
    Write-Host "  Backend (5000):  $(if ($backend) { '✅ RUNNING' } else { '❌ NOT RUNNING' })" -ForegroundColor $(if ($backend) { "Green" } else { "Red" })
} catch {
    Write-Host "  Backend (5000):  ❌ NOT RUNNING" -ForegroundColor Red
}

try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect("localhost", 58643, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
    $frontend = $false
    if ($wait) {
        $tcpClient.EndConnect($connect)
        $frontend = $true
    }
    $tcpClient.Close()
    Write-Host "  Frontend (58643): $(if ($frontend) { '✅ RUNNING' } else { '❌ NOT RUNNING' })" -ForegroundColor $(if ($frontend) { "Green" } else { "Red" })
} catch {
    Write-Host "  Frontend (58643): ❌ NOT RUNNING" -ForegroundColor Red
}

# Check log files
Write-Host "`nLog Files:" -ForegroundColor Cyan
if (Test-Path "_local\logs\backend.log") {
    $backendLogSize = (Get-Item "_local\logs\backend.log").Length
    Write-Host "  backend.log: ✅ ($([math]::Round($backendLogSize/1KB, 2)) KB)" -ForegroundColor Green
    Write-Host "    Last line: $(Get-Content _local\logs\backend.log -Tail 1)" -ForegroundColor Gray
} else {
    Write-Host "  backend.log: ❌ Not found" -ForegroundColor Red
}

if (Test-Path "_local\logs\flutter.log") {
    $flutterLogSize = (Get-Item "_local\logs\flutter.log").Length
    Write-Host "  flutter.log: ✅ ($([math]::Round($flutterLogSize/1KB, 2)) KB)" -ForegroundColor Green
    Write-Host "    Last line: $(Get-Content _local\logs\flutter.log -Tail 1)" -ForegroundColor Gray
} else {
    Write-Host "  flutter.log: ❌ Not found" -ForegroundColor Red
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "To start everything: .\start-all.ps1 → Option 1" -ForegroundColor Yellow
Write-Host ""

