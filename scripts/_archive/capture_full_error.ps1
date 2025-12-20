# Capture Full Error Details from start-all.ps1
# This script runs start-all.ps1 and captures ALL error information

$ErrorActionPreference = "Continue"
$ErrorView = "NormalView"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$errorLogFile = Join-Path $projectRoot "_local\logs\full_error_capture_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Ensure logs directory exists
$logsDir = Join-Path $projectRoot "_local\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

Write-Host "`n=== Full Error Capture Script ===" -ForegroundColor Cyan
Write-Host "This will run start-all.ps1 and capture ALL error details" -ForegroundColor Yellow
Write-Host "Error log will be saved to: $errorLogFile" -ForegroundColor Gray
Write-Host ""

# Capture all output and errors
$errorOutput = @"
FULL ERROR CAPTURE - $(Get-Date)
=====================================

Project Root: $projectRoot
PowerShell Version: $($PSVersionTable.PSVersion)
PowerShell Edition: $($PSVersionTable.PSEdition)
Execution Policy: $(Get-ExecutionPolicy)
Language Mode: $($ExecutionContext.SessionState.LanguageMode)

"@

# Try to run start-all.ps1 and capture everything
try {
    Write-Host "Running start-all.ps1..." -ForegroundColor Green
    Write-Host "When the menu appears, select option 4 (Backend + Frontend)" -ForegroundColor Yellow
    Write-Host "The error will be captured automatically.`n" -ForegroundColor Gray
    
    # Redirect all streams
    $scriptPath = Join-Path $projectRoot "start-all.ps1"
    
    # Run the script and capture errors
    $errorOutput += "`n=== Script Execution Started ===`n`n"
    
    # We'll use a job to capture output
    $job = Start-Job -ScriptBlock {
        param($scriptPath)
        Set-Location (Split-Path -Parent $scriptPath)
        $ErrorActionPreference = "Continue"
        $ErrorView = "NormalView"
        
        try {
            & $scriptPath 2>&1
        } catch {
            # Capture the error
            $errorDetails = @"
EXCEPTION CAUGHT:
================
Error Type: $($_.Exception.GetType().FullName)
Message: $($_.Exception.Message)

Full Exception:
$($_.Exception | Format-List * -Force | Out-String)

Inner Exception:
$(if ($_.Exception.InnerException) {
    $_.Exception.InnerException | Format-List * -Force | Out-String
} else {
    "None"
})

Stack Trace:
$(if ($_.ScriptStackTrace) { $_.ScriptStackTrace } else { "None" })

Error Record:
$($_ | Format-List * -Force | Out-String)

Position Message:
$(if ($_.InvocationInfo.PositionMessage) { $_.InvocationInfo.PositionMessage } else { "None" })
"@
            return $errorDetails
        }
    } -ArgumentList $scriptPath
    
    Write-Host "Job started. Waiting for error or completion..." -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop and view captured errors`n" -ForegroundColor Yellow
    
    # Wait for job with timeout
    $job | Wait-Job -Timeout 30 | Out-Null
    
    if ($job.State -eq "Running") {
        Write-Host "`n[INFO] Script is running (menu displayed). Stopping job to capture current state..." -ForegroundColor Yellow
        Stop-Job $job -ErrorAction SilentlyContinue
    }
    
    $jobOutput = Receive-Job $job
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    
    $errorOutput += $jobOutput
    
} catch {
    # Capture the outer exception
    $errorOutput += @"
OUTER EXCEPTION:
===============
Error Type: $($_.Exception.GetType().FullName)
Message: $($_.Exception.Message)

Full Exception:
$($_.Exception | Format-List * -Force | Out-String)

Inner Exception:
$(if ($_.Exception.InnerException) {
    $_.Exception.InnerException | Format-List * -Force | Out-String
} else {
    "None"
})

Stack Trace:
$(if ($_.ScriptStackTrace) { $_.ScriptStackTrace } else { "None" })

Error Record:
$($_ | Format-List * -Force | Out-String)

Position Message:
$(if ($_.InvocationInfo.PositionMessage) { $_.InvocationInfo.PositionMessage } else { "None" })
"@
}

# Also capture $Error variable
$errorOutput += "`n`n=== Global Error Variable (\$Error) ===" -ForegroundColor Cyan
$errorOutput += "`nTotal Errors: $($Error.Count)`n`n"

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
    $err.Exception.InnerException | Format-List * -Force | Out-String
} else {
    "None"
})

"@
}

# Save to file
Set-Content -Path $errorLogFile -Value $errorOutput -Force

Write-Host "`n=== Error Capture Complete ===" -ForegroundColor Green
Write-Host "Full error details saved to:" -ForegroundColor Yellow
Write-Host "  $errorLogFile" -ForegroundColor Cyan
Write-Host "`nOpening error log..." -ForegroundColor Gray

# Open the file
Start-Process notepad.exe -ArgumentList $errorLogFile

Write-Host "`nError log opened in Notepad. Review the details and share them." -ForegroundColor Yellow
