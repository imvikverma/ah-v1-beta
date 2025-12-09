# Add Hyperledger Fabric configuration to .env file
# This script safely adds Fabric gateway settings to .env

Write-Host "`n=== Add Hyperledger Fabric Config to .env ===" -ForegroundColor Cyan
Write-Host ""

$envPath = ".env"

# Check if .env exists
if (-not (Test-Path $envPath)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path $envPath -ItemType File -Force | Out-Null
}

# Read existing content
$envContent = Get-Content $envPath -ErrorAction SilentlyContinue

# Fabric configuration values
$fabricConfig = @"
# Hyperledger Fabric (Optional - for blockchain integration)
FABRIC_GATEWAY_URL=http://localhost:8080
FABRIC_CHANNEL_NAME=aurumchannel
FABRIC_CHAINCODE_NAME=aurum_cc
"@

# Check if Fabric config already exists
$fabricExists = $envContent | Where-Object { $_ -match "^FABRIC_GATEWAY_URL=" }

if ($fabricExists) {
    Write-Host "⚠️  Fabric configuration already exists in .env" -ForegroundColor Yellow
    Write-Host ""
    $overwrite = Read-Host "Overwrite? (y/N)"
    
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "❌ Cancelled. Fabric config not updated." -ForegroundColor Red
        exit 0
    }
    
    # Remove old Fabric entries
    $newContent = $envContent | Where-Object { 
        $_ -notmatch "^FABRIC_GATEWAY_URL=" -and
        $_ -notmatch "^FABRIC_CHANNEL_NAME=" -and
        $_ -notmatch "^FABRIC_CHAINCODE_NAME=" -and
        $_ -notmatch "^# Hyperledger Fabric"
    }
    $newContent | Set-Content $envPath
}

# Add Fabric config
Add-Content -Path $envPath -Value "`n$fabricConfig"

Write-Host "✅ Fabric configuration added to .env file" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  FABRIC_GATEWAY_URL=http://localhost:8080" -ForegroundColor Gray
Write-Host "  FABRIC_CHANNEL_NAME=aurumchannel" -ForegroundColor Gray
Write-Host "  FABRIC_CHAINCODE_NAME=aurum_cc" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start Fabric network: .\fabric\setup_fabric.ps1" -ForegroundColor White
Write-Host "  2. Create channel: .\fabric\create_channel.ps1" -ForegroundColor White
Write-Host "  3. Start gateway: cd fabric\gateway && python fabric_gateway.py" -ForegroundColor White
Write-Host ""

