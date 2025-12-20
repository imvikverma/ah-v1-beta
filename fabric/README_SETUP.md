# Hyperledger Fabric Setup Guide for AurumHarmony

## Quick Start

### Prerequisites
1. **Docker Desktop** - Must be installed and running
2. **Docker Compose** - Usually included with Docker Desktop
3. (Optional) **Fabric Tools** - `cryptogen` and `configtxgen` (or use Docker)

### Step 1: Start Docker Desktop
Ensure Docker Desktop is running before proceeding.

### Step 2: Generate Crypto Material and Start Network
```powershell
cd fabric
.\setup_fabric.ps1
```

This will:
- Generate crypto material (certificates and keys)
- Generate genesis block
- Generate channel configuration
- Start the Fabric network

### Step 3: Create Channel
```powershell
.\create_channel.ps1
```

### Step 4: Deploy Chaincode
```powershell
.\deploy_chaincode.ps1
```

### Step 5: Start Gateway Service
```powershell
cd gateway
python fabric_gateway.py
```

The gateway will run on `http://localhost:8080`

### Step 6: Configure Environment
Add to your `.env` file:
```
FABRIC_GATEWAY_URL=http://localhost:8080
FABRIC_CHANNEL_NAME=aurumchannel
FABRIC_CHAINCODE_NAME=aurum_cc
```

## Network Architecture

- **Orderer**: `orderer.example.com:7050`
- **Org1 CA**: `ca_org1:7054`
- **Org2 CA**: `ca_org2:8054`
- **Org1 Peer**: `peer0.org1.example.com:7051`
- **Org2 Peer**: `peer0.org2.example.com:8051`
- **Channel**: `aurumchannel`
- **Chaincode**: `aurum_cc`

## Verification

Check network status:
```powershell
docker-compose -f docker-compose.yaml ps
```

Test gateway:
```powershell
curl http://localhost:8080/health
```

## Stopping the Network

```powershell
docker-compose -f docker-compose.yaml down -v
```

## Troubleshooting

### Docker not running
- Start Docker Desktop
- Wait for it to fully start
- Verify with: `docker ps`

### Port conflicts
- Ensure ports 7050, 7051, 7054, 8051, 8054, 8080 are available
- Stop any conflicting services

### Crypto material errors
- Delete `crypto-config/` and `config/` directories
- Re-run `setup_fabric.ps1`

