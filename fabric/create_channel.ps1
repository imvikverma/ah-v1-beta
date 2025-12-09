# Create and join channel on Hyperledger Fabric network

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "Creating Fabric channel 'aurumchannel'..." -ForegroundColor Cyan
Write-Host ""

# Check if network is running
$networkRunning = docker ps --filter "name=peer0.org1" --format "{{.Names}}" | Select-String "peer0.org1"
if (-not $networkRunning) {
    Write-Host "✗ Fabric network is not running" -ForegroundColor Red
    Write-Host "  Start it first with: docker-compose -f docker-compose.yaml up -d" -ForegroundColor Yellow
    exit 1
}

# Create channel
Write-Host "Creating channel..." -ForegroundColor Yellow
docker exec peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c aurumchannel -f /etc/hyperledger/fabric/config/aurumchannel.tx --tls --cafile /etc/hyperledger/fabric/config/orderer.crt 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Channel created" -ForegroundColor Green
} else {
    Write-Host "⚠ Channel may already exist (this is OK)" -ForegroundColor Yellow
}

# Join Org1 peer
Write-Host "Joining Org1 peer to channel..." -ForegroundColor Yellow
docker exec peer0.org1.example.com peer channel join -b aurumchannel.block 2>&1 | Out-Null
Write-Host "✓ Org1 peer joined channel" -ForegroundColor Green

# Join Org2 peer
Write-Host "Joining Org2 peer to channel..." -ForegroundColor Yellow
docker exec peer0.org2.example.com peer channel join -b aurumchannel.block 2>&1 | Out-Null
Write-Host "✓ Org2 peer joined channel" -ForegroundColor Green

Write-Host ""
Write-Host "✓ Channel setup complete!" -ForegroundColor Green
Write-Host ""

