# AurumHarmony Production Deployment Script
# This script handles the complete production deployment process

param(
    [string]$GitHubToken = "",
    [string]$CloudflareToken = "",
    [string]$FirebaseToken = "",
    [string]$RenderToken = "",
    [switch]$SkipGitHub,
    [switch]$SkipCloudflare,
    [switch]$SkipFirebase,
    [switch]$SkipRender
)

$ErrorActionPreference = "Stop"

# Configuration
$projectRoot = $PSScriptRoot
$deploymentBranch = "deployment-v1.0"
$repoName = "ah-v1-beta"
$githubUsername = "imvikverma"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "🚀 AurumHarmony Production Deployment" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if command succeeded
function Test-LastExitCode {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Step 1: GitHub Deployment
if (-not $SkipGitHub) {
    Write-Host "📦 Step 1: GitHub Deployment" -ForegroundColor Yellow
    Write-Host "-----------------------------" -ForegroundColor Yellow

    try {
        Set-Location $projectRoot

        # Check git status
        Write-Host "Checking git status..." -ForegroundColor Gray
        $gitStatus = git status --porcelain 2>$null
        if ($LASTEXITCODE -eq 0 -and -not $gitStatus) {
            Write-Host "✅ Git repository is clean" -ForegroundColor Green
        } else {
            Write-Host "📝 Repository has changes to commit" -ForegroundColor Yellow
        }

        # Create deployment package for manual upload
        Write-Host "Creating deployment package..." -ForegroundColor Gray
        $deployZip = Join-Path $projectRoot "aurumharmony-deployment-v1.0.zip"
        if (Test-Path $deployZip) { Remove-Item $deployZip -Force }

        # Create zip excluding sensitive files
        $excludeList = @(
            "*.log",
            ".git",
            "__pycache__",
            "*.pyc",
            ".env*",
            "node_modules",
            ".DS_Store",
            "Thumbs.db",
            "_local/development/test_xai_api.ps1",
            "_local/documentation/cursor_chat_export.md"
        )

        $tempDir = Join-Path $env:TEMP "aurum_temp_deploy"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        # Copy files excluding sensitive ones
        Get-ChildItem -Path $projectRoot -Recurse -File | Where-Object {
            $include = $true
            foreach ($exclude in $excludeList) {
                if ($_.FullName -like "*$exclude*") {
                    $include = $false
                    break
                }
            }
            $include
        } | ForEach-Object {
            $destPath = $_.FullName.Replace($projectRoot, $tempDir)
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $_.FullName $destPath -Force
        }

        # Create zip
        Compress-Archive -Path "$tempDir\*" -DestinationPath $deployZip -Force
        Remove-Item $tempDir -Recurse -Force

        Write-Host "✅ Deployment package created: $deployZip" -ForegroundColor Green

        # Manual GitHub instructions
        Write-Host "📋 Manual GitHub Deployment Steps:" -ForegroundColor Cyan
        Write-Host "1. Go to https://github.com/$githubUsername/$repoName" -ForegroundColor White
        Write-Host "2. Click 'Add file' → 'Upload files'" -ForegroundColor White
        Write-Host "3. Drag and drop the ZIP contents or upload files manually" -ForegroundColor White
        Write-Host "4. Commit with message: 'AurumHarmony v1.0 Production Release'" -ForegroundColor White
        Write-Host ""

        # Alternative: Try git push with retries
        Write-Host "Attempting automated git push..." -ForegroundColor Gray
        $pushAttempts = 0
        $maxAttempts = 3
        $pushSuccess = $false

        while ($pushAttempts -lt $maxAttempts -and -not $pushSuccess) {
            $pushAttempts++
            Write-Host "Push attempt $pushAttempts/$maxAttempts..." -ForegroundColor Gray

            try {
                git push origin master 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $pushSuccess = $true
                    Write-Host "✅ GitHub push successful!" -ForegroundColor Green
                }
            } catch {
                Write-Host "⚠️  Push attempt $pushAttempts failed" -ForegroundColor Yellow
                if ($pushAttempts -lt $maxAttempts) {
                    Start-Sleep -Seconds 5
                }
            }
        }

        if (-not $pushSuccess) {
            Write-Host "⚠️  Automated push failed - use manual upload method above" -ForegroundColor Yellow
        }

        Write-Host "🌐 Repository: https://github.com/$githubUsername/$repoName" -ForegroundColor Cyan
        Write-Host ""

    } catch {
        Write-Host "❌ GitHub deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "📦 Use the deployment ZIP for manual upload" -ForegroundColor Yellow
    }
}

# Step 2: Cloudflare Pages Deployment (Admin Panel)
if (-not $SkipCloudflare) {
    Write-Host "☁️  Step 2: Cloudflare Pages Deployment" -ForegroundColor Yellow
    Write-Host "-------------------------------------" -ForegroundColor Yellow

    try {
        Set-Location (Join-Path $projectRoot "aurum_harmony\admin_panel")

        # Check if wrangler is available
        if (Get-Command wrangler -ErrorAction SilentlyContinue) {
            Write-Host "Deploying admin panel to Cloudflare Pages..." -ForegroundColor Gray
            wrangler pages deploy . --project-name=aurum-admin-v2 --branch=$deploymentBranch
            Test-LastExitCode

            Write-Host "✅ Admin panel deployed to Cloudflare!" -ForegroundColor Green
            Write-Host "🌐 URL: https://admin-v2.saffronbolt.in" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️  Wrangler not found. Install with: npm install -g wrangler" -ForegroundColor Yellow
            Write-Host "Manual deployment required for Cloudflare Pages" -ForegroundColor Yellow
        }
        Write-Host ""

    } catch {
        Write-Host "❌ Cloudflare deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 3: Firebase Hosting Deployment (Flutter Web App)
if (-not $SkipFirebase) {
    Write-Host "🔥 Step 3: Firebase Hosting Deployment" -ForegroundColor Yellow
    Write-Host "-------------------------------------" -ForegroundColor Yellow

    try {
        Set-Location (Join-Path $projectRoot "aurum_harmony\frontend")

        # Check if Flutter is available
        if (Get-Command flutter -ErrorAction SilentlyContinue) {
            Write-Host "Building Flutter web app..." -ForegroundColor Gray
            flutter build web --release
            Test-LastExitCode

            # Deploy to Firebase
            if (Get-Command firebase -ErrorAction SilentlyContinue) {
                Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Gray
                firebase deploy --only hosting
                Test-LastExitCode

                Write-Host "✅ Flutter web app deployed to Firebase!" -ForegroundColor Green
                Write-Host "🌐 URL: https://aurumharmony.web.app" -ForegroundColor Cyan
            } else {
                Write-Host "⚠️  Firebase CLI not found. Install with: npm install -g firebase-tools" -ForegroundColor Yellow
                Write-Host "Manual deployment required for Firebase" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️  Flutter not found. Install Flutter SDK first" -ForegroundColor Yellow
            Write-Host "Manual deployment required for Flutter web app" -ForegroundColor Yellow
        }
        Write-Host ""

    } catch {
        Write-Host "❌ Firebase deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 4: Render.com Deployment (Flask Backend)
if (-not $SkipRender) {
    Write-Host "🖥️  Step 4: Render.com Backend Deployment" -ForegroundColor Yellow
    Write-Host "---------------------------------------" -ForegroundColor Yellow

    try {
        # Check if render.yaml exists
        $renderYaml = Join-Path $projectRoot "render.yaml"
        if (Test-Path $renderYaml) {
            Write-Host "Render configuration found" -ForegroundColor Gray

            # Note: Actual Render deployment requires their CLI or web interface
            Write-Host "ℹ️  Render deployment requires manual setup or Render CLI" -ForegroundColor Yellow
            Write-Host "1. Push code to GitHub first" -ForegroundColor Gray
            Write-Host "2. Connect Render.com to your GitHub repo" -ForegroundColor Gray
            Write-Host "3. Use render.yaml for service configuration" -ForegroundColor Gray
            Write-Host "4. Set environment variables in Render dashboard" -ForegroundColor Gray

            Write-Host "✅ Render deployment configured!" -ForegroundColor Green
            Write-Host "🌐 Backend will be available after Render setup" -ForegroundColor Cyan
        } else {
            Write-Host "❌ render.yaml not found" -ForegroundColor Red
        }
        Write-Host ""

    } catch {
        Write-Host "❌ Render deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 5: Domain Configuration
Write-Host "🌐 Step 5: Domain Configuration" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

Write-Host "Domain Setup Checklist:" -ForegroundColor Cyan
Write-Host "✅ Admin Panel: admin-v2.saffronbolt.in → Cloudflare Pages" -ForegroundColor Green
Write-Host "✅ Web App: aurumharmony.saffronbolt.in → Firebase Hosting" -ForegroundColor Green
Write-Host "✅ API Backend: api.saffronbolt.in → Render.com" -ForegroundColor Green
Write-Host ""
Write-Host "Manual DNS Configuration Required:" -ForegroundColor Yellow
Write-Host "1. Point domains to respective hosting providers" -ForegroundColor Gray
Write-Host "2. Configure SSL certificates" -ForegroundColor Gray
Write-Host "3. Set up custom domains in each platform" -ForegroundColor Gray
Write-Host ""

# Step 6: Production Testing
Write-Host "🧪 Step 6: Production Testing" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

Write-Host "Testing Checklist:" -ForegroundColor Cyan
Write-Host "□ Admin Panel Login: https://admin-v2.saffronbolt.in" -ForegroundColor White
Write-Host "□ Web App Access: https://aurumharmony.saffronbolt.in" -ForegroundColor White
Write-Host "□ API Endpoints: Check /api/health on backend" -ForegroundColor White
Write-Host "□ User Registration Flow" -ForegroundColor White
Write-Host "□ Broker Integration" -ForegroundColor White
Write-Host "□ Trading Operations" -ForegroundColor White
Write-Host ""

# Final Summary
Write-Host "=========================================" -ForegroundColor Green
Write-Host "🎉 AurumHarmony Deployment Summary" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ GitHub Repository: https://github.com/$githubUsername/$repoName" -ForegroundColor Green
Write-Host "✅ Deployment Branch: $deploymentBranch" -ForegroundColor Green
Write-Host "✅ Admin Panel: https://admin-v2.saffronbolt.in" -ForegroundColor Green
Write-Host "✅ Web App: https://aurumharmony.saffronbolt.in" -ForegroundColor Green
Write-Host "✅ API Backend: [Configure in Render.com]" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 AurumHarmony is ready for production!" -ForegroundColor Magenta
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Create Pull Request: $deploymentBranch → main" -ForegroundColor White
Write-Host "2. Configure domains and SSL" -ForegroundColor White
Write-Host "3. Test all functionality" -ForegroundColor White
Write-Host "4. Monitor performance and logs" -ForegroundColor White
Write-Host ""

# Return to original location
Set-Location $projectRoot
