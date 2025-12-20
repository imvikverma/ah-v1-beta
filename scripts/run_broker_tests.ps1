# Master Broker Test Script
# Runs all broker-related tests in sequence

$ErrorActionPreference = "Continue"

Write-Host "`n🎯 Master Broker Test Suite" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Step 1: Setup Check
Write-Host "`n[Step 1/5] Checking Setup..." -ForegroundColor Yellow
& ".\scripts\setup_broker_test_env.ps1"

# Step 2: Test Individual Brokers
Write-Host "`n[Step 2/5] Testing Individual Brokers..." -ForegroundColor Yellow
Write-Host "  HDFC Sky:" -ForegroundColor Cyan
python scripts/brokers/test_hdfc_connection.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️  HDFC Sky test failed (this is OK if credentials aren't set)" -ForegroundColor Yellow
}

Write-Host "`n  Kotak Neo:" -ForegroundColor Cyan
python scripts/brokers/test_kotak_connection.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️  Kotak Neo test failed (this is OK if credentials aren't set)" -ForegroundColor Yellow
}

# Step 3: Check Backend
Write-Host "`n[Step 3/5] Checking Backend..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 5
    Write-Host "  ✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Backend not running" -ForegroundColor Red
    Write-Host "     Please start backend first: .\start-all.ps1" -ForegroundColor Yellow
    exit 1
}

# Step 4: Test Unified Snapshot Health
Write-Host "`n[Step 4/5] Testing Unified Snapshot Health..." -ForegroundColor Yellow
& ".\scripts\test_unified_snapshot.ps1"

# Step 5: Full Integration Test
Write-Host "`n[Step 5/5] Running Full Integration Test..." -ForegroundColor Yellow
Write-Host "  Note: This requires authentication token" -ForegroundColor Gray
Write-Host "  Set: `$env:AURUM_TEST_TOKEN='your_token'" -ForegroundColor Gray
& ".\scripts\test_broker_integration.ps1"

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "✅ All Tests Complete!" -ForegroundColor Green
Write-Host "`nSee scripts/QUICK_START_BROKER_TEST.md for detailed guide" -ForegroundColor Cyan

