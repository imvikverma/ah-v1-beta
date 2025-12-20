# Test Broker Integration with Unified Snapshot System
# Tests HDFC Sky and Kotak Neo integration end-to-end

$ErrorActionPreference = "Continue"

Write-Host "`n🚀 Broker Integration Test - Unified Snapshot System" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"

# Check environment variables
Write-Host "`n[1/5] Checking Broker Credentials..." -ForegroundColor Yellow

$hdfcConfigured = $false
$kotakConfigured = $false

# Check HDFC Sky
if ($env:HDFC_SKY_API_KEY -and $env:HDFC_SKY_API_SECRET) {
    Write-Host "  ✅ HDFC Sky credentials found" -ForegroundColor Green
    Write-Host "     API Key: $($env:HDFC_SKY_API_KEY.Substring(0, [Math]::Min(8, $env:HDFC_SKY_API_KEY.Length)))..." -ForegroundColor Gray
    $hdfcConfigured = $true
} else {
    Write-Host "  ⚠️  HDFC Sky credentials not found" -ForegroundColor Yellow
    Write-Host "     Set: HDFC_SKY_API_KEY, HDFC_SKY_API_SECRET, HDFC_SKY_TOKEN_ID" -ForegroundColor Gray
}

# Check Kotak Neo
if ($env:KOTAK_NEO_ACCESS_TOKEN -and $env:KOTAK_NEO_MOBILE_NUMBER -and $env:KOTAK_NEO_CLIENT_CODE) {
    Write-Host "  ✅ Kotak Neo credentials found" -ForegroundColor Green
    Write-Host "     Mobile: $($env:KOTAK_NEO_MOBILE_NUMBER)" -ForegroundColor Gray
    $kotakConfigured = $true
} else {
    Write-Host "  ⚠️  Kotak Neo credentials not found" -ForegroundColor Yellow
    Write-Host "     Set: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE" -ForegroundColor Gray
}

if (-not $hdfcConfigured -and -not $kotakConfigured) {
    Write-Host "`n⚠️  No broker credentials configured. Testing with Paper Trading only." -ForegroundColor Yellow
}

# Check backend
Write-Host "`n[2/5] Checking Backend..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/health" -Method Get -TimeoutSec 5
    Write-Host "  ✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend not running" -ForegroundColor Red
    Write-Host "     Start: .\start-all.ps1" -ForegroundColor Gray
    exit 1
}

# Test health endpoint
Write-Host "`n[3/5] Testing Unified Snapshot Health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot/health" -Method Get -TimeoutSec 5
    if ($healthResponse.success) {
        Write-Host "  ✅ Health endpoint working" -ForegroundColor Green
        Write-Host "     Engines configured: $($healthResponse.status.total_engines)" -ForegroundColor Cyan
        
        $availableCount = 0
        foreach ($engineKey in $healthResponse.status.engines.PSObject.Properties.Name) {
            $engine = $healthResponse.status.engines.$engineKey
            if ($engine.available) {
                $availableCount++
                Write-Host "     ✅ $engineKey : Available" -ForegroundColor Green
            } else {
                Write-Host "     ⚠️  $engineKey : Not available" -ForegroundColor Yellow
            }
        }
        Write-Host "     Available: $availableCount/$($healthResponse.status.total_engines)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ⚠️  Health endpoint error: $_" -ForegroundColor Yellow
}

# Test unified snapshot (requires auth)
Write-Host "`n[4/5] Testing Unified Snapshot (requires authentication)..." -ForegroundColor Yellow
$token = $env:AURUM_TEST_TOKEN
if (-not $token) {
    Write-Host "  ⚠️  No auth token found" -ForegroundColor Yellow
    Write-Host "     To test:" -ForegroundColor Gray
    Write-Host "     1. Login via frontend or API" -ForegroundColor Gray
    Write-Host "     2. Get token from browser DevTools → Application → Local Storage" -ForegroundColor Gray
    Write-Host "     3. Set: `$env:AURUM_TEST_TOKEN='your_token'" -ForegroundColor Gray
    Write-Host "     4. Re-run this script" -ForegroundColor Gray
} else {
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        Write-Host "  Fetching unified snapshot..." -ForegroundColor Gray
        $snapshotResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot" -Method Get -Headers $headers -TimeoutSec 15
        
        if ($snapshotResponse.success) {
            Write-Host "  ✅ Unified snapshot retrieved!" -ForegroundColor Green
            
            $snapshot = $snapshotResponse.snapshot
            Write-Host "`n  📊 Snapshot Summary:" -ForegroundColor Cyan
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
                Write-Host "     Margin Used: ₹$($balance.margin_used)" -ForegroundColor White
            }
            
            # Show engine breakdown
            Write-Host "`n  🔧 Engine Breakdown:" -ForegroundColor Cyan
            foreach ($engineKey in $snapshot.engine_snapshots.PSObject.Properties.Name) {
                $engine = $snapshot.engine_snapshots.$engineKey
                $status = if ($engine.is_available) { "✅" } else { "❌" }
                $posCount = $engine.positions.Count
                $errorInfo = if ($engine.error) { " - $($engine.error)" } else { "" }
                Write-Host "     $status $engineKey : $posCount positions$errorInfo" -ForegroundColor $(if ($engine.is_available) { "Green" } else { "Red" })
            }
            
            # Show sample positions
            if ($snapshot.all_positions.Count -gt 0) {
                Write-Host "`n  📈 Sample Positions:" -ForegroundColor Cyan
                $snapshot.all_positions | Select-Object -First 5 | ForEach-Object {
                    $pnlColor = if ($_.unrealized_pnl -ge 0) { "Green" } else { "Red" }
                    Write-Host "     • $($_.symbol) ($($_.exchange))" -ForegroundColor White
                    Write-Host "       Qty: $($_.quantity) | Price: ₹$($_.current_price) | P&L: ₹$($_.unrealized_pnl)" -ForegroundColor $pnlColor
                }
            }
        }
    } catch {
        Write-Host "  ⚠️  Snapshot error: $_" -ForegroundColor Yellow
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 401) {
                Write-Host "     Token expired or invalid. Please login again." -ForegroundColor Yellow
            } elseif ($statusCode -eq 500) {
                Write-Host "     Server error. Check backend logs." -ForegroundColor Yellow
            }
        }
    }
}

# Test orchestrator integration
Write-Host "`n[5/5] Testing Orchestrator Integration..." -ForegroundColor Yellow
Write-Host "  The orchestrator now uses BrokerAggregator for position checks" -ForegroundColor Gray
Write-Host "  Test by running: POST $backendUrl/api/orchestrator/run" -ForegroundColor Gray
Write-Host "  (This will use unified snapshot for risk checks)" -ForegroundColor Gray

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "✅ Broker Integration Test Complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Cyan
if (-not $hdfcConfigured -or -not $kotakConfigured) {
    Write-Host "  1. Configure broker credentials in .env file" -ForegroundColor Yellow
    Write-Host "     - HDFC Sky: HDFC_SKY_API_KEY, HDFC_SKY_API_SECRET, HDFC_SKY_TOKEN_ID" -ForegroundColor Gray
    Write-Host "     - Kotak Neo: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE" -ForegroundColor Gray
}
Write-Host "  2. Authenticate Kotak Neo (TOTP + MPIN) via frontend or API" -ForegroundColor Gray
Write-Host "  3. Test unified snapshot endpoint with real broker data" -ForegroundColor Gray
Write-Host "  4. Verify frontend Dashboard/Trade screens show aggregated data" -ForegroundColor Gray
Write-Host "  5. Run orchestrator to test auto-trading with unified snapshot" -ForegroundColor Gray

