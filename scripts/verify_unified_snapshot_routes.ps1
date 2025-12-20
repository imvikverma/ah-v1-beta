# Verify Unified Snapshot Routes are Available
# Quick check to see if routes are registered

$ErrorActionPreference = "Continue"

Write-Host "`n🔍 Verifying Unified Snapshot Routes" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$backendUrl = "http://localhost:5000"

# Test health endpoint
Write-Host "`n[1/2] Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/unified-snapshot/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅ Health endpoint is available!" -ForegroundColor Green
    Write-Host "     Status: $($response.StatusCode)" -ForegroundColor Cyan
    
    $data = $response.Content | ConvertFrom-Json
    if ($data.success) {
        Write-Host "     Engines configured: $($data.status.total_engines)" -ForegroundColor Cyan
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "  ❌ Route not found (404)" -ForegroundColor Red
        Write-Host "     Backend needs to be restarted to load new routes!" -ForegroundColor Cyan
        Write-Host "`n     Fix: Restart backend" -ForegroundColor Cyan
        Write-Host "     1. Stop current backend (Ctrl+C)" -ForegroundColor Gray
        Write-Host "     2. Restart: .\start-all.ps1" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Cyan
    }
}

# Test main snapshot endpoint (no auth check, just route check)
Write-Host "`n[2/2] Testing Snapshot Endpoint Route..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/unified-snapshot" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  ✅ Snapshot endpoint route exists!" -ForegroundColor Green
    Write-Host "     Status: $($response.StatusCode)" -ForegroundColor Cyan
    if ($response.StatusCode -eq 401) {
        Write-Host "     (401 = Route works, just needs authentication)" -ForegroundColor Gray
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "  ❌ Route not found (404)" -ForegroundColor Red
        Write-Host "     Backend needs restart!" -ForegroundColor Yellow
    } elseif ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ✅ Route exists (401 = needs auth, which is expected)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Cyan
    }
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "✅ Route Verification Complete" -ForegroundColor Green

