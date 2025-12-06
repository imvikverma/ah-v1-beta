# Changelog

All notable changes to AurumHarmony will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Light and Dark Mode theme system with theme toggle button
- Logo integration on login screen (replaces "AurumHarmony" text)
- Theme-aware color system throughout the app
- Admin user creation script with hardcoded credentials
- Comprehensive documentation organization
- Custom domain setup documentation (ah.saffronbolt.in)
- Cloudflare Workers migration plan documentation

### Changed
- Simplified login flow to single stage (email/phone + password only)
- Updated all UI components to use theme-aware colors
- Replaced hardcoded colors with ThemeColors utility
- Deployment script now auto-generates commit messages from CHANGELOG
- Improved file organization and documentation structure

### Fixed
- CORS duplicate header issue in Flask backend
- Flutter compilation errors (CardTheme, const expressions)
- Backend blueprint registration issues
- PowerShell script string terminator errors

## [1.0.0] - 2024-11-29

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

**Format for entries:**
- `### Added` - New features
- `### Changed` - Changes in existing functionality
- `### Deprecated` - Soon-to-be removed features
- `### Removed` - Removed features
- `### Fixed` - Bug fixes
- `### Security` - Security fixes

