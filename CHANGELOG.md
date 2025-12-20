# Changelog

All notable changes to AurumHarmony will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - 2025-01-16
- **Unified Snapshot System**
  - BrokerAggregator service for multi-engine data collection (HDFC Sky NSE/BSE, Kotak Neo NSE/BSE, Paper Trading)
  - Unified data models (UnifiedPosition, UnifiedBalance, UnifiedQuote, UnifiedSnapshot)
  - API endpoints: `/api/unified-snapshot` and `/api/unified-snapshot/health`
  - Exchange routing (NSE/BSE detection for index options)
  - Parallel data fetching from all 8 engines
- **Index Options Trading Test Scripts**
  - `test_paper_trade.ps1` - Test paper trading with index options (NIFTY50, BANKNIFTY, SENSEX)
  - `test_unified_snapshot_quick.ps1` - Quick unified snapshot testing with auth token
  - `verify_unified_snapshot_routes.ps1` - Route verification script
  - `README_INDEX_OPTIONS.md` - Documentation for Index Options Trading system
- **UI/UX Enhancements**
  - Glassmorphism cards across Dashboard, Trade, Reports, and Admin screens
  - Responsive grid layouts (HD fluid feel) replacing stretched layouts
  - Updated color palette (richer gold/saffron accents, cool blues/neutrals)
  - Improved MetricGauge with glass finish, thicker pointers, titles outside gauges
  - Larger logo across all pages
  - Interactive Active Indices chips on Dashboard
  - Smaller widget-sized Paper Trading tiles
  - Scrollbar masking on landing page

### Changed - 2025-01-16
- **UI Theme System**
  - Refined dark theme with cooler palette (less yellow, more gold)
  - Updated CardThemeData for more rounded corners and deeper shadows
  - Improved GlassCard widget with subtle glassmorphism effects
  - Updated ThemeService to reflect new cooler color scheme
- **Backend Integration**
  - Updated BrokerAggregator to use ExchangeRouter for proper NSE/BSE routing
  - Enhanced paper trading snapshot fetching with exchange detection
  - Improved unified snapshot aggregation logic
- **PowerShell Scripts**
  - Updated message colors (cyan for informational messages instead of yellow/red)
  - Improved token handling in test scripts (parameter, clipboard, environment variable support)

### Fixed - 2025-01-16
- Fixed Dart docstring syntax error (Python-style `"""` replaced with Dart `///` comments)
- Fixed exchange routing in BrokerAggregator for index options (NIFTY50→NSE, SENSEX→BSE)
- Fixed token parameter handling in test scripts
- Fixed Flutter compilation errors

### Added
- **Auto-Deploy System**
  - File watcher script (`watch_and_deploy.ps1`) that monitors Flutter frontend files
  - Auto-deploys to GitHub & Cloudflare when files are saved in Cursor
  - Minimum 2-minute interval between deployments to prevent spam
  - Automatic README.md regeneration on every deploy
  - Quick deploy trigger script (`trigger_deploy.ps1`)
- **HDFC Sky Integration**
  - Complete API integration with all endpoints (positions, holdings, orders, trades, quotes, funds, historical data)
  - Paper trading adapter with live market data (`HDFCSkyPaperAdapter`)
  - Live trading adapter (`HDFCSkyBrokerAdapter`)
  - Factory integration for easy broker switching
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
- Firefox auto-refresh tool for development workflow

### Changed
- `FabricClient.invoke()` and `FabricClient.query()` now make HTTP POST requests to gateway service
- Simplified login flow to single stage (email/phone + password only)
- Updated all UI components to use theme-aware colors
- Replaced hardcoded colors with ThemeColors utility
- Deployment script now auto-generates commit messages from CHANGELOG
- Improved file organization and documentation structure
- **README.md auto-generation**: Now updates automatically with latest stats, version, and features
- **Deployment workflow**: File watcher automatically regenerates README before deploying
- **Menu system**: Simplified and fixed erratic behavior in `start-all.ps1`
- **Flutter startup**: Improved error handling, process cleanup, and port conflict resolution

### Removed
- Ngrok integration and all related scripts/documentation (no longer needed)

### Fixed
- **Auto-deploy system**: Fixed git change detection logic, now properly detects uncommitted and untracked files
- **Menu behavior**: Fixed erratic menu in `start-all.ps1` caused by excessive directory changes
- **Flutter startup**: Fixed build directory lock issues, added process cleanup, automatic port conflict resolution
- **Firefox refresh script**: Improved cross-origin tab handling, better cache-busting, clearer error messages
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

