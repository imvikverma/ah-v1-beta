# Quick Test - Unified Snapshot with Auth Token
# Tests the unified snapshot endpoint with your auth token
# Usage: .\test_unified_snapshot_quick.ps1 -Token "your_token_here"
#        .\test_unified_snapshot_quick.ps1 (will prompt or try clipboard)

param(
    [string]$Token
)

$ErrorActionPreference = "Continue"

Write-Host "`n⚡ Quick Unified Snapshot Test" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"

# Get token from parameter, environment, clipboard, or prompt
if (-not $Token) {
    $Token = $env:AURUM_TEST_TOKEN
}

if (-not $Token) {
    # Try clipboard
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
        if ($clipboardText -and $clipboardText.Length -gt 50 -and $clipboardText -match '^[A-Za-z0-9\-_\.]+$') {
            Write-Host "`n📋 Found token in clipboard, using it..." -ForegroundColor Cyan
            $Token = $clipboardText
        }
    } catch {
        # Clipboard not available, continue to prompt
    }
}

if (-not $Token) {
    Write-Host "`n🔑 Enter your JWT token:" -ForegroundColor Cyan
    Write-Host "   (You can paste it here - right-click or Ctrl+V)" -ForegroundColor Gray
    Write-Host "   (Or copy token to clipboard before running this script)" -ForegroundColor Gray
    $Token = Read-Host "Token"
    
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Host "`n⚠️  No token provided. Skipping authenticated test..." -ForegroundColor Cyan
        Write-Host "   Tip: Run with -Token parameter: .\test_unified_snapshot_quick.ps1 -Token 'your_token'" -ForegroundColor Gray
        exit 0
    }
}

Write-Host "`n✅ Token received (length: $($Token.Length) chars)" -ForegroundColor Green

Write-Host "`n[1/2] Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot/health" -Method Get -TimeoutSec 5
    if ($healthResponse.success) {
        Write-Host "  ✅ Health check passed" -ForegroundColor Green
        Write-Host "     Engines: $($healthResponse.status.total_engines) configured" -ForegroundColor Cyan
        $available = ($healthResponse.status.engines.PSObject.Properties | Where-Object { $_.Value.available }).Count
        Write-Host "     Available: $available/$($healthResponse.status.total_engines)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/2] Testing Unified Snapshot..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "  Fetching snapshot from all engines..." -ForegroundColor Gray
    $snapshotResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot" -Method Get -Headers $headers -TimeoutSec 15
    
    if ($snapshotResponse.success) {
        Write-Host "  ✅ Unified snapshot retrieved!" -ForegroundColor Green
        
        $snapshot = $snapshotResponse.snapshot
        Write-Host "`n  📊 Results:" -ForegroundColor Cyan
        Write-Host "     Engines: $($snapshot.available_engines)/$($snapshot.total_engines) available" -ForegroundColor White
        Write-Host "     Positions: $($snapshot.all_positions.Count)" -ForegroundColor White
        
        if ($snapshot.summary) {
            $summary = $snapshot.summary
            Write-Host "     Total Exposure: ₹$($summary.total_exposure)" -ForegroundColor White
            Write-Host "     Unrealized P&L: ₹$($summary.total_unrealized_pnl)" -ForegroundColor White
            Write-Host "     NSE Positions: $($summary.nse_positions)" -ForegroundColor White
            Write-Host "     BSE Positions: $($summary.bse_positions)" -ForegroundColor White
        }
        
        if ($snapshot.aggregated_balance) {
            $balance = $snapshot.aggregated_balance
            Write-Host "`n  💰 Aggregated Balance:" -ForegroundColor Cyan
            Write-Host "     Available: ₹$($balance.available)" -ForegroundColor White
            Write-Host "     Total Equity: ₹$($balance.total_equity)" -ForegroundColor White
        }
        
        # Show engine status
        Write-Host "`n  🔧 Engine Status:" -ForegroundColor Cyan
        foreach ($engineKey in $snapshot.engine_snapshots.PSObject.Properties.Name) {
            $engine = $snapshot.engine_snapshots.$engineKey
            $status = if ($engine.is_available) { "✅" } else { "❌" }
            $posCount = $engine.positions.Count
            Write-Host "     $status $engineKey : $posCount positions" -ForegroundColor $(if ($engine.is_available) { "Green" } else { "Red" })
        }
        
        Write-Host "`n✅ Test Complete! Unified Snapshot System is working!" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Snapshot request failed: $($snapshotResponse.error)" -ForegroundColor Cyan
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ❌ Authentication failed (401)" -ForegroundColor Red
        Write-Host "     Token expired or invalid. Please login again." -ForegroundColor Cyan
    } elseif ($statusCode -eq 404) {
        Write-Host "  ❌ Route not found (404)" -ForegroundColor Red
        Write-Host "     Backend may need restart." -ForegroundColor Cyan
    } else {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Cyan
    }
}

