# Install Wrangler CLI for Cloudflare Workers
# This script installs Wrangler and verifies the installation

$ErrorActionPreference = "Continue"

Write-Host "=== Installing Wrangler CLI ===" -ForegroundColor Cyan
Write-Host ""

# Check if npm is available
try {
    $npmVersion = npm --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green
    } else {
        throw "npm not found"
    }
} catch {
    Write-Host "❌ npm not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js first:" -ForegroundColor Yellow
    Write-Host "  Download from: https://nodejs.org/" -ForegroundColor Cyan
    Write-Host "  Or use: winget install OpenJS.NodeJS" -ForegroundColor Cyan
    exit 1
}

# Check if wrangler is already installed
try {
    $wranglerVersion = wrangler --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Wrangler is already installed: $wranglerVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now run:" -ForegroundColor Cyan
        Write-Host "  .\scripts\setup_d1_database.ps1" -ForegroundColor Yellow
        exit 0
    }
} catch {
    Write-Host "Wrangler not found, installing..." -ForegroundColor Yellow
}

# Install wrangler globally
Write-Host "Installing Wrangler globally..." -ForegroundColor Yellow
Write-Host "This may take a minute..." -ForegroundColor Gray
Write-Host ""

npm install -g wrangler 2>&1 | ForEach-Object {
    Write-Host $_ -ForegroundColor Gray
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Wrangler installed successfully!" -ForegroundColor Green
    
    # Verify installation
    Write-Host ""
    Write-Host "Verifying installation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2  # Give npm time to update PATH
    
    try {
        $wranglerVersion = wrangler --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Wrangler verified: $wranglerVersion" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Wrangler installed but not in PATH yet" -ForegroundColor Yellow
            Write-Host "   You may need to restart your terminal or run:" -ForegroundColor Gray
            Write-Host "   refreshenv" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "⚠️  Could not verify Wrangler (may need to restart terminal)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. If wrangler command doesn't work, restart your terminal" -ForegroundColor White
    Write-Host "  2. Run: .\scripts\setup_d1_database.ps1" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try installing manually:" -ForegroundColor Yellow
    Write-Host "  npm install -g wrangler" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or install locally in worker directory:" -ForegroundColor Yellow
    Write-Host "  cd worker" -ForegroundColor Cyan
    Write-Host "  npm install" -ForegroundColor Cyan
    exit 1
}
