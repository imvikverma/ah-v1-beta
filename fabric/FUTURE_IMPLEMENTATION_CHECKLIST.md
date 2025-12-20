# Hyperledger Fabric SDK Implementation Checklist

**Status:** 📋 Future Task (Not Urgent)  
**Estimated Time:** 5-7 days total  
**When to Start:** 2-4 weeks before production launch

---

## 🎯 Quick Overview

This checklist is for implementing real Fabric SDK integration in the gateway service. The current stub implementation is fine for development and testing.

**Current State:**
- ✅ Network running (Docker Compose)
- ✅ Channel created
- ✅ Chaincode code written
- ⚠️ Gateway returns mock responses (needs SDK integration)
- ⚠️ Chaincode not deployed (needs deployment)

---

## Phase 1: Install Dependencies (30 minutes)

- [ ] **Choose SDK Option:**
  - [ ] Option A: Fabric Gateway SDK (Python) - **Recommended**
    ```bash
    pip install fabric-gateway
    ```
  - [ ] Option B: Fabric SDK Python (legacy)
    ```bash
    pip install fabric-sdk-py
    ```

- [ ] **Update requirements.txt:**
  ```txt
  fabric-gateway>=0.4.0
  # OR
  # fabric-sdk-py>=1.0.0
  ```

- [ ] **Install dependencies:**
  ```powershell
  cd fabric\gateway
  pip install -r requirements.txt
  ```

---

## Phase 2: Implement Gateway SDK (2-3 days)

### Step 1: Initialize Connection (2-3 hours)

- [ ] **Create connection configuration:**
  ```python
  # In fabric_gateway.py
  from fabric_gateway import Gateway, Network, Contract
  
  # Connection config
  peer_endpoint = "localhost:7051"
  peer_tls_cert = "path/to/peer/tls/cert"
  gateway = Gateway()
  ```

- [ ] **Load crypto material:**
  - [ ] Load user certificate
  - [ ] Load private key
  - [ ] Load CA certificate

- [ ] **Connect to network:**
  ```python
  network = gateway.get_network("aurumchannel")
  contract = network.get_contract("aurum_cc")
  ```

### Step 2: Implement Invoke Method (4-6 hours)

- [ ] **Replace stub invoke() with real SDK call:**
  ```python
  @app.route("/invoke", methods=["POST"])
  def invoke():
      data = request.json
      function_name = data.get("function")
      args = data.get("args", {})
      
      # Convert args to list format
      args_list = [json.dumps(args)]
      
      # Submit transaction
      result = contract.submit_transaction(function_name, *args_list)
      
      return jsonify({
          "status": "success",
          "result": result.decode('utf-8')
      }), 200
  ```

- [ ] **Add error handling:**
  - [ ] Handle network errors
  - [ ] Handle timeout errors
  - [ ] Handle endorsement errors
  - [ ] Return proper error messages

### Step 3: Implement Query Method (2-3 hours)

- [ ] **Replace stub query() with real SDK call:**
  ```python
  @app.route("/query", methods=["POST"])
  def query():
      data = request.json
      function_name = data.get("function")
      args = data.get("args", {})
      
      # Convert args to list format
      args_list = [json.dumps(args)]
      
      # Evaluate transaction (read-only)
      result = contract.evaluate_transaction(function_name, *args_list)
      
      return jsonify({
          "status": "success",
          "result": json.loads(result.decode('utf-8'))
      }), 200
  ```

- [ ] **Add error handling:**
  - [ ] Handle network errors
  - [ ] Handle query errors
  - [ ] Return proper error messages

### Step 4: Add Connection Management (2-3 hours)

- [ ] **Implement connection pooling:**
  - [ ] Reuse gateway connections
  - [ ] Handle connection failures
  - [ ] Implement retry logic

- [ ] **Add connection health checks:**
  - [ ] Verify network connectivity
  - [ ] Check channel status
  - [ ] Verify chaincode availability

---

## Phase 3: Deploy Chaincode (1 day)

### Step 1: Package Chaincode (1-2 hours)

- [ ] **Install Go dependencies:**
  ```bash
  cd fabric/chaincode
  go mod init aurum_chaincode
  go get github.com/hyperledger/fabric-contract-api-go/contractapi
  go mod tidy
  ```

- [ ] **Package chaincode:**
  ```bash
  # Using peer CLI in Docker
  docker exec peer0.org1.example.com peer lifecycle chaincode package aurum_cc.tar.gz \
    --path /opt/gopath/src/github.com/chaincode/aurum_chaincode \
    --lang golang \
    --label aurum_cc_1.0
  ```

### Step 2: Install Chaincode (1-2 hours)

- [ ] **Install on Org1 peer:**
  ```bash
  docker exec peer0.org1.example.com peer lifecycle chaincode install aurum_cc.tar.gz
  ```

- [ ] **Install on Org2 peer:**
  ```bash
  docker exec peer0.org2.example.com peer lifecycle chaincode install aurum_cc.tar.gz
  ```

- [ ] **Get package IDs:**
  ```bash
  docker exec peer0.org1.example.com peer lifecycle chaincode queryinstalled
  ```

### Step 3: Approve Chaincode (1-2 hours)

- [ ] **Approve for Org1:**
  ```bash
  docker exec peer0.org1.example.com peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID aurumchannel \
    --name aurum_cc \
    --version 1.0 \
    --package-id <PACKAGE_ID> \
    --sequence 1
  ```

- [ ] **Approve for Org2:**
  ```bash
  docker exec peer0.org2.example.com peer lifecycle chaincode approveformyorg \
    -o orderer.example.com:7050 \
    --channelID aurumchannel \
    --name aurum_cc \
    --version 1.0 \
    --package-id <PACKAGE_ID> \
    --sequence 1
  ```

### Step 4: Commit Chaincode (1 hour)

- [ ] **Commit to channel:**
  ```bash
  docker exec peer0.org1.example.com peer lifecycle chaincode commit \
    -o orderer.example.com:7050 \
    --channelID aurumchannel \
    --name aurum_cc \
    --version 1.0 \
    --sequence 1 \
    --peerAddresses peer0.org1.example.com:7051 \
    --peerAddresses peer0.org2.example.com:8051
  ```

- [ ] **Verify deployment:**
  ```bash
  docker exec peer0.org1.example.com peer lifecycle chaincode querycommitted \
    --channelID aurumchannel \
    --name aurum_cc
  ```

---

## Phase 4: Testing (1 day)

### Step 1: Unit Tests (2-3 hours)

- [ ] **Test invoke endpoint:**
  ```bash
  curl -X POST http://localhost:8080/invoke \
    -H "Content-Type: application/json" \
    -d '{
      "function": "RecordTrade",
      "args": {
        "trade_id": "test_001",
        "user_id": "user_123",
        "symbol": "RELIANCE",
        "side": "BUY",
        "quantity": 10,
        "price": "2500.00"
      }
    }'
  ```

- [ ] **Test query endpoint:**
  ```bash
  curl -X POST http://localhost:8080/query \
    -H "Content-Type: application/json" \
    -d '{
      "function": "QueryTradeByID",
      "args": {"trade_id": "test_001"}
    }'
  ```

- [ ] **Test error handling:**
  - [ ] Invalid function name
  - [ ] Missing arguments
  - [ ] Network errors
  - [ ] Timeout errors

### Step 2: Integration Tests (3-4 hours)

- [ ] **Test trade recording:**
  - [ ] Record a trade
  - [ ] Verify on blockchain
  - [ ] Query the trade

- [ ] **Test settlement recording:**
  - [ ] Record a settlement
  - [ ] Verify on blockchain
  - [ ] Query the settlement

- [ ] **Test query functions:**
  - [ ] Query by trade ID
  - [ ] Query by user ID
  - [ ] Query all trades

### Step 3: End-to-End Test (1-2 hours)

- [ ] **Test from Python backend:**
  ```python
  from aurum_harmony.blockchain.fabric_client import FabricClient
  
  client = FabricClient()
  result = client.invoke("RecordTrade", {
      "trade_id": "test_002",
      "user_id": "user_456",
      "symbol": "TCS",
      "side": "SELL",
      "quantity": 5,
      "price": "3500.00"
  })
  print(result)
  ```

- [ ] **Verify in logs:**
  - [ ] Check gateway logs
  - [ ] Check Fabric network logs
  - [ ] Verify blockchain state

---

## Phase 5: Production Hardening (2-3 days)

### Step 1: Remove Debug Mode (30 minutes)

- [ ] **Update gateway:**
  ```python
  # Change from:
  app.run(host="0.0.0.0", port=GATEWAY_PORT, debug=True)
  
  # To:
  app.run(host="0.0.0.0", port=GATEWAY_PORT, debug=False)
  ```

- [ ] **Update logging:**
  - [ ] Set production log level
  - [ ] Remove debug statements
  - [ ] Add structured logging

### Step 2: Add Security (1-2 days)

- [ ] **Add authentication:**
  - [ ] JWT token validation
  - [ ] API key authentication
  - [ ] Rate limiting

- [ ] **Add input validation:**
  - [ ] Validate function names
  - [ ] Validate arguments
  - [ ] Sanitize inputs

- [ ] **Enable HTTPS:**
  - [ ] Configure SSL certificates
  - [ ] Force HTTPS only
  - [ ] Update CORS settings

### Step 3: Add Monitoring (1 day)

- [ ] **Add metrics:**
  - [ ] Request count
  - [ ] Response time
  - [ ] Error rate
  - [ ] Success rate

- [ ] **Add health checks:**
  - [ ] Network connectivity
  - [ ] Channel status
  - [ ] Chaincode status

- [ ] **Add alerting:**
  - [ ] Error alerts
  - [ ] Performance alerts
  - [ ] Health check failures

---

## 📝 Quick Reference Commands

### Start Network
```powershell
cd fabric
docker-compose -f docker-compose.yaml up -d
```

### Check Network Status
```powershell
docker-compose -f docker-compose.yaml ps
```

### View Logs
```powershell
docker logs fabric-peer0.org1.example.com-1
docker logs fabric-orderer.example.com-1
```

### Test Gateway
```powershell
curl http://localhost:8080/health
```

### Stop Network
```powershell
docker-compose -f docker-compose.yaml down
```

---

## 🚨 Common Issues & Solutions

### Issue: "Connection refused"
**Solution:** Ensure Fabric network is running
```powershell
docker-compose -f fabric/docker-compose.yaml ps
```

### Issue: "Chaincode not found"
**Solution:** Deploy chaincode first (Phase 3)

### Issue: "TLS handshake failed"
**Solution:** Verify TLS certificates are properly mounted

### Issue: "Endorsement policy failure"
**Solution:** Ensure both orgs have approved chaincode

---

## 📚 Resources

- [Fabric Gateway SDK Docs](https://hyperledger.github.io/fabric-gateway/)
- [Fabric Chaincode Lifecycle](https://hyperledger-fabric.readthedocs.io/en/release-2.5/chaincode_lifecycle.html)
- [Fabric Python SDK](https://github.com/hyperledger/fabric-sdk-py)

---

## ✅ Completion Criteria

You're done when:
- [ ] Gateway makes real Fabric SDK calls (not stubs)
- [ ] Chaincode is deployed and running
- [ ] Trade recording works end-to-end
- [ ] Query functions return real data
- [ ] Error handling is robust
- [ ] Security is implemented
- [ ] Monitoring is in place

**Estimated Total Time:** 5-7 days

---

**Note:** This is a future task. Current stub implementation is fine for development. Start this checklist 2-4 weeks before production launch.

