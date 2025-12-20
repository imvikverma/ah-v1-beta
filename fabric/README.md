# Hyperledger Fabric Network Setup (Production-like)

This directory contains the configuration and Docker Compose file to launch a production-like Hyperledger Fabric network for AurumHarmony.

## Network Topology
- 2 Organizations (Org1, Org2)
- 1 Orderer
- 1 Certificate Authority (CA) per org
- 1 Peer per org
- Chaincode deployment support

## Prerequisites
- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/)
- [cryptogen](https://hyperledger-fabric.readthedocs.io/en/release-2.5/getting_started.html#prerequisites) and [configtxgen](https://hyperledger-fabric.readthedocs.io/en/release-2.5/commands/configtxgen.html) tools (for generating crypto material and genesis block)
- (Optional) [Fabric binaries](https://hyperledger-fabric.readthedocs.io/en/release-2.5/install.html)

## Setup Steps

1. **Generate Crypto Material**
   - Use `cryptogen` to generate certificates and keys:
     ```sh
     cryptogen generate --config=./crypto-config.yaml --output=./crypto-config
     ```
   - Use `configtxgen` to generate the genesis block:
     ```sh
     configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./config/orderer.genesis.block
     ```
   - Place the generated files in the `crypto-config/` and `config/` directories as referenced in `docker-compose.yaml`.

2. **Start the Network**
   ```sh
   docker-compose -f docker-compose.yaml up -d
   ```

3. **Deploy Chaincode**
   - Follow the [official Fabric chaincode lifecycle](https://hyperledger-fabric.readthedocs.io/en/release-2.5/chaincode_lifecycle.html) to package, install, approve, and commit chaincode.

4. **Shut Down the Network**
   ```sh
   docker-compose -f docker-compose.yaml down -v
   ```

## Notes
- This setup is suitable for development, integration, and pre-production testing.
- For production, use separate hosts, secure your keys, and follow Fabric security best practices.

For more details, see the [Hyperledger Fabric documentation](https://hyperledger-fabric.readthedocs.io/). 