# Changelog

All notable changes to AurumHarmony will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dynamic changelog and README generation system
- Automated deployment with changelog-based commit messages

### Changed
- Deploy script now reads from CHANGELOG.md for commit messages

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

