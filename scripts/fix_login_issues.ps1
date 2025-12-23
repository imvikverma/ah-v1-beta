# Fix Login Issues
# Comprehensive diagnosis and fixes for login problems

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
Write-Host "║     Login Issues Diagnosis & Fix                      ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Backend Status
Write-Host "[1] Checking Backend Status..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray

$backendRunning = $false
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "  ✅ Flask Backend: Running on http://localhost:5000" -ForegroundColor Green
    $backendRunning = $true
} catch {
    Write-Host "  ❌ Flask Backend: Not running" -ForegroundColor Red
    Write-Host "     Start with: .\start-all.ps1 (Option 1 or 4)" -ForegroundColor Gray
}

# Step 2: Check Database
Write-Host "`n[2] Checking Database..." -ForegroundColor Yellow
Write-Host "───────────────────────────" -ForegroundColor Gray

$dbPath = Join-Path $projectRoot "aurum_harmony.db"
if (Test-Path $dbPath) {
    $dbSize = (Get-Item $dbPath).Length / 1KB
    Write-Host "  ✅ Database exists: $([math]::Round($dbSize, 2)) KB" -ForegroundColor Green
    
    # Check if database is locked
    try {
        $testScript = @"
import sqlite3
import sys
try:
    conn = sqlite3.connect(r'$dbPath', timeout=1.0)
    conn.execute('SELECT 1')
    conn.close()
    print('OK')
except sqlite3.OperationalError as e:
    if 'locked' in str(e).lower():
        print('LOCKED')
    else:
        print(f'ERROR: {e}')
except Exception as e:
    print(f'ERROR: {e}')
"@
        $result = $testScript | python 2>&1
        if ($result -match "LOCKED") {
            Write-Host "  ⚠️  Database is locked (another process using it)" -ForegroundColor Yellow
            Write-Host "     Stop all Python processes and try again" -ForegroundColor Gray
        } elseif ($result -match "OK") {
            Write-Host "  ✅ Database is accessible" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Database check: $result" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠️  Could not check database status" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Database not found: $dbPath" -ForegroundColor Red
    Write-Host "     Run migrations to create database" -ForegroundColor Gray
}

# Step 3: Check User Accounts
Write-Host "`n[3] Checking User Accounts..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray

if ($backendRunning) {
    try {
        $testScript = @"
import sys
sys.path.insert(0, r'$projectRoot')
from aurum_harmony.database.db import db
from aurum_harmony.database.models import User

try:
    users = User.query.all()
    print(f'Total users: {len(users)}')
    active_users = [u for u in users if u.is_active]
    print(f'Active users: {len(active_users)}')
    admin_users = [u for u in users if u.is_admin]
    print(f'Admin users: {len(admin_users)}')
    
    if users:
        print('\\nSample users:')
        for u in users[:3]:
            print(f'  - {u.email or u.phone} (ID: {u.id}, Active: {u.is_active}, Admin: {u.is_admin})')
except Exception as e:
    print(f'ERROR: {e}')
"@
        $result = $testScript | python 2>&1
        Write-Host $result -ForegroundColor White
    } catch {
        Write-Host "  ⚠️  Could not check users: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Backend not running - cannot check users" -ForegroundColor Yellow
}

# Step 4: Check Session Table
Write-Host "`n[4] Checking Sessions..." -ForegroundColor Yellow
Write-Host "─────────────────────────────" -ForegroundColor Gray

if ($backendRunning) {
    try {
        $testScript = @"
import sys
from datetime import datetime, timedelta
sys.path.insert(0, r'$projectRoot')
from aurum_harmony.database.db import db
from aurum_harmony.database.models import Session

try:
    sessions = Session.query.all()
    print(f'Total sessions: {len(sessions)}')
    
    now = datetime.utcnow()
    active_sessions = [s for s in sessions if not s.is_expired()]
    print(f'Active sessions: {len(active_sessions)}')
    
    expired_sessions = [s for s in sessions if s.is_expired()]
    print(f'Expired sessions: {len(expired_sessions)}')
    
    if expired_sessions:
        print('\\n⚠️  Found expired sessions - these should be cleaned up')
except Exception as e:
    print(f'ERROR: {e}')
"@
        $result = $testScript | python 2>&1
        Write-Host $result -ForegroundColor White
    } catch {
        Write-Host "  ⚠️  Could not check sessions: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Backend not running - cannot check sessions" -ForegroundColor Yellow
}

# Step 5: Test Login Endpoint
Write-Host "`n[5] Testing Login Endpoint..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray

if ($backendRunning) {
    Write-Host "  Testing: http://localhost:5000/api/auth/login" -ForegroundColor Gray
    try {
        $testBody = @{
            email = "test@test.com"
            password = "test123"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Body $testBody -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.token) {
            Write-Host "  ✅ Login endpoint responding" -ForegroundColor Green
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "  ✅ Login endpoint working (401 = invalid credentials, expected)" -ForegroundColor Green
        } elseif ($statusCode -eq 400) {
            Write-Host "  ✅ Login endpoint working (400 = validation error, expected)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Login endpoint returned: $statusCode" -ForegroundColor Yellow
            Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ⚠️  Backend not running - cannot test login endpoint" -ForegroundColor Yellow
}

# Step 6: Check Frontend Constants
Write-Host "`n[6] Checking Frontend Configuration..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────" -ForegroundColor Gray

$constantsFile = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib\constants.dart"
if (Test-Path $constantsFile) {
    $constants = Get-Content $constantsFile -Raw
    if ($constants -match "kBackendBaseUrl\s*=\s*['`"]([^'`"]+)['`"]") {
        $backendUrl = $matches[1]
        Write-Host "  Frontend Backend URL: $backendUrl" -ForegroundColor White
        
        if ($backendUrl -like "*localhost*" -or $backendUrl -like "*127.0.0.1*") {
            Write-Host "  ✅ Using localhost backend (good for development)" -ForegroundColor Green
        } elseif ($backendUrl -like "*saffronbolt.in*") {
            Write-Host "  ⚠️  Using production backend" -ForegroundColor Yellow
            Write-Host "     Make sure production API is accessible" -ForegroundColor Gray
        }
    }
    
    if ($constants -match "kBackendBaseUrlFallback\s*=\s*['`"]([^'`"]+)['`"]") {
        $fallbackUrl = $matches[1]
        Write-Host "  Frontend Fallback URL: $fallbackUrl" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️  Constants file not found" -ForegroundColor Yellow
}

# Step 7: Recommendations
Write-Host "`n[7] Recommendations..." -ForegroundColor Yellow
Write-Host "───────────────────────────" -ForegroundColor Gray

$recommendations = @()

if (-not $backendRunning) {
    $recommendations += "Start Flask backend: .\start-all.ps1 (Option 1 or 4)"
}

if (-not (Test-Path $dbPath)) {
    $recommendations += "Create database: Run migrations"
}

$recommendations += "Clear expired sessions: Run cleanup script"
$recommendations += "Test login with valid credentials"
$recommendations += "Check browser console for frontend errors"
$recommendations += "Verify token storage in SharedPreferences"

if ($recommendations.Count -gt 0) {
    foreach ($rec in $recommendations) {
        Write-Host "  • $rec" -ForegroundColor Cyan
    }
}

Write-Host "`n✅ Diagnosis Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Fix any issues found above" -ForegroundColor White
Write-Host "  2. Test login with a known good account" -ForegroundColor White
Write-Host "  3. Check browser console for errors" -ForegroundColor White
Write-Host "  4. Review auth_service.dart for token validation logic" -ForegroundColor White
Write-Host ""

