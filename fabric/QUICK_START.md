# Quick Start: Activate Hyperledger Fabric

## ⚠️ IMPORTANT: Start Docker Desktop First!

Before running any commands, ensure **Docker Desktop is running**.

## One-Command Setup

From the project root:
```powershell
.\scripts\setup_fabric_network.ps1
```

Or manually:
```powershell
cd fabric
.\setup_fabric.ps1
.\create_channel.ps1
```

## Configure Environment

Add to `.env` file in project root:
```
FABRIC_GATEWAY_URL=http://localhost:8080
FABRIC_CHANNEL_NAME=aurumchannel
FABRIC_CHAINCODE_NAME=aurum_cc
```

## Start Gateway Service

```powershell
cd fabric\gateway
python fabric_gateway.py
```

Gateway will be available at: `http://localhost:8080`

## Verify Setup

1. Check network: `docker-compose -f fabric/docker-compose.yaml ps`
2. Test gateway: `curl http://localhost:8080/health`
3. Check logs: Your Python app should now log Fabric calls instead of NO-OPs

## What This Enables

✅ Trade logging to blockchain  
✅ Settlement recording  
✅ Immutable audit trail  
✅ Query trades by user  
✅ 7-year compliance records  

## Next Steps

- Deploy chaincode (see `deploy_chaincode.ps1`)
- Integrate with authentication (blockchain-based identity)
- Test trade recording

