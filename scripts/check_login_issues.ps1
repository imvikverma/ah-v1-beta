# Check and Fix Login Issues
# Diagnoses and fixes common login problems

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== Login Issues Diagnostic & Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check 1: Backend running
Write-Host "[1/6] Checking Flask Backend..." -ForegroundColor Yellow
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($backend.StatusCode -eq 200) {
        Write-Host "   ✅ Backend is running" -ForegroundColor Green
        $backendRunning = $true
    } else {
        Write-Host "   ⚠️  Backend returned status: $($backend.StatusCode)" -ForegroundColor Yellow
        $backendRunning = $false
    }
} catch {
    Write-Host "   ❌ Backend is not running" -ForegroundColor Red
    Write-Host "      Start it with: .\start-all.ps1 → Option 1" -ForegroundColor Gray
    $backendRunning = $false
}

# Check 2: Worker API accessible
Write-Host "`n[2/6] Checking Cloudflare Worker API..." -ForegroundColor Yellow
try {
    $worker = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health" -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($worker.StatusCode -eq 200) {
        Write-Host "   ✅ Worker API is accessible" -ForegroundColor Green
        $workerRunning = $true
    } else {
        Write-Host "   ⚠️  Worker returned status: $($worker.StatusCode)" -ForegroundColor Yellow
        $workerRunning = $false
    }
} catch {
    Write-Host "   ❌ Worker API is not accessible" -ForegroundColor Red
    Write-Host "      This is OK - Flutter will fallback to Flask backend" -ForegroundColor Gray
    $workerRunning = $false
}

# Check 3: Worker login endpoint
Write-Host "`n[3/6] Testing Worker login endpoint..." -ForegroundColor Yellow
if ($workerRunning) {
    try {
        $loginBody = @{email="test@test.com";password="test"} | ConvertTo-Json
        $login = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "   Status: $($login.StatusCode)" -ForegroundColor Gray
    } catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
        if ($statusCode -eq 503) {
            Write-Host "   ⚠️  Worker returns 503 (Database not configured)" -ForegroundColor Yellow
            Write-Host "      Flutter will automatically fallback to Flask" -ForegroundColor Gray
        } elseif ($statusCode -eq 501) {
            Write-Host "   ⚠️  Worker returns 501 (bcrypt not supported)" -ForegroundColor Yellow
            Write-Host "      Flutter will automatically fallback to Flask" -ForegroundColor Gray
        } elseif ($statusCode -eq 401) {
            Write-Host "   ✅ Worker login endpoint working (401 = invalid credentials, expected)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Worker login returned: $statusCode" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   ⏭️  Skipped (Worker not accessible)" -ForegroundColor Gray
}

# Check 4: Flutter app running
Write-Host "`n[4/6] Checking Flutter frontend..." -ForegroundColor Yellow
try {
    $flutter = Invoke-WebRequest -Uri "http://localhost:58643" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($flutter.StatusCode -eq 200) {
        Write-Host "   ✅ Flutter frontend is running" -ForegroundColor Green
        $flutterRunning = $true
    } else {
        Write-Host "   ⚠️  Flutter returned status: $($flutter.StatusCode)" -ForegroundColor Yellow
        $flutterRunning = $false
    }
} catch {
    Write-Host "   ❌ Flutter frontend is not running" -ForegroundColor Red
    Write-Host "      Start it with: .\start-all.ps1 → Option 2" -ForegroundColor Gray
    $flutterRunning = $false
}

# Check 5: Database
Write-Host "`n[5/6] Checking database..." -ForegroundColor Yellow
$sqliteDb = Join-Path $projectRoot "aurum_harmony.db"
if (Test-Path $sqliteDb) {
    Write-Host "   ✅ SQLite database exists" -ForegroundColor Green
    
    # Check if database has users
    try {
        python -c "import sqlite3; conn = sqlite3.connect(r'$sqliteDb'); cursor = conn.cursor(); cursor.execute('SELECT COUNT(*) FROM users'); count = cursor.fetchone()[0]; print(f'   Users in database: {count}'); conn.close()" 2>&1 | Out-String | ForEach-Object {
            if ($_ -match "Users in database: (\d+)") {
                $userCount = $matches[1]
                if ([int]$userCount -gt 0) {
                    Write-Host "   ✅ Database has $userCount user(s)" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠️  Database has no users" -ForegroundColor Yellow
                    Write-Host "      Create a user via registration or migration" -ForegroundColor Gray
                }
            }
        }
    } catch {
        Write-Host "   ⚠️  Could not check database contents" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  SQLite database not found" -ForegroundColor Yellow
    Write-Host "      Run migration: .\start-all.ps1 → Option 1" -ForegroundColor Gray
}

# Check 6: Flutter auth service
Write-Host "`n[6/6] Checking Flutter auth service code..." -ForegroundColor Yellow
$authService = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib\services\auth_service.dart"
if (Test-Path $authService) {
    $content = Get-Content $authService -Raw
    if ($content -match "SERVICE_UNAVAILABLE") {
        Write-Host "   ✅ Auth service has 503 fallback handling" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Auth service may need 503 fallback update" -ForegroundColor Yellow
    }
    
    if ($content -match "BCRYPT_FALLBACK") {
        Write-Host "   ✅ Auth service has bcrypt fallback handling" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Auth service may need bcrypt fallback update" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Auth service file not found" -ForegroundColor Red
}

# Summary and recommendations
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host ""

$needsFix = $false
$missingServices = @()

if (-not $backendRunning) {
    Write-Host "❌ CRITICAL: Backend is not running" -ForegroundColor Red
    Write-Host "   Fix: .\start-all.ps1 → Option 1" -ForegroundColor Yellow
    $needsFix = $true
    $missingServices += "Backend"
    Write-Host ""
}

if (-not $flutterRunning) {
    Write-Host "❌ CRITICAL: Frontend is not running" -ForegroundColor Red
    Write-Host "   Fix: .\start-all.ps1 → Option 2" -ForegroundColor Yellow
    $needsFix = $true
    $missingServices += "Frontend"
    Write-Host ""
}

if ($backendRunning -and $flutterRunning) {
    Write-Host "✅ Both backend and frontend are running!" -ForegroundColor Green
    Write-Host "   Login should work at: http://localhost:58643" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 If login still fails:" -ForegroundColor Yellow
    Write-Host "   1. Check browser console for errors" -ForegroundColor Gray
    Write-Host "   2. Verify user exists in database" -ForegroundColor Gray
    Write-Host "   3. Check backend logs: _local\logs\backend.log" -ForegroundColor Gray
    Write-Host "   4. Check Flutter logs: _local\logs\flutter.log" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Start the missing services to enable login" -ForegroundColor Yellow
}

# Quick Fix Option
if ($needsFix) {
    Write-Host ""
    Write-Host "=== Quick Fix ===" -ForegroundColor Cyan
    Write-Host "Missing services: $($missingServices -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    $autoFix = Read-Host "Would you like to start the missing services automatically? (Y/N)"
    
    if ($autoFix -eq "Y" -or $autoFix -eq "y") {
        Write-Host "`nStarting missing services..." -ForegroundColor Green
        
        # Get PowerShell executable
        $PowerShellExe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
        
        if (-not $backendRunning) {
            Write-Host "[1/2] Starting Backend..." -ForegroundColor Yellow
            $backendScript = Join-Path $projectRoot "scripts\start_backend_silent.ps1"
            if (Test-Path $backendScript) {
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $PowerShellExe
                $psi.Arguments = "-NoExit -WindowStyle Minimized -File `"$backendScript`""
                $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
                $psi.CreateNoWindow = $false
                [System.Diagnostics.Process]::Start($psi) | Out-Null
                Write-Host "   ✅ Backend starting..." -ForegroundColor Green
                Start-Sleep -Seconds 3
            } else {
                Write-Host "   ❌ Backend script not found" -ForegroundColor Red
            }
        }
        
        if (-not $flutterRunning) {
            Write-Host "[2/2] Starting Frontend..." -ForegroundColor Yellow
            $flutterScript = Join-Path $projectRoot "scripts\start_flutter_silent.ps1"
            if (Test-Path $flutterScript) {
                # Check for existing Flutter processes
                $existingFlutter = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
                if ($existingFlutter) {
                    $existingFlutter | Stop-Process -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                }
                
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $PowerShellExe
                $psi.Arguments = "-NoExit -WindowStyle Minimized -File `"$flutterScript`""
                $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
                $psi.CreateNoWindow = $false
                $process = [System.Diagnostics.Process]::Start($psi)
                
                if ($process) {
                    Write-Host "   ✅ Frontend starting..." -ForegroundColor Green
                } else {
                    Write-Host "   ❌ Failed to start Frontend" -ForegroundColor Red
                }
            } else {
                Write-Host "   ❌ Frontend script not found" -ForegroundColor Red
            }
        }
        
        Write-Host "`n✅ Services started!" -ForegroundColor Green
        Write-Host "   - Backend: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "   - Frontend: http://localhost:58643" -ForegroundColor Cyan
        Write-Host "   - Wait a few seconds for services to fully start" -ForegroundColor Yellow
        Write-Host "   - Check logs: _local\logs\" -ForegroundColor Gray
        Write-Host ""
        Write-Host "💡 Run this diagnostic again in 10 seconds to verify everything is working" -ForegroundColor Yellow
    } else {
        Write-Host "`nManual fix required:" -ForegroundColor Yellow
        Write-Host "   .\start-all.ps1 → Option 3 (Run Both)" -ForegroundColor Cyan
    }
}

Write-Host ""

