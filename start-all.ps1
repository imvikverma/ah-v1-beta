# AurumHarmony - Master Launcher Menu
# Double-click this file or run: .\start-all.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

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
    Write-Host "  1. Start Backend (Flask)" -ForegroundColor Cyan
    Write-Host "  2. Start Frontend (Flutter Web)" -ForegroundColor Cyan
    Write-Host "  3. Start Both (Backend + Frontend)" -ForegroundColor Cyan
    Write-Host "  4. Rebuild Flutter (Clean Build)" -ForegroundColor Magenta
    Write-Host "  5. Deploy to Cloudflare Pages" -ForegroundColor Magenta
    Write-Host "  6. View Documentation" -ForegroundColor Gray
    Write-Host "  7. Exit" -ForegroundColor Gray
    Write-Host ""
}

function Start-Backend {
    Write-Host "Starting Flask Backend..." -ForegroundColor Green
    Write-Host "Main app: http://localhost:5000" -ForegroundColor Yellow
    Write-Host "Admin panel: http://localhost:5001" -ForegroundColor Yellow
    Write-Host ""
    
    $backendScript = Join-Path $projectRoot "start_backend.ps1"
    if (Test-Path $backendScript) {
        Start-Process powershell -ArgumentList "-NoExit", "-File", "`"$backendScript`""
    } else {
        Write-Host "Backend script not found!" -ForegroundColor Red
    }
}

function Start-Frontend {
    Write-Host "Starting Flutter Web App..." -ForegroundColor Green
    Write-Host ""
    
    $flutterScript = Join-Path $projectRoot "start_flutter.ps1"
    if (Test-Path $flutterScript) {
        Start-Process powershell -ArgumentList "-NoExit", "-File", "`"$flutterScript`""
    } else {
        Write-Host "Flutter script not found!" -ForegroundColor Red
    }
}

function Rebuild-Flutter {
    Write-Host "Rebuilding Flutter Web App (Clean Build)..." -ForegroundColor Magenta
    Write-Host ""
    
    $flutterDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
    if (Test-Path $flutterDir) {
        Set-Location $flutterDir
        Write-Host "[1/3] Cleaning Flutter build..." -ForegroundColor Cyan
        flutter clean
        
        Write-Host "`n[2/3] Getting dependencies..." -ForegroundColor Cyan
        flutter pub get
        
        Write-Host "`n[3/3] Building Flutter web..." -ForegroundColor Cyan
        flutter build web --release
        
        Write-Host "`n✅ Build complete!" -ForegroundColor Green
        Write-Host "Build output: $flutterDir\build\web" -ForegroundColor Gray
        
        Set-Location $projectRoot
    } else {
        Write-Host "Flutter app directory not found!" -ForegroundColor Red
    }
}

function Deploy-Cloudflare {
    Write-Host "Deploying to Cloudflare Pages..." -ForegroundColor Magenta
    Write-Host "This will build Flutter web and push to GitHub." -ForegroundColor Yellow
    Write-Host "Commit message will be auto-generated from CHANGELOG.md" -ForegroundColor Gray
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
        flutter clean
        flutter pub get
        flutter build web --release
        
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

function Show-Documentation {
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  - Setup: documentation\setup\" -ForegroundColor White
    Write-Host "  - Deployment: documentation\deployment\" -ForegroundColor White
    Write-Host "  - Reference: documentation\reference\" -ForegroundColor White
    Write-Host "  - Status: documentation\status\" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening documentation folder..." -ForegroundColor Yellow
    
    $docPath = Join-Path $projectRoot "documentation"
    if (Test-Path $docPath) {
        Start-Process explorer.exe -ArgumentList $docPath
    } else {
        Write-Host "Documentation folder not found!" -ForegroundColor Red
    }
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-7)"
    
    switch ($choice) {
        "1" {
            Start-Backend
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "2" {
            Start-Frontend
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "3" {
            Write-Host "`nStarting both services..." -ForegroundColor Green
            Start-Backend
            Start-Sleep -Seconds 2
            Start-Frontend
            Write-Host "`n✅ Both services started!" -ForegroundColor Green
            Write-Host "   - Flask Backend: http://localhost:5000" -ForegroundColor Yellow
            Write-Host "   - Flutter: Check the Flutter window for URL" -ForegroundColor Yellow
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "4" {
            Rebuild-Flutter
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "5" {
            Publish-Cloudflare
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "6" {
            Show-Documentation
            Write-Host "`nPress any key to return to menu..."
            Read-Host
        }
        "7" {
            Write-Host "`nExiting..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "`nInvalid choice. Please select 1-7." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)

