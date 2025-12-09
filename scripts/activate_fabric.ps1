# Complete Hyperledger Fabric Activation Script
# This script orchestrates the full Fabric network setup

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot + "\.."
Set-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hyperledger Fabric Activation" -ForegroundColor Cyan
Write-Host "  AurumHarmony Blockchain Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Docker
Write-Host "Step 1: Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "  ✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Docker is not installed" -ForegroundColor Red
    Write-Host "    Please install Docker Desktop first" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
$dockerReady = $false
Write-Host "  Checking if Docker Desktop is running..." -ForegroundColor Gray
for ($i = 1; $i -le 30; $i++) {
    try {
        docker ps | Out-Null
        $dockerReady = $true
        Write-Host "  ✓ Docker Desktop is running" -ForegroundColor Green
        break
    } catch {
        if ($i -eq 1) {
            Write-Host "  ⏳ Waiting for Docker Desktop to start..." -ForegroundColor Yellow
        }
        Start-Sleep -Seconds 2
    }
}

if (-not $dockerReady) {
    Write-Host "  ✗ Docker Desktop is not running" -ForegroundColor Red
    Write-Host "    Please start Docker Desktop and try again" -ForegroundColor Yellow
    Write-Host "    Or run: Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" -ForegroundColor Gray
    exit 1
}

# Step 2: Add Fabric config to .env
Write-Host ""
Write-Host "Step 2: Configuring .env file..." -ForegroundColor Yellow
& "$PSScriptRoot\setup\add_fabric_config.ps1"

# Step 3: Setup Fabric network
Write-Host ""
Write-Host "Step 3: Setting up Fabric network..." -ForegroundColor Yellow
Set-Location "$projectRoot\fabric"
& ".\setup_fabric.ps1" -StartNetwork

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Fabric setup failed" -ForegroundColor Red
    exit 1
}

# Step 4: Create channel
Write-Host ""
Write-Host "Step 4: Creating channel..." -ForegroundColor Yellow
& ".\create_channel.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Channel creation failed" -ForegroundColor Red
    Write-Host "    You may need to wait a bit longer for the network to be ready" -ForegroundColor Yellow
    Write-Host "    Try running: .\create_channel.ps1 manually" -ForegroundColor Gray
}

# Step 5: Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Fabric Activation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy chaincode (when ready):" -ForegroundColor White
Write-Host "     cd fabric" -ForegroundColor Gray
Write-Host "     .\deploy_chaincode.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Start the gateway service:" -ForegroundColor White
Write-Host "     cd fabric\gateway" -ForegroundColor Gray
Write-Host "     python fabric_gateway.py" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Verify setup:" -ForegroundColor White
Write-Host "     docker-compose -f fabric\docker-compose.yaml ps" -ForegroundColor Gray
Write-Host "     curl http://localhost:8080/health" -ForegroundColor Gray
Write-Host ""
Write-Host "The FabricClient in your Python code will now make HTTP calls" -ForegroundColor Gray
Write-Host "to the gateway instead of NO-OP stubs!" -ForegroundColor Gray
Write-Host ""

Set-Location $projectRoot

