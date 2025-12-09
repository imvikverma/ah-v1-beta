# Hyperledger Fabric Network Setup Script for AurumHarmony
# This script sets up a complete Fabric network with crypto material generation

param(
    [switch]$SkipCrypto = $false,
    [switch]$StartNetwork = $true
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hyperledger Fabric Setup" -ForegroundColor Cyan
Write-Host "  AurumHarmony Blockchain Network" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not running" -ForegroundColor Red
    Write-Host "  Please install Docker Desktop and ensure it's running" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
try {
    docker ps | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Desktop is not running" -ForegroundColor Red
    Write-Host "  Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}

# Check for cryptogen and configtxgen
$hasCryptogen = $false
$hasConfigtxgen = $false

if (Get-Command cryptogen -ErrorAction SilentlyContinue) {
    $hasCryptogen = $true
    Write-Host "✓ cryptogen found" -ForegroundColor Green
} else {
    Write-Host "⚠ cryptogen not found in PATH" -ForegroundColor Yellow
    Write-Host "  Will use Docker-based generation" -ForegroundColor Gray
}

if (Get-Command configtxgen -ErrorAction SilentlyContinue) {
    $hasConfigtxgen = $true
    Write-Host "✓ configtxgen found" -ForegroundColor Green
} else {
    Write-Host "⚠ configtxgen not found in PATH" -ForegroundColor Yellow
    Write-Host "  Will use Docker-based generation" -ForegroundColor Gray
}

# Generate crypto material
if (-not $SkipCrypto) {
    Write-Host ""
    Write-Host "Generating crypto material..." -ForegroundColor Yellow
    
    if ($hasCryptogen) {
        if (Test-Path "crypto-config") {
            Write-Host "  Removing existing crypto-config..." -ForegroundColor Gray
            Remove-Item -Recurse -Force crypto-config
        }
        cryptogen generate --config=./crypto-config.yaml --output=./crypto-config
        Write-Host "✓ Crypto material generated" -ForegroundColor Green
    } else {
        Write-Host "  Using Docker to generate crypto material..." -ForegroundColor Gray
        docker run --rm -v "${PWD}:/work" -w /work hyperledger/fabric-tools:2.5 cryptogen generate --config=./crypto-config.yaml --output=./crypto-config
        Write-Host "✓ Crypto material generated via Docker" -ForegroundColor Green
    }
} else {
    Write-Host "Skipping crypto material generation (using existing)" -ForegroundColor Gray
}

# Generate genesis block
Write-Host ""
Write-Host "Generating genesis block..." -ForegroundColor Yellow

if (-not (Test-Path "config")) {
    New-Item -ItemType Directory -Path "config" | Out-Null
}

if ($hasConfigtxgen) {
    configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./config/orderer.genesis.block -configPath .
    Write-Host "✓ Genesis block generated" -ForegroundColor Green
} else {
    Write-Host "  Using Docker to generate genesis block..." -ForegroundColor Gray
    docker run --rm -v "${PWD}:/work" -w /work -e FABRIC_CFG_PATH=/work hyperledger/fabric-tools:2.5 configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./config/orderer.genesis.block -configPath /work
    Write-Host "✓ Genesis block generated via Docker" -ForegroundColor Green
}

# Generate channel configuration
Write-Host ""
Write-Host "Generating channel configuration..." -ForegroundColor Yellow

if ($hasConfigtxgen) {
    configtxgen -profile TwoOrgsChannel -channelID aurumchannel -outputCreateChannelTx ./config/aurumchannel.tx -configPath .
    Write-Host "✓ Channel configuration generated" -ForegroundColor Green
} else {
    Write-Host "  Using Docker to generate channel config..." -ForegroundColor Gray
    docker run --rm -v "${PWD}:/work" -w /work -e FABRIC_CFG_PATH=/work hyperledger/fabric-tools:2.5 configtxgen -profile TwoOrgsChannel -channelID aurumchannel -outputCreateChannelTx ./config/aurumchannel.tx -configPath /work
    Write-Host "✓ Channel configuration generated via Docker" -ForegroundColor Green
}

# Start network
if ($StartNetwork) {
    Write-Host ""
    Write-Host "Starting Fabric network..." -ForegroundColor Yellow
    
    # Stop any existing network
    docker-compose -f docker-compose.yaml down -v 2>$null
    
    # Start network
    docker-compose -f docker-compose.yaml up -d
    
    Write-Host ""
    Write-Host "Waiting for network to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host ""
    Write-Host "✓ Fabric network started!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Network Status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.yaml ps
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Create channel: .\create_channel.ps1" -ForegroundColor White
    Write-Host "  2. Deploy chaincode: .\deploy_chaincode.ps1" -ForegroundColor White
    Write-Host "  3. Set FABRIC_GATEWAY_URL in .env file" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "✓ Setup complete! Start network with:" -ForegroundColor Green
    Write-Host "  docker-compose -f docker-compose.yaml up -d" -ForegroundColor White
}

Write-Host ""

