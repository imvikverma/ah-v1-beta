# AurumHarmony Master Launcher
# Quick access menu for all services
#
# NOTE: This script shows a menu - it does NOT automatically start services.
# Safe to run even when Flask, Ngrok, or Flutter are already running.
# Services will only start if you choose options 1-5.
#
# For clarity when services are running, you can also use: .\menu-only.ps1

# Get project root directory (parent of zzz-quick-access)
$projectRoot = Split-Path -Parent $PSScriptRoot

# Function to show the menu
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   AurumHarmony Service Launcher       " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select a service to start:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Flask Backend (port 5000)" -ForegroundColor White
    Write-Host "  2. Ngrok Tunnel" -ForegroundColor White
    Write-Host "  3. Flask Backend + Ngrok (both)" -ForegroundColor White
    Write-Host "  4. Flutter Dev Server" -ForegroundColor White
    Write-Host "  5. Flask Backend + Ngrok + Flutter (all three)" -ForegroundColor Cyan
    Write-Host "  6. Deploy to Cloudflare Pages" -ForegroundColor Magenta
    Write-Host "  7. Update Changelog" -ForegroundColor Cyan
    Write-Host "  8. Regenerate README" -ForegroundColor Cyan
    Write-Host "  9. Test HDFC Sky Credentials" -ForegroundColor White
    Write-Host "  10. Test Kotak Neo Credentials" -ForegroundColor White
    Write-Host "  11. Exit" -ForegroundColor White
    Write-Host ""
}

# Function to verify script exists
function Test-ScriptPath {
    param([string]$ScriptPath)
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "`n❌ ERROR: Script not found: $ScriptPath" -ForegroundColor Red
        Write-Host "   Project root: $projectRoot" -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Main loop
$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-11)"
    
    switch ($choice) {
        "1" {
            Write-Host "`nStarting Flask Backend..." -ForegroundColor Green
            $scriptPath = Join-Path $projectRoot "scripts\start_backend.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            } else {
                Write-Host "`nPress any key to continue..."
                Read-Host
            }
        }
        "2" {
            Write-Host "`nStarting Ngrok Tunnel..." -ForegroundColor Green
            $scriptPath = Join-Path $projectRoot "scripts\start_ngrok.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            } else {
                Write-Host "`nPress any key to continue..."
                Read-Host
            }
        }
        "3" {
            Write-Host "`nStarting Flask Backend + Ngrok..." -ForegroundColor Green
            $backendScript = Join-Path $projectRoot "scripts\start_backend.ps1"
            $ngrokScript = Join-Path $projectRoot "scripts\start_ngrok.ps1"
            if (Test-ScriptPath $backendScript) {
                Start-Process powershell -ArgumentList @(
                    "-NoExit",
                    "-Command",
                    "cd '$projectRoot'; & '$backendScript'"
                )
                Start-Sleep -Seconds 3
                if (Test-ScriptPath $ngrokScript) {
                    Set-Location $projectRoot
                    & $ngrokScript
                }
            } else {
                Write-Host "`nPress any key to continue..."
                Read-Host
            }
        }
        "4" {
            Write-Host "`nStarting Flutter Dev Server..." -ForegroundColor Green
            $scriptPath = Join-Path $projectRoot "scripts\start_flutter.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            } else {
                Write-Host "`nPress any key to continue..."
                Read-Host
            }
        }
        "5" {
            Write-Host "`nStarting ALL services (Backend + Ngrok + Flutter)..." -ForegroundColor Cyan
            Write-Host "This will open 3 separate windows." -ForegroundColor Yellow
            Write-Host ""
            
            $backendScript = Join-Path $projectRoot "scripts\start_backend.ps1"
            $ngrokScript = Join-Path $projectRoot "scripts\start_ngrok.ps1"
            $flutterScript = Join-Path $projectRoot "scripts\start_flutter.ps1"
            
            $allExist = $true
            if (-not (Test-ScriptPath $backendScript)) { $allExist = $false }
            if (-not (Test-ScriptPath $ngrokScript)) { $allExist = $false }
            if (-not (Test-ScriptPath $flutterScript)) { $allExist = $false }
            
            if ($allExist) {
                # Start Flask Backend in new window
                Write-Host "Starting Flask Backend..." -ForegroundColor Green
                Start-Process powershell -ArgumentList @(
                    "-NoExit",
                    "-Command",
                    "cd '$projectRoot'; & '$backendScript'"
                )
                
                # Wait for backend to start
                Start-Sleep -Seconds 3
                
                # Start Ngrok in new window
                Write-Host "Starting Ngrok Tunnel..." -ForegroundColor Green
                Start-Process powershell -ArgumentList @(
                    "-NoExit",
                    "-Command",
                    "cd '$projectRoot'; & '$ngrokScript'"
                )
                
                # Wait a moment
                Start-Sleep -Seconds 2
                
                # Start Flutter in new window
                Write-Host "Starting Flutter Dev Server..." -ForegroundColor Green
                Start-Process powershell -ArgumentList @(
                    "-NoExit",
                    "-Command",
                    "cd '$projectRoot'; & '$flutterScript'"
                )
                
                Write-Host "`n✅ All services started!" -ForegroundColor Green
                Write-Host "   - Flask Backend: http://localhost:5000" -ForegroundColor Yellow
                Write-Host "   - Admin Panel: http://localhost:5001" -ForegroundColor Yellow
                Write-Host "   - Ngrok: Check the ngrok window for URL" -ForegroundColor Yellow
                Write-Host "   - Flutter: Check the Flutter window for URL" -ForegroundColor Yellow
                Write-Host "`nPress any key to exit this launcher..."
                Read-Host
            } else {
                Write-Host "`nPress any key to continue..."
                Read-Host
            }
        }
        "6" {
            Write-Host "`nDeploying to Cloudflare Pages..." -ForegroundColor Magenta
            Write-Host "This will build Flutter web and push to GitHub." -ForegroundColor Yellow
            Write-Host "Commit message will be auto-generated from CHANGELOG.md" -ForegroundColor Gray
            Write-Host ""
            # Change to project root and run deploy script
            $scriptPath = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            }
            Write-Host "`nPress any key to continue..."
            Read-Host
        }
        "7" {
            Write-Host "`nUpdating Changelog..." -ForegroundColor Cyan
            $scriptPath = Join-Path $projectRoot "scripts\update-changelog.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            }
            Write-Host "`nPress any key to continue..."
            Read-Host
        }
        "8" {
            Write-Host "`nRegenerating README..." -ForegroundColor Cyan
            $scriptPath = Join-Path $projectRoot "scripts\generate-readme.ps1"
            if (Test-ScriptPath $scriptPath) {
                Set-Location $projectRoot
                & $scriptPath
            }
            Write-Host "`nPress any key to continue..."
            Read-Host
        }
        "9" {
            Write-Host "`nTesting HDFC Sky Credentials..." -ForegroundColor Green
            $scriptPath = Join-Path $projectRoot "scripts\tests\test_hdfc_credentials.py"
            if (Test-Path $scriptPath) {
                Set-Location $projectRoot
                python $scriptPath
            } else {
                Write-Host "`n❌ ERROR: Script not found: $scriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress any key to continue..."
            Read-Host
        }
        "10" {
            Write-Host "`nTesting Kotak Neo Credentials..." -ForegroundColor Green
            $scriptPath = Join-Path $projectRoot "config\get_kotak_token.py"
            if (Test-Path $scriptPath) {
                Set-Location $projectRoot
                python $scriptPath
            } else {
                Write-Host "`n❌ ERROR: Script not found: $scriptPath" -ForegroundColor Red
            }
            Write-Host "`nPress any key to continue..."
            Read-Host
        }
        "11" {
            Write-Host "`nExiting..." -ForegroundColor Gray
            $running = $false
            break
        }
        default {
            Write-Host "`nInvalid choice. Please select 1-11." -ForegroundColor Red
            Write-Host "Press any key to continue..."
            Read-Host
        }
    }
}
