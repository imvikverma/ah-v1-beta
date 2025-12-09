# Deploy chaincode to Hyperledger Fabric network
# Note: This is a simplified deployment. For production, use proper chaincode lifecycle

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "Deploying AurumHarmony Chaincode..." -ForegroundColor Cyan
Write-Host ""

# Check if network is running
$networkRunning = docker ps --filter "name=peer0.org1" --format "{{.Names}}" | Select-String "peer0.org1"
if (-not $networkRunning) {
    Write-Host "✗ Fabric network is not running" -ForegroundColor Red
    Write-Host "  Start it first with: docker-compose -f docker-compose.yaml up -d" -ForegroundColor Yellow
    exit 1
}

# Check if channel exists
$channelExists = docker exec peer0.org1.example.com peer channel list 2>&1 | Select-String "aurumchannel"
if (-not $channelExists) {
    Write-Host "✗ Channel 'aurumchannel' does not exist" -ForegroundColor Red
    Write-Host "  Create it first with: .\create_channel.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "⚠ Chaincode deployment requires:" -ForegroundColor Yellow
Write-Host "  1. Chaincode packaged and installed" -ForegroundColor Gray
Write-Host "  2. Chaincode approved by both orgs" -ForegroundColor Gray
Write-Host "  3. Chaincode committed to channel" -ForegroundColor Gray
Write-Host ""
Write-Host "For now, use Fabric CLI or SDK to deploy:" -ForegroundColor Cyan
Write-Host "  See: https://hyperledger-fabric.readthedocs.io/en/release-2.5/chaincode_lifecycle.html" -ForegroundColor White
Write-Host ""
Write-Host "Or use a Fabric gateway service that handles deployment automatically." -ForegroundColor Gray
Write-Host ""

