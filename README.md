# AurumHarmony Project

## Project Rules and Compliance

All contributors and system AI must follow the requirements in `rules.md`. This file outlines:
- Development guidelines
- Coding standards
- Security protocols
- Compliance requirements
- Testing and deployment
- Maintenance and updates

Automated checks and code reviews should reference `rules.md` to ensure compliance.

## Hyperledger Fabric Docker Setup

A production-like Hyperledger Fabric network can be launched using Docker Compose. The setup includes:
- 2 Organizations (Org1, Org2)
- 1 Orderer
- 1 CA per org
- 1 Peer per org
- Chaincode deployment support

**Setup instructions and files are in the `fabric/` directory.**

To start the network:
```sh
docker-compose -f fabric/docker-compose.yaml up -d
```

For more details, see `fabric/README.md`. 