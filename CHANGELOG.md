# Changelog

All notable changes to AurumHarmony will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Hyperledger Fabric Blockchain Integration**
  - Complete Fabric network setup with Docker Compose
  - Crypto material generation scripts (`crypto-config.yaml`, `configtx.yaml`)
  - Automated network setup script (`setup_fabric.ps1`)
  - Channel creation automation (`create_channel.ps1`)
  - Go chaincode for trade and settlement recording (`aurum_chaincode.go`)
  - REST API gateway service for Fabric network (`fabric_gateway.py`)
  - Updated `FabricClient` to make HTTP calls to gateway (replaces NO-OP stubs)
  - Comprehensive setup documentation (`QUICK_START.md`, `README_SETUP.md`)
- Light and Dark Mode theme system with theme toggle button
- Logo integration on login screen (replaces "AurumHarmony" text)
- Theme-aware color system throughout the app
- Admin user creation script with hardcoded credentials
- Comprehensive documentation organization
- Custom domain setup documentation (ah.saffronbolt.in)
- Cloudflare Workers migration plan documentation

### Changed
- `FabricClient.invoke()` and `FabricClient.query()` now make HTTP POST requests to gateway service
- Simplified login flow to single stage (email/phone + password only)
- Updated all UI components to use theme-aware colors
- Replaced hardcoded colors with ThemeColors utility
- Deployment script now auto-generates commit messages from CHANGELOG
- Improved file organization and documentation structure

### Removed
- Ngrok integration and all related scripts/documentation (no longer needed)

### Fixed
- CORS duplicate header issue in Flask backend
- Flutter compilation errors (CardTheme, const expressions)
- Backend blueprint registration issues
- PowerShell script string terminator errors
- Order keying inconsistency in trade execution (rejected orders now use `broker_order_id`)
- P&L double-counting bug in `get_pnl()` method
- App title inconsistency between login and main app (now uses white-label config)

## [1.0] - 2024-11-29

### Added
- Initial Flutter web application
- Flask backend with broker API integrations (HDFC Sky, Kotak Neo)
- Ngrok integration for webhook testing
- Responsive design for multi-platform support
- Quick access launcher scripts
- Cloudflare Pages deployment automation

### Changed
- Improved UI/UX with responsive layouts
- Enhanced error handling and logging

---

## How to Update This Changelog

1. **Quick Update**: Run `.\scripts\update-changelog.ps1` and follow prompts
2. **Manual Update**: Edit this file directly, add entries under `[Unreleased]`
3. **Auto on Deploy**: The deploy script will use the latest `[Unreleased]` entry
4. **Create Release**: Run `.\scripts\create_release.ps1 -Version "1.1"` to move `[Unreleased]` to a version
   - Minor changes: Use 1.1, 1.2, 1.3, etc.
   - Major changes: Use 2.0, 3.0, etc. (for design overhauls, breaking changes)

**Format for entries:**
- `### Added` - New features
- `### Changed` - Changes in existing functionality
- `### Deprecated` - Soon-to-be removed features
- `### Removed` - Removed features
- `### Fixed` - Bug fixes
- `### Security` - Security fixes

**Version History:** See [RELEASES.md](RELEASES.md) for complete release history and version tags.

