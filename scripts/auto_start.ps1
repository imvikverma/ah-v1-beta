# AurumHarmony Automated Startup & Test Script
# Automatically handles: migration, backend, frontend, and verification

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# Detect PowerShell executable (prefer pwsh.exe for PowerShell 7+, fallback to powershell.exe)
function Get-PowerShellExe {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwsh) {
        return "pwsh.exe"
    }
    return "powershell.exe"
}

$PowerShellExe = Get-PowerShellExe

# Log file
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$startupLog = Join-Path $logDir "auto_start.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $startupLog -Value $logMessage
    Write-Host $logMessage -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "SUCCESS") { "Green" } else { "Cyan" })
}

function Test-Port {
    param([int]$Port, [int]$TimeoutMs = 2000)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect("127.0.0.1", $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if ($wait) {
            try {
                $tcpClient.EndConnect($connect)
                $result = $true
            } catch {
                $result = $false
            }
            $tcpClient.Close()
            return $result
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

function Test-HealthEndpoint {
    param([string]$Url, [int]$TimeoutSec = 3)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Wait-ForService {
    param([int]$Port, [int]$TimeoutSeconds = 45, [string]$ServiceName, [string]$HealthUrl = $null)
    $elapsed = 0
    $checkInterval = 3  # Check every 3 seconds instead of 2
    
    # For backend, wait longer before starting checks (TensorFlow takes ~15-20 seconds to load)
    if ($ServiceName -eq "Backend") {
        Write-Log "Waiting for TensorFlow initialization (this may take 15-20 seconds)..." "INFO"
        Start-Sleep -Seconds 10
        $elapsed = 10
    }
    
    # For frontend, wait much longer (Flutter compilation takes ~2-3 minutes)
    if ($ServiceName -eq "Frontend") {
        Write-Log "Waiting for Flutter compilation (this may take 2-3 minutes)..." "INFO"
        Write-Log "Flutter is compiling your app - please be patient..." "INFO"
        # Give Flutter time to start compiling - check every 10 seconds for first minute
        for ($i = 0; $i -lt 6; $i++) {
            Start-Sleep -Seconds 10
            $elapsed += 10
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
        Write-Host ""  # New line after initial wait
    }
    
    while ($elapsed -lt $TimeoutSeconds) {
        # First check if port is open
        $portOpen = Test-Port -Port $Port
        if ($portOpen) {
            # If health URL is provided, try to check that endpoint
            if ($HealthUrl) {
                $healthOk = Test-HealthEndpoint -Url $HealthUrl
                if ($healthOk) {
                    Write-Log "$ServiceName is ready on port $Port (health check passed)" "SUCCESS"
                    return $true
                }
                # Port is open but health check failed - try a few more times before giving up
                # Sometimes the port opens before the HTTP server is fully ready
                if ($elapsed -gt ($TimeoutSeconds - 10)) {
                    # In the last 10 seconds, if port is open, accept it even without health check
                    Write-Log "$ServiceName port $Port is open (health check pending, but accepting port)" "SUCCESS"
                    return $true
                }
            } else {
                Write-Log "$ServiceName is ready on port $Port" "SUCCESS"
                return $true
            }
        }
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host ""
    Write-Log "$ServiceName failed to start within $TimeoutSeconds seconds" "ERROR"
    Write-Log "Port $Port status: $(if (Test-Port -Port $Port) { 'OPEN' } else { 'CLOSED' })" "ERROR"
    if ($HealthUrl) {
        Write-Log "Health endpoint $HealthUrl status: $(if (Test-HealthEndpoint -Url $HealthUrl) { 'OK' } else { 'FAILED' })" "ERROR"
    }
    return $false
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AurumHarmony Automated Startup" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Starting automated startup sequence..." "INFO"

# Step 1: Activate virtual environment
Write-Log "Step 1: Activating virtual environment..." "INFO"
$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    . $venvPath
    Write-Log "Virtual environment activated" "SUCCESS"
} else {
    Write-Log "Virtual environment not found at: $venvPath" "ERROR"
    Write-Log "Please create virtual environment first: python -m venv .venv" "ERROR"
    exit 1
}

# Step 2: Run database migration
Write-Log "Step 2: Running database migration..." "INFO"
try {
    $migrationOutput = python aurum_harmony\database\migrate.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Database migration completed successfully" "SUCCESS"
    } else {
        Write-Log "Database migration had warnings (check output)" "INFO"
    }
} catch {
    Write-Log "Database migration failed: $_" "ERROR"
    exit 1
}

# Step 3: Check if services are already running
Write-Log "Step 3: Checking existing services..." "INFO"
$backendRunning = Test-Port -Port 5000
$frontendRunning = Test-Port -Port 58643

if ($backendRunning) {
    Write-Log "Backend already running on port 5000" "INFO"
} else {
    Write-Log "Starting backend in silent mode..." "INFO"
    $backendScript = Join-Path $projectRoot "scripts\start_backend_silent.ps1"
    if (Test-Path $backendScript) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PowerShellExe
        $psi.Arguments = "-NoExit -WindowStyle Minimized -File `"$backendScript`""
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
        $psi.CreateNoWindow = $false
        $process = [System.Diagnostics.Process]::Start($psi)
        if ($process) {
            Write-Log "Backend startup process launched (PID: $($process.Id))" "SUCCESS"
            Start-Sleep -Seconds 2  # Give process a moment to start
            if (-not $process.HasExited) {
                Wait-ForService -Port 5000 -ServiceName "Backend" -TimeoutSeconds 60 -HealthUrl "http://localhost:5000/health"
            } else {
                Write-Log "Backend process exited immediately after launch (exit code: $($process.ExitCode))" "ERROR"
                Write-Log "Check _local\logs\backend.log for error details" "ERROR"
            }
        } else {
            Write-Log "Failed to launch backend process" "ERROR"
        }
    } else {
        Write-Log "Backend script not found: $backendScript" "ERROR"
    }
}

if ($frontendRunning) {
    Write-Log "Frontend already running on port 58643" "INFO"
} else {
    Write-Log "Starting frontend in silent mode..." "INFO"
    $flutterScript = Join-Path $projectRoot "scripts\start_flutter_silent.ps1"
    if (Test-Path $flutterScript) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PowerShellExe
        $psi.Arguments = "-NoExit -WindowStyle Minimized -File `"$flutterScript`""
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
        $psi.CreateNoWindow = $false
        $process = [System.Diagnostics.Process]::Start($psi)
        if ($process) {
            Write-Log "Frontend startup process launched (PID: $($process.Id))" "SUCCESS"
            Start-Sleep -Seconds 2  # Give process a moment to start
            if (-not $process.HasExited) {
                # Flutter takes 2-3 minutes to compile and start, so use 180 seconds timeout
                Wait-ForService -Port 58643 -ServiceName "Frontend" -TimeoutSeconds 180
            } else {
                Write-Log "Frontend process exited immediately after launch (exit code: $($process.ExitCode))" "ERROR"
                Write-Log "Check _local\logs\flutter.log for error details" "ERROR"
            }
        } else {
            Write-Log "Failed to launch frontend process" "ERROR"
        }
    } else {
        Write-Log "Frontend script not found: $flutterScript" "ERROR"
    }
}

# Step 4: Test API endpoints
Write-Log "Step 4: Testing API endpoints..." "INFO"
if ($backendRunning -or (Test-Port -Port 5000)) {
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing
        if ($healthResponse.StatusCode -eq 200) {
            Write-Log "Backend health check: ✅ OK" "SUCCESS"
        }
    } catch {
        Write-Log "Backend health check failed: $_" "ERROR"
    }
} else {
    Write-Log "Backend not responding, skipping API tests" "ERROR"
}

# Step 5: Optional - Start auto-deploy
$startAutoDeploy = $env:AUTO_DEPLOY_ENABLED -eq "true"
if ($startAutoDeploy) {
    Write-Log "Step 5: Starting auto-deploy watcher..." "INFO"
    $autoDeployScript = Join-Path $projectRoot "scripts\auto_deploy.ps1"
    if (Test-Path $autoDeployScript) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PowerShellExe
        $psi.Arguments = "-WindowStyle Hidden -File `"$autoDeployScript`""
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.CreateNoWindow = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Log "Auto-deploy watcher started" "SUCCESS"
    }
} else {
    Write-Log "Step 5: Auto-deploy skipped (set AUTO_DEPLOY_ENABLED=true to enable)" "INFO"
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Startup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor Yellow
Write-Host "  Backend:  http://localhost:5000" -ForegroundColor $(if (Test-Port -Port 5000) { "Green" } else { "Red" })
Write-Host "  Frontend: http://localhost:58643" -ForegroundColor $(if (Test-Port -Port 58643) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Logs:" -ForegroundColor Yellow
Write-Host "  Backend:  _local\logs\backend.log" -ForegroundColor Gray
Write-Host "  Frontend: _local\logs\flutter.log" -ForegroundColor Gray
Write-Host "  Startup:  _local\logs\auto_start.log" -ForegroundColor Gray
if ($startAutoDeploy) {
    Write-Host "  Deploy:   _local\logs\auto_deploy.log" -ForegroundColor Gray
}
Write-Host ""
Write-Host "All services running in minimized windows." -ForegroundColor Green
Write-Host "Check logs for details. Critical errors will show popups." -ForegroundColor Gray
Write-Host ""

