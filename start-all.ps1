# AurumHarmony - Master Launcher Menu
# Double-click this file or run: .\start-all.ps1

# Enhanced error handling to capture RemoteException details
$ErrorActionPreference = "Continue"
$ErrorView = "NormalView"  # Show full error details including inner exceptions

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Detect PowerShell executable (prefer pwsh.exe for PowerShell 7+, fallback to powershell.exe)
function Get-PowerShellExe {
    # Check if pwsh.exe (PowerShell 7+) is available
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwsh) {
        return "pwsh.exe"
    }
    # Fallback to powershell.exe (PowerShell 5.1)
    return "powershell.exe"
}

$PowerShellExe = Get-PowerShellExe

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   AurumHarmony v1.0 Beta Launcher" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Production URLs:" -ForegroundColor Green
    Write-Host "  - https://ah.saffronbolt.in" -ForegroundColor White
    Write-Host "  - https://aurumharmony.saffronbolt.in" -ForegroundColor White
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host "  1. Launch All Processes [Normal]" -ForegroundColor Green
    Write-Host "  2. Launch All Processes with Fixes [Error Detection & Auto-Correction]" -ForegroundColor Yellow
    Write-Host "  3. Quick Deploy [1-Click: Build & Push to GitHub → Cloudflare]" -ForegroundColor Magenta
    Write-Host "  4. Invoke Backend + Frontend [Sequential with Health Check]" -ForegroundColor Cyan
    Write-Host "  5. Stop All Services [Clean shutdown of Backend + Frontend]" -ForegroundColor Red
    Write-Host "  6. Exit" -ForegroundColor Gray
    Write-Host ""
}

function Start-Backend {
    Write-Host "Starting Flask Backend (Silent Mode)..." -ForegroundColor Green
    Write-Host "Main app: http://localhost:5000" -ForegroundColor Yellow
    Write-Host "Admin panel: http://localhost:5001" -ForegroundColor Yellow
    Write-Host "Logs: _local\logs\backend.log" -ForegroundColor Gray
    Write-Host ""
    
    # Use batch file wrapper to avoid PowerShell 7.5.4 RemoteException
    # This is the most reliable method across all PowerShell versions
    $wrapperScript = Join-Path $projectRoot "scripts" "start_backend_wrapper.bat"
    $backendScript = Join-Path $projectRoot "scripts" "start_backend_silent.ps1"
    
    if (-not (Test-Path $backendScript)) {
        Write-Host "[ERROR] Backend script not found at: $backendScript" -ForegroundColor Red
        return
    }
    
    # Ensure wrapper exists
    if (-not (Test-Path $wrapperScript)) {
        Write-Host "[INFO] Creating backend wrapper..." -ForegroundColor Yellow
        # Get full path to PowerShell executable (respects fallback logic)
        $psExePath = (Get-Command $PowerShellExe -ErrorAction Stop).Source
        $wrapperContent = @"
@echo off
REM Wrapper for starting backend - avoids PowerShell 7.5.4 RemoteException
cd /d "%~dp0\.."
"$psExePath" -NoExit -ExecutionPolicy Bypass -NoProfile -File "%~dp0start_backend_silent.ps1"
"@
        try {
            Set-Content -Path $wrapperScript -Value $wrapperContent -Encoding ASCII -ErrorAction Stop
            Write-Host "   [OK] Wrapper created" -ForegroundColor Green
        } catch {
            Write-Host "   [ERROR] Failed to create wrapper: $_" -ForegroundColor Red
            return
        }
    }
    
    try {
        # Check language mode - ConstrainedLanguage can cause RemoteException
        $languageMode = $ExecutionContext.SessionState.LanguageMode
        if ($languageMode -eq "ConstrainedLanguage") {
            Write-Host "[WARN] PowerShell is in ConstrainedLanguage mode" -ForegroundColor Yellow
            Write-Host "   This may cause RemoteException. Consider running in FullLanguage mode." -ForegroundColor Yellow
        }
        
        # COMPLETE WORKAROUND: Use WMI to create process - bypasses Start-Process entirely
        # This is the only reliable way to avoid RemoteException in PowerShell 7.5.4
        $backendScriptFullPath = (Resolve-Path $backendScript -ErrorAction Stop).Path
        
        Write-Host "   Starting backend via WMI (bypasses RemoteException)..." -ForegroundColor Gray
        
        # Build command line for PowerShell (use detected PowerShell executable with fallback)
        $psExePath = (Get-Command $PowerShellExe -ErrorAction Stop).Source
        $commandLine = "`"$psExePath`" -NoExit -ExecutionPolicy Bypass -NoProfile -File `"$backendScriptFullPath`""
        
        # Use WMI Win32_Process Create method - completely bypasses Start-Process
        $processClass = [WmiClass]"Win32_Process"
        $startup = ([WmiClass]"Win32_ProcessStartup").CreateInstance()
        $startup.ShowWindow = 7  # SW_SHOWMINNOACTIVE (minimized)
        
        $result = $processClass.Create($commandLine, $projectRoot, $startup)
        
        if ($result.ReturnValue -eq 0) {
            Write-Host "[OK] Backend process created (PID: $($result.ProcessId))" -ForegroundColor Green
            Write-Host "   Waiting for initialization..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
            
            # Verify process is running
            $pwshProcess = Get-Process -Id $result.ProcessId -ErrorAction SilentlyContinue
            if ($pwshProcess) {
                Write-Host "[OK] Backend running (PID: $($pwshProcess.Id))" -ForegroundColor Green
                Write-Host "   Window minimized - check taskbar to restore if needed" -ForegroundColor Gray
            } else {
                Write-Host "[WARN] Process may have exited - check logs: _local\logs\backend.log" -ForegroundColor Yellow
            }
        } else {
            throw "WMI Create failed with return code: $($result.ReturnValue)"
        }
    } catch {
        # Capture error details but check if backend actually started
        $errorMsg = $_.Exception.Message
        $errorType = $_.Exception.GetType().FullName
        
        # Check if backend is actually running despite the error (RemoteException glitch)
        Start-Sleep -Milliseconds 2000  # Give backend time to start
        $backendCheck = Test-NetConnection -ComputerName localhost -Port 5000 -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if ($backendCheck) {
            # Backend is running! The error was just a visual glitch
            Write-Host "[OK] Backend started successfully (error was visual only)" -ForegroundColor Green
            Write-Host "   Backend is running on http://localhost:5000" -ForegroundColor Gray
            Write-Host "   (RemoteException was caught but backend works)" -ForegroundColor DarkGray
        } else {
            # Backend actually failed - show full error
            Write-Host "[ERROR] Failed to start Backend" -ForegroundColor Red
            Write-Host "   Error Type: $errorType" -ForegroundColor Red
            Write-Host "   Message: $errorMsg" -ForegroundColor Red
            
            # Check for inner exception (RemoteException often wraps the real error)
            if ($_.Exception.InnerException) {
                $innerMsg = $_.Exception.InnerException.Message
                $innerType = $_.Exception.InnerException.GetType().FullName
                Write-Host "   INNER EXCEPTION (this is the real error):" -ForegroundColor Yellow
                Write-Host "      Type: $innerType" -ForegroundColor Yellow
                Write-Host "      Message: $innerMsg" -ForegroundColor Yellow
                
                # Show full inner exception details
                if ($_.Exception.InnerException.StackTrace) {
                    Write-Host "   Inner Stack Trace:" -ForegroundColor Gray
                    Write-Host "      $($_.Exception.InnerException.StackTrace -replace "`r?`n", "`n      ")" -ForegroundColor DarkGray
                }
            }
            
            # Show stack trace
            if ($_.ScriptStackTrace) {
                Write-Host "   Stack Trace:" -ForegroundColor Gray
                Write-Host "      $($_.ScriptStackTrace -replace "`r?`n", "`n      ")" -ForegroundColor DarkGray
            }
        }
        
        # Save full error to file
        try {
            $errorFile = Join-Path $projectRoot "_local\logs\backend_start_error_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
            $errorOutput = @"
BACKEND START ERROR - $(Get-Date)

Error Type: $errorType
Message: $errorMsg

Full Exception:
$($_.Exception | Format-List * -Force | Out-String)

Inner Exception:
$(if ($_.Exception.InnerException) { $_.Exception.InnerException | Format-List * -Force | Out-String } else { "None" })

Stack Trace:
$(if ($_.ScriptStackTrace) { $_.ScriptStackTrace } else { "None" })

Error Record:
$($_ | Format-List * -Force | Out-String)
"@
            Set-Content -Path $errorFile -Value $errorOutput -ErrorAction SilentlyContinue
            Write-Host "   Full error saved to: $errorFile" -ForegroundColor Cyan
        } catch {
            # Ignore file save errors
        }
        
        Write-Host "   Backend script: $backendScriptFullPath" -ForegroundColor Gray
        Write-Host "   Manual start: cd '$projectRoot'; .\scripts\start_backend_silent.ps1" -ForegroundColor Yellow
        Write-Host "   Or use: .\scripts\start_backend_direct.ps1" -ForegroundColor Yellow
    }
}

function Start-Frontend {
    Write-Host "Starting Flutter Web App (Silent Mode)..." -ForegroundColor Green
    Write-Host "Frontend: http://localhost:58643 (or check logs if port differs)" -ForegroundColor Yellow
    Write-Host "Logs: _local\logs\flutter.log" -ForegroundColor Gray
    Write-Host ""
    
    $flutterScript = Join-Path $projectRoot "scripts\start_flutter_silent.ps1"
    if (Test-Path $flutterScript) {
        # Check for existing Flutter processes first
        $existingFlutter = Get-Process -Name "flutter" -ErrorAction SilentlyContinue
        if ($existingFlutter) {
            Write-Host "⚠️  Found existing Flutter process(es). They will be stopped." -ForegroundColor Yellow
            $existingFlutter | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        # Use WMI to avoid RemoteException (same method as backend)
        $flutterAppDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
        $flutterScriptFullPath = (Resolve-Path $flutterScript -ErrorAction Stop).Path
        
        try {
            # Use WMI Win32_Process Create method - bypasses Start-Process
            # Use detected PowerShell executable with fallback (pwsh.exe or powershell.exe)
            $psExePath = (Get-Command $PowerShellExe -ErrorAction Stop).Source
            $commandLine = "`"$psExePath`" -NoExit -ExecutionPolicy Bypass -NoProfile -File `"$flutterScriptFullPath`""
            
            $processClass = [WmiClass]"Win32_Process"
            $startup = ([WmiClass]"Win32_ProcessStartup").CreateInstance()
            $startup.ShowWindow = 7  # SW_SHOWMINNOACTIVE (minimized)
            
            $result = $processClass.Create($commandLine, $flutterAppDir, $startup)
            
            if ($result.ReturnValue -eq 0) {
                Write-Host "[OK] Flutter process started (PID: $($result.ProcessId))" -ForegroundColor Green
                Write-Host "   Window title: 'AurumHarmony - Frontend (Flutter)'" -ForegroundColor Cyan
                Write-Host "   Window minimized - restore from taskbar to use hot reload menu" -ForegroundColor Gray
                Write-Host "   Hot reload: Press 'r' | Hot restart: Press 'R' | Quit: Press 'q'" -ForegroundColor Cyan
                Write-Host "   Check logs for startup status: _local\logs\flutter.log" -ForegroundColor Gray
            } else {
                Write-Host "[ERROR] Failed to start Flutter (WMI return: $($result.ReturnValue))" -ForegroundColor Red
            }
        } catch {
            Write-Host "[ERROR] Failed to start Flutter: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "   Manual start: cd '$flutterAppDir'; .\scripts\start_flutter_silent.ps1" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Flutter script not found at: $flutterScript" -ForegroundColor Red
    }
}

function Invoke-CloudflareDeploy {
    Write-Host "Deploying to Cloudflare Pages..." -ForegroundColor Magenta
    Write-Host "This will build Flutter web and push to GitHub." -ForegroundColor Yellow
    Write-Host "Commit message will be auto-generated from CHANGELOG.md" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Tip: After deployment, use the auto-refresh tool:" -ForegroundColor Cyan
    Write-Host "   Open: scripts\firefox_auto_refresh.html" -ForegroundColor Gray
    Write-Host ""
    
    $deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
    if (Test-Path $deployScript) {
        Set-Location $projectRoot
        & $deployScript
    } else {
        Write-Host "Deploy script not found at: $deployScript" -ForegroundColor Red
        Write-Host "Creating basic deployment..." -ForegroundColor Yellow
        
        # Basic deployment steps
        $flutterDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
        Set-Location $flutterDir
        
        Write-Host "[1/4] Building Flutter web..." -ForegroundColor Cyan
        Set-Location $flutterDir
        # Suppress Flutter clean output to avoid confusing "Removed X of Y files" messages
        flutter clean 2>&1 | Out-Null
        Write-Host "   ✅ Clean completed" -ForegroundColor Green
        flutter pub get 2>&1 | Out-Null
        flutter build web --release 2>&1 | Out-Null
        Write-Host "   ✅ Build completed" -ForegroundColor Green
        
        Write-Host "`n[2/4] Copying to docs/..." -ForegroundColor Cyan
        Set-Location $projectRoot
        
        # Verify build exists
        $buildPath = Join-Path $flutterDir "build\web"
        if (-not (Test-Path $buildPath)) {
            Write-Host "❌ Build directory not found: $buildPath" -ForegroundColor Red
            return
        }
        
        # Clean and create docs
        $docsPath = Join-Path $projectRoot "docs"
        if (Test-Path $docsPath) {
            Remove-Item -Recurse -Force $docsPath
        }
        New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
        Copy-Item -Recurse "$buildPath\*" -Destination $docsPath -Force
        
        Write-Host "`n[3/4] Committing changes..." -ForegroundColor Cyan
        # Ensure we're in git repo
        if (-not (Test-Path ".git")) {
            Write-Host "❌ Not in a git repository!" -ForegroundColor Red
            return
        }
        
        $env:GIT_EDITOR = "true"
        git add docs
        $stagedFiles = git diff --staged --name-only
        if ($stagedFiles) {
            git commit -m "chore: Update Flutter web build for Cloudflare"
            
            Write-Host "`n[4/4] Pushing to GitHub..." -ForegroundColor Cyan
            $env:GIT_EDITOR = "true"
            git push origin main
            
            Write-Host "`n✅ Deployment initiated! Cloudflare will auto-deploy in ~60 seconds." -ForegroundColor Green
            Write-Host "Live at: https://ah.saffronbolt.in" -ForegroundColor Yellow
        } else {
            Write-Host "⚠️  No changes to commit. Build output is identical." -ForegroundColor Yellow
        }
    }
}

function Start-AutoDeploy {
    Write-Host "Starting File Watcher & Auto-Deploy..." -ForegroundColor Cyan
    Write-Host "This will watch for file changes and auto-deploy to GitHub & Cloudflare" -ForegroundColor Yellow
    Write-Host "Logs: _local\logs\watch_deploy.log" -ForegroundColor Gray
    Write-Host ""
    
    $watchScript = Join-Path $projectRoot "scripts\watch_and_deploy.ps1"
    if (Test-Path $watchScript) {
        # Run in minimized window (so you can see it's running)
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PowerShellExe
        $psi.Arguments = "-NoExit -WindowStyle Minimized -File `"$watchScript`""
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
        $psi.CreateNoWindow = $false
        $process = [System.Diagnostics.Process]::Start($psi)
        
        if ($process) {
            Write-Host "✅ File watcher started (PID: $($process.Id))" -ForegroundColor Green
            Write-Host "   Watching Flutter frontend files for changes" -ForegroundColor Gray
            Write-Host "   Auto-deploys when files change (min 2 min between deploys)" -ForegroundColor Gray
            Write-Host "   To stop: Close the minimized PowerShell window" -ForegroundColor Gray
        } else {
            Write-Host "❌ Failed to start file watcher" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Watch script not found: $watchScript" -ForegroundColor Red
    }
}

function Test-LoginIssues {
    Write-Host "Checking and fixing login issues..." -ForegroundColor Yellow
    Write-Host ""
    
    $checkScript = Join-Path $projectRoot "scripts\check_login_issues.ps1"
    if (Test-Path $checkScript) {
        Set-Location $projectRoot
        & $checkScript
    } else {
        Write-Host "❌ Login check script not found at: $checkScript" -ForegroundColor Red
    }
}

function Invoke-AllOtherProcesses {
    Write-Host "=== All Other Processes Menu ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Select what to run:" -ForegroundColor Yellow
    Write-Host "  1. Deploy to Cloudflare Pages (Build + Push)" -ForegroundColor Cyan
    Write-Host "  2. Deploy Cloudflare Worker (API - aurum-api)" -ForegroundColor Cyan
    Write-Host "  3. Setup D1 Database (Create & Migrate)" -ForegroundColor Cyan
    Write-Host "  4. Watch & Auto-Deploy (Watches file changes, auto-deploys)" -ForegroundColor Cyan
    Write-Host "  5. Run All (Deploy Pages + Worker + Setup D1)" -ForegroundColor Green
    Write-Host "  6. Back to Main Menu" -ForegroundColor Gray
    Write-Host ""
    
    $subChoice = Read-Host "Enter your choice (1-6)"
    
    switch ($subChoice) {
        "1" {
            Set-Location $projectRoot
            Invoke-CloudflareDeploy
        }
        "2" {
            Set-Location $projectRoot
            Deploy-Worker
        }
        "3" {
            Set-Location $projectRoot
            Initialize-D1Database
        }
        "4" {
            Set-Location $projectRoot
            Start-AutoDeploy
        }
        "5" {
            Set-Location $projectRoot
            Write-Host "`nRunning all deployment processes..." -ForegroundColor Green
            Write-Host "[1/3] Setting up D1 Database..." -ForegroundColor Yellow
            Initialize-D1Database
            Write-Host "`n[2/3] Deploying Worker..." -ForegroundColor Yellow
            Deploy-Worker
            Write-Host "`n[3/3] Deploying to Cloudflare Pages..." -ForegroundColor Yellow
            Invoke-CloudflareDeploy
            Write-Host "`n✅ All processes completed!" -ForegroundColor Green
        }
        "6" {
            return
        }
        default {
            Write-Host "Invalid choice" -ForegroundColor Red
        }
    }
}

function Deploy-Worker {
    Write-Host "Deploying Cloudflare Worker (aurum-api)..." -ForegroundColor Magenta
    Write-Host "This will deploy the API worker to: https://api.ah.saffronbolt.in" -ForegroundColor Yellow
    Write-Host ""
    
    $workerScript = Join-Path $projectRoot "scripts\deploy_worker.ps1"
    if (Test-Path $workerScript) {
        Set-Location $projectRoot
        & $workerScript
    } else {
        Write-Host "❌ Worker deploy script not found at: $workerScript" -ForegroundColor Red
    }
}

function Initialize-D1Database {
    Write-Host "Setting up D1 Database for Cloudflare Worker..." -ForegroundColor Magenta
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  • Check/Create D1 database" -ForegroundColor Gray
    Write-Host "  • Update wrangler.toml with database ID" -ForegroundColor Gray
    Write-Host "  • Migrate schema" -ForegroundColor Gray
    Write-Host "  • Optionally sync data from SQLite" -ForegroundColor Gray
    Write-Host ""
    
    $setupScript = Join-Path $projectRoot "scripts\setup_d1_complete.ps1"
    if (Test-Path $setupScript) {
        Set-Location $projectRoot
        & $setupScript
    } else {
        Write-Host "❌ D1 setup script not found at: $setupScript" -ForegroundColor Red
        Write-Host "   Falling back to legacy script..." -ForegroundColor Yellow
        $legacyScript = Join-Path $projectRoot "scripts\setup_d1_database.ps1"
        if (Test-Path $legacyScript) {
            & $legacyScript
        }
    }
}

function Show-Documentation {
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  - Setup: _local\documentation\project-documentation\setup\" -ForegroundColor White
    Write-Host "  - Deployment: _local\documentation\project-documentation\deployment\" -ForegroundColor White
    Write-Host "  - Reference: _local\documentation\project-documentation\reference\" -ForegroundColor White
    Write-Host "  - Status: _local\documentation\project-documentation\status\" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening documentation folder..." -ForegroundColor Yellow
    
    $docPath = Join-Path $projectRoot "_local\documentation\project-documentation"
    if (Test-Path $docPath) {
        Start-Process explorer.exe -ArgumentList $docPath
    } else {
        Write-Host "Documentation folder not found!" -ForegroundColor Red
    }
}

function Invoke-AllInfrastructureProcesses {
    Write-Host "`n=== Running All Infrastructure Processes ===" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "[1/3] Setting up D1 Database..." -ForegroundColor Yellow
    Initialize-D1Database
    Write-Host ""
    
    Write-Host "[2/3] Deploying Cloudflare Worker..." -ForegroundColor Yellow
    Deploy-Worker
    Write-Host ""
    
    Write-Host "[3/3] Deploying to Cloudflare Pages..." -ForegroundColor Yellow
    Invoke-CloudflareDeploy
    Write-Host ""
    
    Write-Host "✅ All infrastructure processes completed!" -ForegroundColor Green
}

function Invoke-AllProcesses {
    Write-Host "`n=== Launching All Processes ===" -ForegroundColor Green
    Write-Host ""
    
    # Step 1: Run all infrastructure processes first
    Write-Host "Step 1: Setting up infrastructure..." -ForegroundColor Cyan
    Invoke-AllInfrastructureProcesses
    Write-Host ""
    
    # Step 2: Start backend and frontend
    Write-Host "Step 2: Starting services..." -ForegroundColor Cyan
    Start-Backend
    Start-Sleep -Seconds 3
    Start-Frontend
    Start-Sleep -Seconds 1
    Write-Host ""
    
    Write-Host "✅ All processes launched!" -ForegroundColor Green
    Write-Host "   - Flask Backend: http://localhost:5000" -ForegroundColor Yellow
    Write-Host "   - Flutter: http://localhost:58643" -ForegroundColor Yellow
    Write-Host "   - Check logs: _local\logs\" -ForegroundColor Gray
}

function Invoke-AllProcessesWithFixes {
    Write-Host "`n=== Launching All Processes with Fixes ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Step 1: Check and fix issues first
    Write-Host "Step 1: Checking and fixing issues..." -ForegroundColor Yellow
    Test-LoginIssues
    Write-Host ""
    
    # Step 2: Run all infrastructure processes
    Write-Host "Step 2: Setting up infrastructure..." -ForegroundColor Cyan
    Invoke-AllInfrastructureProcesses
    Write-Host ""
    
    # Step 3: Start backend and frontend
    Write-Host "Step 3: Starting services..." -ForegroundColor Cyan
    Start-Backend
    Start-Sleep -Seconds 3
    Start-Frontend
    Start-Sleep -Seconds 1
    Write-Host ""
    
    Write-Host "✅ All processes launched with fixes applied!" -ForegroundColor Green
    Write-Host "   - Flask Backend: http://localhost:5000" -ForegroundColor Yellow
    Write-Host "   - Flutter: http://localhost:58643" -ForegroundColor Yellow
    Write-Host "   - Check logs: _local\logs\" -ForegroundColor Gray
}

function Invoke-QuickDeploy {
    Write-Host "`n=== Quick Deploy (1-Click) ===" -ForegroundColor Magenta
    Write-Host "Building Flutter web and pushing to GitHub → Cloudflare auto-deploys" -ForegroundColor Yellow
    Write-Host ""
    
    Set-Location $projectRoot
    
    # Step 1: Build Flutter web
    Write-Host "[1/3] Building Flutter web app..." -ForegroundColor Cyan
    $flutterDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
    Set-Location $flutterDir
    
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get 2>&1 | Out-Null
    
    Write-Host "   Building web (this may take 1-2 minutes)..." -ForegroundColor Gray
    $buildOutput = flutter build web --release 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Red
        return
    }
    Write-Host "   ✅ Build completed" -ForegroundColor Green
    
    # Step 2: Copy to docs
    Write-Host "`n[2/3] Copying build to docs/..." -ForegroundColor Cyan
    Set-Location $projectRoot
    
    $buildPath = Join-Path $flutterDir "build\web"
    if (-not (Test-Path $buildPath)) {
        Write-Host "❌ Build directory not found: $buildPath" -ForegroundColor Red
        return
    }
    
    $docsPath = Join-Path $projectRoot "docs"
    if (Test-Path $docsPath) {
        Remove-Item -Recurse -Force $docsPath
    }
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
    Copy-Item -Recurse "$buildPath\*" -Destination $docsPath -Force
    Write-Host "   ✅ Build files copied" -ForegroundColor Green
    
    # Step 3: Commit and push
    Write-Host "`n[3/3] Committing and pushing to GitHub..." -ForegroundColor Cyan
    
    if (-not (Test-Path ".git")) {
        Write-Host "❌ Not in a git repository!" -ForegroundColor Red
        return
    }
    
    $env:GIT_EDITOR = "true"
    git add docs 2>&1 | Out-Null
    $stagedFiles = git diff --staged --name-only
    
    if ($stagedFiles) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "Quick deploy: Update Flutter web build ($timestamp)" 2>&1 | Out-Null
        
        Write-Host "   Pushing to GitHub..." -ForegroundColor Gray
        $pushOutput = git push origin main 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Quick deploy completed!" -ForegroundColor Green
            Write-Host "   Cloudflare will auto-deploy in ~60 seconds" -ForegroundColor Yellow
            Write-Host "   Live at: https://ah.saffronbolt.in" -ForegroundColor Cyan
        } else {
            # Handle non-fast-forward error
            if (($pushOutput -match "rejected.*fetch first") -or ($pushOutput -match "Updates were rejected") -or ($pushOutput -match "non-fast-forward")) {
                Write-Host "   ⚠️  Remote has new changes. Pulling and merging..." -ForegroundColor Yellow
                
                # Abort any existing rebase/merge first
                if ((Test-Path ".git/rebase-merge") -or (Test-Path ".git/rebase-apply")) {
                    git rebase --abort 2>&1 | Out-Null
                }
                if (Test-Path ".git/MERGE_HEAD") {
                    git merge --abort 2>&1 | Out-Null
                }
                
                # Pull with merge (not rebase - simpler for docs/ conflicts)
                $pullOutput = git pull origin main --no-edit 2>&1 | Out-String
                
                # Check if merge resulted in conflicts
                if ($pullOutput -match "CONFLICT|conflict") {
                    Write-Host "   Resolving conflicts in docs/ (keeping new build)..." -ForegroundColor Gray
                    # During merge: --ours is our branch (new build), --theirs is remote
                    # We want to keep our new build files
                    $conflictFiles = git diff --name-only --diff-filter=U 2>&1 | Out-String
                    if ($conflictFiles -match "docs/") {
                        git checkout --ours docs/ 2>&1 | Out-Null
                        git add docs/ 2>&1 | Out-Null
                    }
                    # Add all resolved files and complete merge
                    git add -A 2>&1 | Out-Null
                    git commit --no-edit 2>&1 | Out-Null
                }
                
                if ($LASTEXITCODE -eq 0) {
                    
                    # Try push again
                    $pushOutput = git push origin main 2>&1 | Out-String
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "`n✅ Quick deploy completed!" -ForegroundColor Green
                        Write-Host "   Cloudflare will auto-deploy in ~60 seconds" -ForegroundColor Yellow
                        Write-Host "   Live at: https://ah.saffronbolt.in" -ForegroundColor Cyan
                    } else {
                        # Try force-with-lease as last resort
                        if ($pushOutput -match "non-fast-forward") {
                            Write-Host "   ⚠️  Trying force-with-lease as last resort..." -ForegroundColor Yellow
                            $pushOutput = git push origin main --force-with-lease 2>&1 | Out-String
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "`n✅ Quick deploy completed!" -ForegroundColor Green
                                Write-Host "   Cloudflare will auto-deploy in ~60 seconds" -ForegroundColor Yellow
                                Write-Host "   Live at: https://ah.saffronbolt.in" -ForegroundColor Cyan
                            } else {
                                Write-Host "`n❌ Push failed after retry attempts" -ForegroundColor Red
                                Write-Host "   Error: $pushOutput" -ForegroundColor Gray
                                Write-Host "   💡 Try running: git pull origin main --rebase && git push origin main" -ForegroundColor Cyan
                            }
                        } else {
                            Write-Host "`n❌ Push failed after merge" -ForegroundColor Red
                            Write-Host "   Error: $pushOutput" -ForegroundColor Gray
                            Write-Host "   💡 Try running: git pull origin main && git push origin main" -ForegroundColor Cyan
                        }
                    }
                } else {
                    Write-Host "`n❌ Could not pull remote changes" -ForegroundColor Red
                    Write-Host "   Error: $pullOutput" -ForegroundColor Gray
                    Write-Host "   💡 Manual fix: git pull origin main && git push origin main" -ForegroundColor Cyan
                }
            } else {
                Write-Host "`n❌ Push failed. Check git status." -ForegroundColor Red
                Write-Host "   Error: $pushOutput" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "⚠️  No changes to commit. Build output is identical." -ForegroundColor Yellow
    }
}

function Invoke-BackendAndFrontend {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   Sequential Startup with Monitoring   ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Step 1: Start Backend
    Write-Host "[1/3] Starting Flask Backend..." -ForegroundColor Green
    Write-Host "      Port: 5000" -ForegroundColor Gray
    Start-Backend
    
    # Step 2: Wait for Backend Health Check
    Write-Host "`n[2/3] Waiting for backend health check..." -ForegroundColor Yellow
    Write-Host "      Testing: http://localhost:5000/api/health" -ForegroundColor Gray
    Write-Host "      Flask initialization can take 60-90 seconds..." -ForegroundColor DarkGray
    Write-Host "      " -NoNewline
    
    $maxWait = 120  # Increased to 2 minutes for Flask initialization
    $waited = 0
    $backendReady = $false
    
    # Create HttpClient once outside loop to avoid resource leaks and improve performance
    # Use .NET HttpClient instead of Invoke-WebRequest to avoid PowerShell 7.5.4 RemoteException
    $httpClient = New-Object System.Net.Http.HttpClient
    $httpClient.Timeout = [System.TimeSpan]::FromSeconds(2)
    
    try {
        while ($waited -lt $maxWait -and -not $backendReady) {
            Start-Sleep -Seconds 1
            $waited++
            
            try {
                $task = $httpClient.GetAsync("http://localhost:5000/api/health")
                $task.Wait()
                
                if ($task.Result.IsSuccessStatusCode) {
                    $backendReady = $true
                    $content = $task.Result.Content.ReadAsStringAsync().Result
                    try {
                        $data = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
                        Write-Host "`n      ✅ Backend ready! (took $waited seconds)" -ForegroundColor Green
                        if ($data -and $data.status) {
                            Write-Host "      Status: $($data.status)" -ForegroundColor Gray
                        }
                    } catch {
                        Write-Host "`n      ✅ Backend ready! (took $waited seconds)" -ForegroundColor Green
                    }
                    break
                }
            } catch {
                # Ignore all errors (connection refused, timeout, RemoteException, etc.)
                # Show progress every 10 seconds
                if ($waited % 10 -eq 0) {
                    Write-Host "`n      ⏳ Still waiting... ($waited seconds elapsed)" -NoNewline -ForegroundColor DarkGray
                } elseif ($waited % 5 -eq 0) {
                    Write-Host " $waited" -NoNewline -ForegroundColor DarkGray
                } else {
                    Write-Host "." -NoNewline -ForegroundColor DarkGray
                }
            }
        }
    } finally {
        # Always dispose HttpClient to prevent resource leaks
        if ($httpClient) {
            $httpClient.Dispose()
        }
    }
    
    if (-not $backendReady) {
        Write-Host "`n      ⚠️  Backend didn't respond after $maxWait seconds" -ForegroundColor Yellow
        Write-Host "      This is unusual - Flask should start within 2 minutes" -ForegroundColor Yellow
        Write-Host "      Check backend log: _local\logs\backend.log" -ForegroundColor Gray
        Write-Host "      Or restore minimized backend window to see errors" -ForegroundColor Gray
        Write-Host "      Continuing with frontend startup anyway..." -ForegroundColor Gray
    }
    
    # Step 3: Start Frontend
    Write-Host "`n[3/3] Starting Flutter Web App..." -ForegroundColor Green
    Write-Host "      Port: 58643" -ForegroundColor Gray
    Start-Frontend
    
    # Give Flutter time to start compiling
    Write-Host "`n      ⏳ Flutter is compiling... (first build takes 2-3 minutes)" -ForegroundColor Yellow
    Write-Host "      Compilation progress:" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    # Check if Flutter is compiling
    $buildDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\build\web"
    $maxCompileWait = 180  # 3 minutes for compilation
    $compileWaited = 10
    
    while ($compileWaited -lt $maxCompileWait) {
        if (Test-Path (Join-Path $buildDir "main.dart.js")) {
            Write-Host "      ✅ Flutter compiled successfully! (took $compileWaited seconds)" -ForegroundColor Green
            break
        }
        
        Start-Sleep -Seconds 15
        $compileWaited += 15
        Write-Host "      ⏳ Still compiling... ($compileWaited seconds elapsed)" -ForegroundColor DarkGray
    }
    
    if (-not (Test-Path (Join-Path $buildDir "main.dart.js"))) {
        Write-Host "      ⚠️  Flutter compilation taking longer than expected" -ForegroundColor Yellow
        Write-Host "      Restore Flutter window from taskbar to see progress" -ForegroundColor Gray
    }
    
    # Summary
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          Startup Complete!             ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "📡 URLs:" -ForegroundColor Yellow
    Write-Host "   Backend:  http://localhost:5000" -ForegroundColor White
    Write-Host "   Frontend: http://localhost:58643" -ForegroundColor White
    Write-Host "   Admin:    http://localhost:58643/#/admin" -ForegroundColor Cyan
    
    Write-Host "`n📋 Logs:" -ForegroundColor Yellow
    Write-Host "   Backend:  _local\logs\backend.log" -ForegroundColor Gray
    Write-Host "   Flutter:  _local\logs\flutter.log" -ForegroundColor Gray
    
    Write-Host "`n💡 Notes:" -ForegroundColor Yellow
    Write-Host "   - Windows minimized - check taskbar to restore" -ForegroundColor Gray
    Write-Host "   - Flask initialization: ~60-90 seconds" -ForegroundColor Gray
    Write-Host "   - Flutter first compilation: ~2-3 minutes" -ForegroundColor Gray
    Write-Host "   - Refresh browser if page is blank after compilation" -ForegroundColor Gray
    
    Write-Host "`n⚙️  To stop services:" -ForegroundColor Yellow
    Write-Host "   Use Task Manager or: Get-Process python,dart | Stop-Process" -ForegroundColor Gray
    Write-Host ""
}

function Stop-AllServices {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        Stopping All Services           ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "🛑 Stopping Flask Backend..." -ForegroundColor Yellow
    $pythonProcs = Get-Process python -ErrorAction SilentlyContinue
    if ($pythonProcs) {
        $pythonProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "   ✅ Backend stopped ($($pythonProcs.Count) process(es))" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  No backend processes found" -ForegroundColor Gray
    }
    
    Write-Host "`n🛑 Stopping Flutter..." -ForegroundColor Yellow
    $dartProcs = Get-Process dart,flutter -ErrorAction SilentlyContinue
    if ($dartProcs) {
        $dartProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "   ✅ Flutter stopped ($($dartProcs.Count) process(es))" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  No Flutter processes found" -ForegroundColor Gray
    }
    
    Write-Host "`n🧹 Cleaning up background jobs..." -ForegroundColor Yellow
    $jobs = Get-Job -ErrorAction SilentlyContinue
    if ($jobs) {
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
        Write-Host "   ✅ Jobs cleaned up ($($jobs.Count) job(s))" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  No background jobs found" -ForegroundColor Gray
    }
    
    Write-Host "`n✅ All services stopped!" -ForegroundColor Green
    Write-Host ""
}

function Start-Automated {
    Write-Host "Starting automated system..." -ForegroundColor Green
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Run database migration" -ForegroundColor Gray
    Write-Host "  2. Start backend in silent mode" -ForegroundColor Gray
    Write-Host "  3. Start frontend in silent mode" -ForegroundColor Gray
    Write-Host "  4. Verify services are running" -ForegroundColor Gray
    Write-Host "  5. Optionally start auto-deploy" -ForegroundColor Gray
    Write-Host ""
    
    Set-Location $projectRoot
    $autoStartScript = Join-Path $projectRoot "scripts\auto_start.ps1"
    if (Test-Path $autoStartScript) {
        & $autoStartScript
    } else {
        Write-Host "Auto-start script not found!" -ForegroundColor Red
    }
}

# Main menu loop
do {
    # Ensure we're in project root
    Set-Location $projectRoot -ErrorAction SilentlyContinue
    
    Show-Menu
    # Get user choice (trim to handle any whitespace issues)
    $choice = (Read-Host "Enter your choice (1-6)").Trim()
    
    switch ($choice) {
        "1" {
            Set-Location $projectRoot
            Invoke-AllProcesses
            Write-Host "`nPress any key to return to menu..."
            $null = Read-Host
        }
        "2" {
            Set-Location $projectRoot
            Invoke-AllProcessesWithFixes
            Write-Host "`nPress any key to return to menu..."
            $null = Read-Host
        }
        "3" {
            Set-Location $projectRoot
            Invoke-QuickDeploy
            Write-Host "`nPress any key to return to menu..."
            $null = Read-Host
        }
        "4" {
            Set-Location $projectRoot
            Invoke-BackendAndFrontend
            Write-Host "`nPress any key to return to menu..."
            $null = Read-Host
        }
        "5" {
            Set-Location $projectRoot
            Stop-AllServices
            Write-Host "`nPress any key to return to menu..."
            $null = Read-Host
        }
        "6" {
            Write-Host "`nExiting..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "`nInvalid choice. Please select 1-6." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)

