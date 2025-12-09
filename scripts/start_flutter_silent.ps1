# AurumHarmony Flutter Frontend Startup Script (Silent Mode)
# Runs in minimized window, only shows critical errors

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$flutterAppPath = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
Set-Location $flutterAppPath

# Log file
$logDir = Join-Path $projectRoot "_local\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "flutter.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    if ($Level -eq "ERROR" -or $Level -eq "CRITICAL") {
        Write-Host $logMessage -ForegroundColor Red
    }
}

function Show-CriticalError {
    param([string]$Message)
    Write-Log $Message "CRITICAL"
    # Show popup only for critical errors
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "AurumHarmony Flutter - Critical Error`n`n$Message`n`nCheck logs: $logFile",
            "Critical Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } catch {
        # Fallback if MessageBox fails
        Write-Host "CRITICAL ERROR: $Message" -ForegroundColor Red
    }
}

try {
    Write-Log "Starting Flutter Web App (Silent Mode)" "INFO"
    
    # Check Flutter - try multiple ways
    $flutterCmd = $null
    $flutterFound = $false
    
    # First, try to find Flutter in PATH
    try {
        $flutterTest = Get-Command flutter -ErrorAction Stop
        $flutterCmd = "flutter"
        $flutterFound = $true
        Write-Log "Flutter found in PATH: $($flutterTest.Source)" "INFO"
    } catch {
        Write-Log "Flutter not in PATH, trying common locations..." "INFO"
        # Try common Flutter paths
        $flutterPaths = @(
            "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
            "C:\flutter\bin\flutter.bat",
            "C:\Users\$env:USERNAME\flutter\bin\flutter.bat",
            "C:\src\flutter\bin\flutter.bat"
        )
        foreach ($path in $flutterPaths) {
            if (Test-Path $path) {
                $flutterCmd = $path
                $flutterFound = $true
                Write-Log "Flutter found at: $path" "INFO"
                break
            }
        }
    }
    
    if (-not $flutterFound -or -not $flutterCmd) {
        Show-CriticalError "Flutter not found. Please ensure Flutter is installed and in PATH, or update the script with your Flutter path."
        exit 1
    }
    
    # Test Flutter command with better error handling
    Write-Log "Testing Flutter installation..." "INFO"
    try {
        $flutterVersionOutput = & $flutterCmd --version 2>&1
        if ($LASTEXITCODE -eq 0 -or $flutterVersionOutput -match "Flutter") {
            $versionLine = ($flutterVersionOutput | Select-Object -First 1) -join ""
            Write-Log "Flutter found: $versionLine" "INFO"
        } else {
            $errorDetails = ($flutterVersionOutput | Out-String)
            Write-Log "Flutter version check failed. Output: $errorDetails" "ERROR"
            Show-CriticalError "Flutter command failed. Check Flutter installation. Error: $errorDetails"
            exit 1
        }
    } catch {
        Write-Log "Exception testing Flutter: $_" "ERROR"
        Show-CriticalError "Flutter command failed. Check Flutter installation. Exception: $_"
        exit 1
    }
    
    # Install dependencies
    Write-Log "Installing/updating Flutter dependencies..." "INFO"
    try {
        $pubGetOutput = & $flutterCmd pub get 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $pubGetOutput -notmatch "No dependencies changed|Running.*pub get") {
            Write-Log "pub get output: $pubGetOutput" "ERROR"
            Show-CriticalError "Failed to install Flutter dependencies. Exit code: $LASTEXITCODE`nOutput: $pubGetOutput"
            exit 1
        }
        Write-Log "Dependencies installed/verified" "INFO"
    } catch {
        Write-Log "Exception during pub get: $_" "ERROR"
        Show-CriticalError "Failed to install Flutter dependencies. Exception: $_"
        exit 1
    }
    
    # Check for existing Flutter processes and kill them
    Write-Log "Checking for existing Flutter processes..." "INFO"
    $flutterProcesses = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
    if ($flutterProcesses) {
        Write-Log "Found $($flutterProcesses.Count) existing Flutter process(es). Stopping them..." "INFO"
        $flutterProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    # Clean build directory to avoid lock issues (but don't fail if locked)
    Write-Log "Cleaning Flutter build directory..." "INFO"
    $buildPath = Join-Path $flutterAppPath "build"
    if (Test-Path $buildPath) {
        try {
            # Try to remove build directory (ignore errors if locked)
            Remove-Item -Path $buildPath -Recurse -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Write-Log "Build directory cleaned" "INFO"
        } catch {
            Write-Log "Build directory may be locked (safe to ignore): $_" "WARNING"
            # Don't fail - Flutter will handle locked files
        }
    }
    
    # Note: We don't try to clean .dart_tool or ephemeral directories here
    # Flutter clean will handle them, and deletion errors are safe to ignore
    
    # Check if port is already in use
    $webPort = 58643
    $portInUse = Get-NetTCPConnection -LocalPort $webPort -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Log "Port $webPort is already in use. Attempting to use a different port..." "WARNING"
        # Try alternative ports
        $altPorts = @(58644, 58645, 58646)
        foreach ($altPort in $altPorts) {
            $altPortInUse = Get-NetTCPConnection -LocalPort $altPort -ErrorAction SilentlyContinue
            if (-not $altPortInUse) {
                $webPort = $altPort
                Write-Log "Using port $webPort instead..." "INFO"
                break
            }
        }
        if ($webPort -eq 58643) {
            Show-CriticalError "All common ports (58643-58646) are in use. Please free a port or stop other Flutter instances."
            exit 1
        }
    }
    
    # Start Flutter web
    Write-Log "Starting Flutter web server on port $webPort..." "INFO"
    Write-Log "Frontend will be available at: http://localhost:$webPort" "INFO"
    
    # Run Flutter (output to log, errors to console)
    & $flutterCmd run -d web-server --web-port=$webPort 2>&1 | ForEach-Object {
        $line = $_
        Write-Log $line "INFO"
        # Check for critical errors
        if ($line -match "ERROR|FAILURE|Exception|Fatal") {
            Write-Host $line -ForegroundColor Red
        }
    }
    
} catch {
    Show-CriticalError "Unexpected error: $_"
    exit 1
}

