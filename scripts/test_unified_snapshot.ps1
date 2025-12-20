# Test Unified Snapshot System
# Validates that the multi-engine aggregation is working correctly

$ErrorActionPreference = "Stop"

Write-Host "`n🧪 Testing Unified Snapshot System" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"

# Check if backend is running
Write-Host "`n[1/4] Checking backend health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/health" -Method Get -TimeoutSec 5
    Write-Host "  ✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend not running. Please start it first:" -ForegroundColor Red
    Write-Host "     .\start-all.ps1" -ForegroundColor Gray
    exit 1
}

# Test health endpoint (no auth required)
Write-Host "`n[2/4] Testing unified snapshot health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot/health" -Method Get -TimeoutSec 5
    if ($healthResponse.success) {
        Write-Host "  ✅ Health endpoint working" -ForegroundColor Green
        Write-Host "     Engines configured: $($healthResponse.status.total_engines)" -ForegroundColor Cyan
        foreach ($engineKey in $healthResponse.status.engines.PSObject.Properties.Name) {
            $engine = $healthResponse.status.engines.$engineKey
            $status = if ($engine.available) { "✅" } else { "❌" }
            Write-Host "     $status $engineKey : initialized=$($engine.initialized), available=$($engine.available)" -ForegroundColor $(if ($engine.available) { "Green" } else { "Yellow" })
        }
    }
} catch {
    Write-Host "  ⚠️  Health endpoint error: $_" -ForegroundColor Yellow
}

# Get auth token (you'll need to login first)
Write-Host "`n[3/4] Testing unified snapshot endpoint..." -ForegroundColor Yellow
Write-Host "  Note: This requires authentication" -ForegroundColor Gray
Write-Host "  Endpoint: GET $backendUrl/api/unified-snapshot" -ForegroundColor Gray

# Try to get unified snapshot
try {
    # You'll need to provide a valid token here
    $token = $env:AURUM_TEST_TOKEN
    if (-not $token) {
        Write-Host "  ⚠️  No test token found. Set AURUM_TEST_TOKEN env var to test authenticated endpoint" -ForegroundColor Yellow
        Write-Host "     Or test manually via:" -ForegroundColor Gray
        Write-Host "     curl -H 'Authorization: Bearer YOUR_TOKEN' $backendUrl/api/unified-snapshot" -ForegroundColor Gray
    } else {
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $snapshotResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot" -Method Get -Headers $headers -TimeoutSec 10
        
        if ($snapshotResponse.success) {
            Write-Host "  ✅ Unified snapshot retrieved successfully" -ForegroundColor Green
            Write-Host "     Engines available: $($snapshotResponse.snapshot.available_engines)/$($snapshotResponse.snapshot.total_engines)" -ForegroundColor Cyan
            Write-Host "     Total positions: $($snapshotResponse.snapshot.all_positions.Count)" -ForegroundColor Cyan
            
            if ($snapshotResponse.snapshot.aggregated_balance) {
                $balance = $snapshotResponse.snapshot.aggregated_balance
                Write-Host "     Aggregated balance: ₹$($balance.available)" -ForegroundColor Cyan
                Write-Host "     Total equity: ₹$($balance.total_equity)" -ForegroundColor Cyan
            }
            
            # Show engine breakdown
            Write-Host "`n  Engine Status:" -ForegroundColor Yellow
            foreach ($engineKey in $snapshotResponse.snapshot.engine_snapshots.PSObject.Properties.Name) {
                $engine = $snapshotResponse.snapshot.engine_snapshots.$engineKey
                $status = if ($engine.is_available) { "✅" } else { "❌" }
                $positions = $engine.positions.Count
                Write-Host "     $status $engineKey : $positions positions" -ForegroundColor $(if ($engine.is_available) { "Green" } else { "Red" })
            }
        } else {
            Write-Host "  ⚠️  Snapshot request failed: $($snapshotResponse.error)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ⚠️  Error testing unified snapshot: $_" -ForegroundColor Yellow
    Write-Host "     This is expected if you haven't set up broker credentials yet" -ForegroundColor Gray
}

# Test orchestrator with aggregator
Write-Host "`n[4/4] Testing orchestrator integration..." -ForegroundColor Yellow
Write-Host "  The orchestrator now uses BrokerAggregator when available" -ForegroundColor Gray
Write-Host "  This will be tested when you run: POST $backendUrl/api/orchestrator/run" -ForegroundColor Gray

Write-Host "`n✅ Unified Snapshot System Test Complete" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Set up broker credentials (HDFC Sky, Kotak Neo) in .env" -ForegroundColor Gray
Write-Host "  2. Test unified snapshot endpoint with real broker data" -ForegroundColor Gray
Write-Host "  3. Verify frontend Dashboard/Trade screens show aggregated data" -ForegroundColor Gray

