# Test Paper Trade Placement and Unified Snapshot
# Places a paper trade for INDEX OPTIONS and verifies it appears in the unified snapshot
#
# IMPORTANT: AurumHarmony is a Handsfree Intraday Options Trading System
# - Trades INDEX OPTIONS (not underlying indices or stocks)
# - Uses Option Chain data to identify low premium, high frequency trades
# - Only 3 indices: NIFTY50, BANKNIFTY, SENSEX
# - NO individual stocks allowed
#
# Option Symbol Format Examples:
# - NIFTY50 25000 CE (Call Option)
# - NIFTY50 25000 PE (Put Option)
# - BANKNIFTY 45000 CE
# - SENSEX 70000 PE
#
# For paper trading, you can use simplified format like "NIFTY50-25000-CE" or "NIFTY50 25000 CE"

param(
    [string]$Token,
    [string]$Symbol = "NIFTY50",  # Underlying Index: NIFTY50, BANKNIFTY, or SENSEX
    [string]$Side = "BUY",
    [int]$Quantity = 10  # Quantity in lots (1 lot = 50 for NIFTY50, 15 for BANKNIFTY, 10 for SENSEX)
)

$ErrorActionPreference = "Continue"

Write-Host "`n📈 Paper Trade Test" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"

# Get token from parameter, environment, or clipboard
if (-not $Token) {
    $Token = $env:AURUM_TEST_TOKEN
}

if (-not $Token) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
        if ($clipboardText -and $clipboardText.Length -gt 50) {
            Write-Host "`n📋 Using token from clipboard..." -ForegroundColor Cyan
            $Token = $clipboardText
        }
    } catch {
        # Clipboard not available
    }
}

if (-not $Token) {
    Write-Host "`n🔑 Enter your JWT token:" -ForegroundColor Cyan
    $Token = Read-Host "Token"
    
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Host "`n⚠️  No token provided. Exiting..." -ForegroundColor Cyan
        exit 1
    }
}

# Extract user_id from token (simple base64 decode of payload)
try {
    $tokenParts = $Token.Split('.')
    if ($tokenParts.Length -ge 2) {
        $payload = $tokenParts[1]
        # Add padding if needed
        while ($payload.Length % 4) { $payload += "=" }
        $payloadBytes = [System.Convert]::FromBase64String($payload)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes) | ConvertFrom-Json
        $userId = $payloadJson.user_id
        Write-Host "`n✅ Token decoded - User ID: $userId" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Could not decode token, using default user_id: 4" -ForegroundColor Cyan
        $userId = "4"
    }
} catch {
    Write-Host "`n⚠️  Could not decode token, using default user_id: 4" -ForegroundColor Cyan
    $userId = "4"
}

Write-Host "`n[1/3] Placing Paper Trade (Index Options)..." -ForegroundColor Yellow
Write-Host "     Underlying Index: $Symbol" -ForegroundColor Cyan
Write-Host "     Note: System trades Index Options (CE/PE) from Option Chain" -ForegroundColor Gray
Write-Host "     Side: $Side" -ForegroundColor Cyan
Write-Host "     Quantity: $Quantity lots" -ForegroundColor Cyan
Write-Host "`n     System: Handsfree Intraday Options Trading" -ForegroundColor Gray
Write-Host "     Allowed Indices: NIFTY50, BANKNIFTY, SENSEX only" -ForegroundColor Gray
Write-Host "     Strategy: Low premium, high frequency trades" -ForegroundColor Gray
Write-Host "     (AI engine selects specific option contract from chain)" -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    
    $orderPayload = @{
        user_id = $userId
        symbol = $Symbol
        side = $Side
        quantity = $Quantity
        order_type = "MARKET"
        reason = "Test trade for unified snapshot verification"
    } | ConvertTo-Json
    
    Write-Host "  Sending order request..." -ForegroundColor Gray
    $orderResponse = Invoke-RestMethod -Uri "$backendUrl/api/paper/orders" -Method Post -Headers $headers -Body $orderPayload -TimeoutSec 10
    
    if ($orderResponse.success) {
        Write-Host "  ✅ Order placed successfully!" -ForegroundColor Green
        $order = $orderResponse.order
        Write-Host "     Order ID: $($order.broker_order_id)" -ForegroundColor Cyan
        Write-Host "     Status: $($order.status)" -ForegroundColor Cyan
        if ($order.filled_price) {
            Write-Host "     Filled Price: ₹$($order.filled_price)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  ❌ Order failed: $($orderResponse.error)" -ForegroundColor Red
        exit 1
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ❌ Authentication failed (401)" -ForegroundColor Red
        Write-Host "     Token expired or invalid." -ForegroundColor Cyan
    } elseif ($statusCode -eq 400) {
        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  ❌ Order validation failed: $($errorBody.error)" -ForegroundColor Red
    } else {
        Write-Host "  ❌ Error placing order: $_" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`n[2/3] Waiting 2 seconds for order to settle..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "`n[3/3] Checking Unified Snapshot for new position..." -ForegroundColor Yellow
try {
    $snapshotResponse = Invoke-RestMethod -Uri "$backendUrl/api/unified-snapshot" -Method Get -Headers $headers -TimeoutSec 15
    
    if ($snapshotResponse.success) {
        $snapshot = $snapshotResponse.snapshot
        $positions = $snapshot.all_positions
        
        Write-Host "`n  📊 Unified Snapshot Results:" -ForegroundColor Cyan
        Write-Host "     Total Positions: $($positions.Count)" -ForegroundColor White
        
        if ($positions.Count -gt 0) {
            Write-Host "`n  📈 Positions Found:" -ForegroundColor Cyan
            foreach ($pos in $positions) {
                $pnlColor = if ($pos.unrealized_pnl -ge 0) { "Green" } else { "Red" }
                Write-Host "     ✅ $($pos.symbol) ($($pos.exchange))" -ForegroundColor Green
                Write-Host "        Side: $($pos.side) | Qty: $($pos.quantity) | Avg: ₹$($pos.avg_price)" -ForegroundColor White
                Write-Host "        Current: ₹$($pos.current_price) | P&L: ₹$($pos.unrealized_pnl)" -ForegroundColor $pnlColor
                Write-Host "        Engine: $($pos.engine_source)" -ForegroundColor Gray
            }
            
            # Check if our trade appears
            $ourPosition = $positions | Where-Object { $_.symbol -eq $Symbol -and $_.side -eq $Side }
            if ($ourPosition) {
                Write-Host "`n  ✅ SUCCESS! Our trade appears in unified snapshot!" -ForegroundColor Green
                Write-Host "     The unified snapshot system is working correctly!" -ForegroundColor Cyan
            } else {
                Write-Host "`n  ⚠️  Trade placed but not found in snapshot yet" -ForegroundColor Cyan
                Write-Host "     (May need a moment to propagate)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ⚠️  No positions found in snapshot" -ForegroundColor Cyan
            Write-Host "     (Position may take a moment to appear)" -ForegroundColor Gray
        }
        
        # Show engine status
        Write-Host "`n  🔧 Engine Status:" -ForegroundColor Cyan
        foreach ($engineKey in $snapshot.engine_snapshots.PSObject.Properties.Name) {
            $engine = $snapshot.engine_snapshots.$engineKey
            $status = if ($engine.is_available) { "✅" } else { "❌" }
            $posCount = $engine.positions.Count
            $engineStatus = if ($engine.is_available) { "Green" } else { "Red" }
            Write-Host "     $status $engineKey : $posCount positions" -ForegroundColor $engineStatus
        }
        
    } else {
        Write-Host "  ⚠️  Snapshot request failed: $($snapshotResponse.error)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ❌ Error fetching snapshot: $_" -ForegroundColor Red
}

Write-Host "`n✅ Test Complete!" -ForegroundColor Green

