# Diagnose exactly when RemoteException occurs in start-all.ps1
# This will run Option 4 with detailed logging at each step

$ErrorActionPreference = "Continue"
$ErrorView = "NormalView"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$logFile = Join-Path $projectRoot "_local\logs\remoteexception_diagnosis_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Ensure logs directory exists
$logsDir = Join-Path $projectRoot "_local\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

Write-Host "`n=== RemoteException Diagnosis ===" -ForegroundColor Cyan
Write-Host "This will trace exactly when RemoteException occurs`n" -ForegroundColor Yellow

$log = @"
RemoteException Diagnosis - $(Get-Date)
=====================================

Project Root: $projectRoot
PowerShell Version: $($PSVersionTable.PSVersion)
PowerShell Edition: $($PSVersionTable.PSEdition)
Execution Policy: $(Get-ExecutionPolicy)
Language Mode: $($ExecutionContext.SessionState.LanguageMode)

"@

# Load start-all.ps1 functions
Write-Host "[1/5] Loading start-all.ps1 functions..." -ForegroundColor Cyan
try {
    $startAllPath = Join-Path $projectRoot "start-all.ps1"
    if (-not (Test-Path $startAllPath)) {
        throw "start-all.ps1 not found at: $startAllPath"
    }
    
    # Set the projectRoot variable before dot-sourcing so start-all.ps1 can use it
    # We'll create a temporary script that sets projectRoot first, then loads functions
    $scriptLines = Get-Content $startAllPath
    
    # Find where the menu loop starts (look for "# Main menu loop" or the "do {" that starts it)
    $menuStartIndex = -1
    for ($i = 0; $i -lt $scriptLines.Count; $i++) {
        if ($scriptLines[$i] -match '^\s*#\s*Main\s+menu\s+loop') {
            # Found the comment, menu loop starts a few lines after
            $menuStartIndex = $i
            break
        }
    }
    
    # If we found the menu start, extract everything before it
    if ($menuStartIndex -gt 0) {
        $functionsOnly = $scriptLines[0..($menuStartIndex - 1)] -join "`n"
        
        # Replace the $MyInvocation line with our projectRoot variable
        $functionsOnly = $functionsOnly -replace '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\$MyInvocation\.MyCommand\.Path', "`$projectRoot = '$projectRoot'"
        
        # Execute the modified script
        $scriptBlock = [scriptblock]::Create($functionsOnly)
        . $scriptBlock
    } else {
        # Fallback: just dot-source the file (it will try to run menu, but we can interrupt)
        Write-Host "   [WARN] Could not find menu loop start, using full script" -ForegroundColor Yellow
        . $startAllPath
    }
    
    $log += "[OK] Functions loaded successfully`n`n"
    Write-Host "   [OK] Functions loaded" -ForegroundColor Green
} catch {
    $log += "[ERROR] Failed to load functions:`n"
    $log += "Type: $($_.Exception.GetType().FullName)`n"
    $log += "Message: $($_.Exception.Message)`n"
    if ($_.Exception.InnerException) {
        $log += "Inner: $($_.Exception.InnerException.Message)`n"
    }
    $log += "Stack: $($_.ScriptStackTrace)`n`n"
    Write-Host "   [ERROR] Failed to load: $_" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "   Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
    }
    Set-Content -Path $logFile -Value $log -Force
    Start-Process notepad.exe -ArgumentList $logFile
    exit 1
}

# Test Start-Backend function step by step
Write-Host "`n[2/5] Testing Start-Backend function..." -ForegroundColor Cyan
$log += "=== Testing Start-Backend Function ===`n`n"

# Clear error variable before test
$Error.Clear()

try {
    Write-Host "   Calling Start-Backend..." -ForegroundColor Gray
    
    # Capture all output and errors
    $output = Start-Backend *>&1
    
    $log += "Function Output:`n"
    $log += ($output | Out-String)
    $log += "`n[OK] Start-Backend completed without exception`n`n"
    
    Write-Host "   [OK] Start-Backend completed" -ForegroundColor Green
    
} catch {
    Write-Host "   [ERROR] Exception caught in Start-Backend!" -ForegroundColor Red
    
    $log += @"
EXCEPTION IN Start-Backend:
===========================

Error Type: $($_.Exception.GetType().FullName)
Message: $($_.Exception.Message)

Full Exception:
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

Position:
$(if ($_.InvocationInfo.PositionMessage) { $_.InvocationInfo.PositionMessage } else { "None" })

"@
}

# Check for errors in $Error variable
Write-Host "`n[3/5] Checking for errors..." -ForegroundColor Cyan
$log += "`n=== Errors in `$Error Variable ===`n"
$log += "Total Errors: $($Error.Count)`n`n"

if ($Error.Count -gt 0) {
    for ($i = 0; $i -lt [Math]::Min($Error.Count, 20); $i++) {
        $err = $Error[$i]
        
        # Check if it's a RemoteException
        if ($err.Exception.GetType().FullName -match "RemoteException") {
            $log += @"
*** REMOTEEXCEPTION FOUND (Error #$($i + 1)) ***
===============================================
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
        } else {
            $log += "Error #$($i + 1): $($err.Exception.GetType().FullName) - $($err.Exception.Message)`n"
        }
    }
} else {
    $log += "No errors found`n"
}

# Test Invoke-BackendAndFrontend (Option 4)
Write-Host "`n[4/5] Testing Invoke-BackendAndFrontend (Option 4)..." -ForegroundColor Cyan
Write-Host "   (This is what runs when you select Option 4)`n" -ForegroundColor Yellow

$log += "`n=== Testing Invoke-BackendAndFrontend (Option 4) ===`n`n"

# Clear errors again
$Error.Clear()

try {
    Write-Host "   Calling Invoke-BackendAndFrontend..." -ForegroundColor Gray
    Write-Host "   (This will start backend and frontend)`n" -ForegroundColor Gray
    
    # Capture output
    $output = Invoke-BackendAndFrontend *>&1
    
    $log += "Function Output:`n"
    $log += ($output | Out-String)
    $log += "`n[OK] Invoke-BackendAndFrontend completed`n`n"
    
    Write-Host "   [OK] Invoke-BackendAndFrontend completed" -ForegroundColor Green
    
} catch {
    Write-Host "   [ERROR] Exception caught in Invoke-BackendAndFrontend!" -ForegroundColor Red
    
    $log += @"
EXCEPTION IN Invoke-BackendAndFrontend:
=======================================

Error Type: $($_.Exception.GetType().FullName)
Message: $($_.Exception.Message)

Full Exception:
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

"@
}

# Final error check
Write-Host "`n[5/5] Final error check..." -ForegroundColor Cyan
$log += "`n=== Final Error Check ===`n"
$log += "Total Errors: $($Error.Count)`n`n"

if ($Error.Count -gt 0) {
    for ($i = 0; $i -lt [Math]::Min($Error.Count, 20); $i++) {
        $err = $Error[$i]
        
        if ($err.Exception.GetType().FullName -match "RemoteException") {
            $log += @"
*** FINAL REMOTEEXCEPTION FOUND (Error #$($i + 1)) ***
====================================================
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
    }
}

# Save log
Set-Content -Path $logFile -Value $log -Force

Write-Host "`n=== Diagnosis Complete ===" -ForegroundColor Green
Write-Host "Full diagnosis saved to:" -ForegroundColor Yellow
Write-Host "  $logFile" -ForegroundColor Cyan
Write-Host "`nOpening diagnosis log..." -ForegroundColor Gray

Start-Process notepad.exe -ArgumentList $logFile

Write-Host "`n✅ Diagnosis log opened!" -ForegroundColor Green
Write-Host "Please review and share the contents." -ForegroundColor Yellow

