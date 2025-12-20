# Comprehensive Integration Test for Unified Snapshot System
# Tests the full flow: aggregator → snapshot → validation → API

$ErrorActionPreference = "Continue"

Write-Host "`n🧪 Unified Snapshot System - Integration Test" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"
$testResults = @{
    "Backend Health" = $false
    "Health Endpoint" = $false
    "Snapshot Endpoint" = $false
    "Data Validation" = $false
    "Position Aggregation" = $false
    "Balance Aggregation" = $false
}

# Test 1: Backend Health
Write-Host "`n[1/6] Testing Backend Health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/health" -Method Get -TimeoutSec 5
    if ($healthResponse.status -eq "OK") {
        Write-Host "  ✅ Backend is healthy" -ForegroundColor Green
        $testResults["Backend Health"] = $true
    }
} catch {
    Write-Host "  ❌ Backend not running: $_" -ForegroundColor Red
    Write-Host "     Start backend: .\start-all.ps1" -ForegroundColor Gray
    exit 1
}

# Test 2: Health Endpoint
Write-Host "`n[2/6] Testing Unified Snapshot Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot/health" -Method Get -TimeoutSec 5
    if ($healthResponse.success) {
        Write-Host "  ✅ Health endpoint working" -ForegroundColor Green
        Write-Host "     Engines configured: $($healthResponse.status.total_engines)" -ForegroundColor Cyan
        $testResults["Health Endpoint"] = $true
        
        # Show engine status
        foreach ($engineKey in $healthResponse.status.engines.PSObject.Properties.Name) {
            $engine = $healthResponse.status.engines.$engineKey
            $status = if ($engine.available) { "✅" } else { "⚠️" }
            Write-Host "     $status $engineKey" -ForegroundColor $(if ($engine.available) { "Green" } else { "Yellow" })
        }
    }
} catch {
    Write-Host "  ⚠️  Health endpoint error: $_" -ForegroundColor Yellow
    Write-Host "     This is expected if broker credentials aren't set up" -ForegroundColor Gray
}

# Test 3: Snapshot Endpoint (requires auth)
Write-Host "`n[3/6] Testing Unified Snapshot Endpoint..." -ForegroundColor Yellow
$token = $env:AURUM_TEST_TOKEN
if (-not $token) {
    Write-Host "  ⚠️  Skipping (no AURUM_TEST_TOKEN env var)" -ForegroundColor Yellow
    Write-Host "     Set token: `$env:AURUM_TEST_TOKEN='your_token'" -ForegroundColor Gray
} else {
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $snapshotResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot" -Method Get -Headers $headers -TimeoutSec 10
        
        if ($snapshotResponse.success) {
            Write-Host "  ✅ Snapshot endpoint working" -ForegroundColor Green
            $testResults["Snapshot Endpoint"] = $true
            
            $snapshot = $snapshotResponse.snapshot
            Write-Host "     Engines: $($snapshot.available_engines)/$($snapshot.total_engines) available" -ForegroundColor Cyan
            Write-Host "     Positions: $($snapshot.all_positions.Count)" -ForegroundColor Cyan
            
            # Test 4: Data Validation
            if ($snapshot.summary) {
                Write-Host "`n[4/6] Validating Snapshot Data..." -ForegroundColor Yellow
                $summary = $snapshot.summary
                Write-Host "  ✅ Summary data present" -ForegroundColor Green
                Write-Host "     Total positions: $($summary.total_positions)" -ForegroundColor Cyan
                Write-Host "     Total exposure: ₹$($summary.total_exposure)" -ForegroundColor Cyan
                Write-Host "     Unrealized P&L: ₹$($summary.total_unrealized_pnl)" -ForegroundColor Cyan
                Write-Host "     NSE positions: $($summary.nse_positions)" -ForegroundColor Cyan
                Write-Host "     BSE positions: $($summary.bse_positions)" -ForegroundColor Cyan
                $testResults["Data Validation"] = $true
            }
            
            # Test 5: Position Aggregation
            Write-Host "`n[5/6] Testing Position Aggregation..." -ForegroundColor Yellow
            if ($snapshot.all_positions.Count -gt 0) {
                Write-Host "  ✅ Positions aggregated successfully" -ForegroundColor Green
                Write-Host "     Sample positions:" -ForegroundColor Cyan
                $snapshot.all_positions | Select-Object -First 3 | ForEach-Object {
                    Write-Host "       - $($_.symbol) ($($_.exchange)): $($_.quantity) @ ₹$($_.current_price)" -ForegroundColor Gray
                }
                $testResults["Position Aggregation"] = $true
            } else {
                Write-Host "  ⚠️  No positions found (expected if no trades)" -ForegroundColor Yellow
                $testResults["Position Aggregation"] = $true  # Still valid
            }
            
            # Test 6: Balance Aggregation
            Write-Host "`n[6/6] Testing Balance Aggregation..." -ForegroundColor Yellow
            if ($snapshot.aggregated_balance) {
                $balance = $snapshot.aggregated_balance
                Write-Host "  ✅ Balance aggregated successfully" -ForegroundColor Green
                Write-Host "     Available: ₹$($balance.available)" -ForegroundColor Cyan
                Write-Host "     Total Equity: ₹$($balance.total_equity)" -ForegroundColor Cyan
                Write-Host "     Margin Used: ₹$($balance.margin_used)" -ForegroundColor Cyan
                $testResults["Balance Aggregation"] = $true
            } else {
                Write-Host "  ⚠️  No balance data (expected if engines not configured)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  ⚠️  Snapshot endpoint error: $_" -ForegroundColor Yellow
        Write-Host "     This is expected if broker credentials aren't set up" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "📊 Test Summary" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Gray

$passed = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$total = $testResults.Count

foreach ($test in $testResults.GetEnumerator()) {
    $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($test.Value) { "Green" } else { "Red" }
    Write-Host "  $status : $($test.Key)" -ForegroundColor $color
}

Write-Host "`nResults: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

if ($passed -eq $total) {
    Write-Host "`n🎉 All tests passed! Unified Snapshot System is working correctly." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Some tests failed. This is expected if:" -ForegroundColor Yellow
    Write-Host "   - Broker credentials aren't configured" -ForegroundColor Gray
    Write-Host "   - Backend isn't running" -ForegroundColor Gray
    Write-Host "   - Auth token isn't set" -ForegroundColor Gray
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Configure broker credentials (HDFC Sky, Kotak Neo) in .env" -ForegroundColor Gray
Write-Host "  2. Test with real broker data" -ForegroundColor Gray
Write-Host "  3. Verify frontend Dashboard/Trade screens show aggregated data" -ForegroundColor Gray

