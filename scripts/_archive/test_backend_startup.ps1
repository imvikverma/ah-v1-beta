# Test Backend Startup and Capture ALL Errors
# This directly tests the WMI process creation code that causes RemoteException

$ErrorActionPreference = "Continue"
$ErrorView = "NormalView"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$errorLogFile = Join-Path $projectRoot "_local\logs\backend_startup_test_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Ensure logs directory exists
$logsDir = Join-Path $projectRoot "_local\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

Write-Host "`n=== Backend Startup Error Capture ===" -ForegroundColor Cyan
Write-Host "Testing WMI process creation (same code as Start-Backend)`n" -ForegroundColor Yellow

$errorOutput = @"
BACKEND STARTUP ERROR TEST - $(Get-Date)
========================================

Project Root: $projectRoot
PowerShell Version: $($PSVersionTable.PSVersion)
PowerShell Edition: $($PSVersionTable.PSEdition)
Execution Policy: $(Get-ExecutionPolicy)
Language Mode: $($ExecutionContext.SessionState.LanguageMode)
Current Directory: $(Get-Location)

"@

# Test the exact code from Start-Backend function
Write-Host "[1/4] Setting up paths..." -ForegroundColor Cyan

$wrapperScript = Join-Path $projectRoot "scripts" "start_backend_wrapper.bat"
$backendScript = Join-Path $projectRoot "scripts" "start_backend_silent.ps1"

$errorOutput += "Backend Script: $backendScript`n"
$errorOutput += "Wrapper Script: $wrapperScript`n"
$errorOutput += "Backend Script Exists: $(Test-Path $backendScript)`n"
$errorOutput += "Wrapper Script Exists: $(Test-Path $wrapperScript)`n`n"

if (-not (Test-Path $backendScript)) {
    $errorOutput += "[ERROR] Backend script not found!`n"
    Set-Content -Path $errorLogFile -Value $errorOutput -Force
    Write-Host "   [ERROR] Backend script not found!" -ForegroundColor Red
    Start-Process notepad.exe -ArgumentList $errorLogFile
    exit 1
}

Write-Host "   [OK] Scripts found" -ForegroundColor Green

# Test WMI process creation (the exact code from Start-Backend)
Write-Host "`n[2/4] Testing WMI process creation..." -ForegroundColor Cyan
Write-Host "   (This is where RemoteException occurs)`n" -ForegroundColor Yellow

$errorOutput += "=== Testing WMI Process Creation ===`n`n"

try {
    # Check language mode
    $languageMode = $ExecutionContext.SessionState.LanguageMode
    $errorOutput += "Language Mode: $languageMode`n"
    
    if ($languageMode -eq "ConstrainedLanguage") {
        $errorOutput += "[WARN] PowerShell is in ConstrainedLanguage mode`n"
    }
    
    # Get backend script full path
    Write-Host "   Resolving backend script path..." -ForegroundColor Gray
    $backendScriptFullPath = (Resolve-Path $backendScript -ErrorAction Stop).Path
    $errorOutput += "Backend Script Full Path: $backendScriptFullPath`n`n"
    Write-Host "   [OK] Path resolved: $backendScriptFullPath" -ForegroundColor Green
    
    # Get PowerShell path
    Write-Host "   Getting PowerShell executable path..." -ForegroundColor Gray
    $pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
    $errorOutput += "PowerShell Path: $pwshPath`n`n"
    Write-Host "   [OK] PowerShell found: $pwshPath" -ForegroundColor Green
    
    # Build command line
    Write-Host "   Building command line..." -ForegroundColor Gray
    $commandLine = "`"$pwshPath`" -NoExit -ExecutionPolicy Bypass -NoProfile -File `"$backendScriptFullPath`""
    $errorOutput += "Command Line: $commandLine`n`n"
    Write-Host "   [OK] Command line built" -ForegroundColor Green
    
    # Test WMI classes
    Write-Host "`n[3/4] Testing WMI classes..." -ForegroundColor Cyan
    try {
        $processClass = [WmiClass]"Win32_Process"
        $errorOutput += "[OK] Win32_Process class loaded`n"
        Write-Host "   [OK] Win32_Process class loaded" -ForegroundColor Green
    } catch {
        $errorOutput += "[ERROR] Failed to load Win32_Process: $($_.Exception.Message)`n"
        $errorOutput += "Type: $($_.Exception.GetType().FullName)`n"
        Write-Host "   [ERROR] Failed to load Win32_Process: $_" -ForegroundColor Red
        throw
    }
    
    try {
        $startupClass = [WmiClass]"Win32_ProcessStartup"
        $startup = $startupClass.CreateInstance()
        $errorOutput += "[OK] Win32_ProcessStartup instance created`n"
        Write-Host "   [OK] Win32_ProcessStartup instance created" -ForegroundColor Green
    } catch {
        $errorOutput += "[ERROR] Failed to create Win32_ProcessStartup: $($_.Exception.Message)`n"
        $errorOutput += "Type: $($_.Exception.GetType().FullName)`n"
        Write-Host "   [ERROR] Failed to create Win32_ProcessStartup: $_" -ForegroundColor Red
        throw
    }
    
    $startup.ShowWindow = 7  # SW_SHOWMINNOACTIVE (minimized)
    $errorOutput += "ShowWindow set to: 7 (minimized)`n`n"
    
    # THIS IS WHERE THE ERROR OCCURS - WMI Create call
    Write-Host "`n[4/4] Calling WMI Create (THIS IS WHERE ERROR OCCURS)..." -ForegroundColor Cyan
    Write-Host "   Working Directory: $projectRoot" -ForegroundColor Gray
    Write-Host "   Command: $commandLine" -ForegroundColor Gray
    Write-Host ""
    
    $errorOutput += "=== Calling WMI Create ===`n"
    $errorOutput += "Working Directory: $projectRoot`n"
    $errorOutput += "Command Line: $commandLine`n`n"
    
    $result = $processClass.Create($commandLine, $projectRoot, $startup)
    
    $errorOutput += "WMI Create Return Value: $($result.ReturnValue)`n"
    $errorOutput += "Process ID: $($result.ProcessId)`n`n"
    
    if ($result.ReturnValue -eq 0) {
        Write-Host "   [OK] Process created successfully! (PID: $($result.ProcessId))" -ForegroundColor Green
        $errorOutput += "[SUCCESS] Process created successfully!`n"
        $errorOutput += "Process ID: $($result.ProcessId)`n"
    } else {
        Write-Host "   [ERROR] WMI Create failed with return code: $($result.ReturnValue)" -ForegroundColor Red
        $errorOutput += "[ERROR] WMI Create failed with return code: $($result.ReturnValue)`n"
    }
    
} catch {
    Write-Host "   [ERROR] Exception caught!" -ForegroundColor Red
    
    $errorOutput += @"
EXCEPTION CAUGHT:
================

Error Type: $($_.Exception.GetType().FullName)
Message: $($_.Exception.Message)

Full Exception Object:
$($_.Exception | Format-List * -Force | Out-String)

Inner Exception:
$(if ($_.Exception.InnerException) {
    "Type: $($_.Exception.InnerException.GetType().FullName)`n"
    "Message: $($_.Exception.InnerException.Message)`n"
    "Full Inner Exception:`n"
    + ($_.Exception.InnerException | Format-List * -Force | Out-String)
} else {
    "None"
})

Stack Trace:
$(if ($_.ScriptStackTrace) { $_.ScriptStackTrace } else { "None" })

Error Record:
$($_ | Format-List * -Force | Out-String)

Position Message:
$(if ($_.InvocationInfo.PositionMessage) { $_.InvocationInfo.PositionMessage } else { "None" })

Line Number: $(if ($_.InvocationInfo.ScriptLineNumber) { $_.InvocationInfo.ScriptLineNumber } else { "Unknown" })
"@
}

# Capture $Error variable
Write-Host "`nCapturing global errors..." -ForegroundColor Cyan

$errorOutput += "`n`n=== Global Error Variable (\$Error) ==="
$errorOutput += "`nTotal Errors: $($Error.Count)`n`n"

if ($Error.Count -gt 0) {
    for ($i = 0; $i -lt [Math]::Min($Error.Count, 10); $i++) {
        $err = $Error[$i]
        $errorOutput += @"
Error #$($i + 1):
---------------
Type: $($err.Exception.GetType().FullName)
Message: $($err.Exception.Message)

Full Error:
$($err | Format-List * -Force | Out-String)

Inner Exception:
$(if ($err.Exception.InnerException) {
    "Type: $($err.Exception.InnerException.GetType().FullName)`n"
    "Message: $($err.Exception.InnerException.Message)`n"
    "Full Inner Exception:`n"
    + ($err.Exception.InnerException | Format-List * -Force | Out-String)
} else {
    "None"
})

Stack Trace:
$(if ($err.ScriptStackTrace) { $err.ScriptStackTrace } else { "None" })

"@
    }
} else {
    $errorOutput += "No errors in `$Error variable`n"
}

# Save to file
Set-Content -Path $errorLogFile -Value $errorOutput -Force

Write-Host "   [OK] Error details captured" -ForegroundColor Green

Write-Host "`n=== Error Capture Complete ===" -ForegroundColor Green
Write-Host "Full error details saved to:" -ForegroundColor Yellow
Write-Host "  $errorLogFile" -ForegroundColor Cyan
Write-Host "`nOpening error log..." -ForegroundColor Gray

# Open the file
Start-Process notepad.exe -ArgumentList $errorLogFile

Write-Host "`n✅ Error log opened in Notepad!" -ForegroundColor Green
Write-Host "Please share the contents of the error log file." -ForegroundColor Yellow
