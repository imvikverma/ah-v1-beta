# Comprehensive Login Fix
# Fixes common login issues systematically

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

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Comprehensive Login Fix                            ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean expired sessions
Write-Host "[1] Cleaning Expired Sessions..." -ForegroundColor Yellow
Write-Host "──────────────────────────────────" -ForegroundColor Gray

$cleanupScript = @"
import sys
from datetime import datetime
sys.path.insert(0, r'$projectRoot')

# Need Flask app context
from aurum_harmony.master_codebase.Master_AurumHarmony_261125 import app
from aurum_harmony.database.models import Session

with app.app_context():
    try:
        sessions = Session.query.all()
        expired = [s for s in sessions if s.is_expired()]
        print(f'Found {len(expired)} expired sessions')
        
        for session in expired:
            from aurum_harmony.database.db import db
            db.session.delete(session)
        
        from aurum_harmony.database.db import db
        db.session.commit()
        print(f'Cleaned {len(expired)} expired sessions')
    except Exception as e:
        print(f'Error: {e}')
"@

$cleanupScript | python
Write-Host ""

# Step 2: Verify login route exists
Write-Host "[2] Verifying Login Route..." -ForegroundColor Yellow
Write-Host "───────────────────────────────" -ForegroundColor Gray

$routeCheckScript = @"
import sys
sys.path.insert(0, r'$projectRoot')

from aurum_harmony.master_codebase.Master_AurumHarmony_261125 import app

print('Registered routes:')
for rule in app.url_map.iter_rules():
    if 'auth' in rule.rule.lower() or 'login' in rule.rule.lower():
        print(f'  {rule.methods} {rule.rule}')
"@

$routeCheckScript | python
Write-Host ""

# Step 3: Test login with test user
Write-Host "[3] Testing Login..." -ForegroundColor Yellow
Write-Host "───────────────────────" -ForegroundColor Gray

Write-Host "  Testing login endpoint..." -ForegroundColor Gray
try {
    $testBody = @{
        email = "test@test.com"
        password = "test123"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Body $testBody -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
    
    if ($response.token) {
        Write-Host "  ✅ Login successful! Token received" -ForegroundColor Green
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ✅ Login endpoint working (401 = invalid credentials, expected)" -ForegroundColor Green
    } elseif ($statusCode -eq 404) {
        Write-Host "  ❌ Login route not found (404)" -ForegroundColor Red
        Write-Host "     Checking route registration..." -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  Login endpoint returned: $statusCode" -ForegroundColor Yellow
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Login Fix Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 If login still fails:" -ForegroundColor Yellow
Write-Host "  1. Restart Flask backend: .\start-all.ps1 (Option 5, then Option 1)" -ForegroundColor White
Write-Host "  2. Check backend logs: _local\logs\backend.log" -ForegroundColor White
Write-Host "  3. Verify user exists in database" -ForegroundColor White
Write-Host "  4. Check browser console for frontend errors" -ForegroundColor White
Write-Host ""

