# Release History

This document tracks all official releases of AurumHarmony with version numbers, dates, and key changes.

## Release Process

1. **Prepare Release**: Move `[Unreleased]` entries in `CHANGELOG.md` to a new version
2. **Create Git Tag**: Tag the release commit with version number
3. **Create GitHub Release**: Create a release on GitHub with release notes
4. **Update Version**: Update version in code/config files

## Version Format

We follow a simplified semantic versioning scheme:
- **MAJOR.MINOR** (e.g., 1.0, 1.1, 1.2, 2.0)
- **MAJOR** (1.0 → 2.0): Major changes like design overhauls, architecture changes, breaking changes
- **MINOR** (1.0 → 1.1 → 1.2): Small changes, new features, bug fixes, improvements

**Examples:**
- `1.0` → `1.1`: New features, bug fixes, small improvements
- `1.1` → `1.2`: More features, more fixes
- `1.9` → `2.0`: Complete design overhaul, major architecture change, breaking changes

## Release History

### [1.1] - 2025-12-07 (Planned)

**Major Features:**
- Hyperledger Fabric blockchain integration
- Complete network setup automation
- REST API gateway for blockchain
- Trade and settlement recording on-chain

**Improvements:**
- Repository cleanup (118+ files removed from Git)
- Bug fixes (order keying, P&L calculation, app title)
- Removed ngrok dependency

**Status:** Ready for release

---

### [1.0] - 2024-11-29

**Initial Release:**
- Flutter web application
- Flask backend with broker integrations
- HDFC Sky and Kotak Neo API support
- Cloudflare Pages deployment
- Responsive multi-platform UI

---

## Upcoming Releases

### [1.2] - Planned
- Full blockchain authentication integration
- Chaincode deployment automation
- Enhanced trade logging
- Real-time blockchain queries

### [1.3] - Planned
- Advanced risk management features
- ML model improvements
- Performance optimizations

### [2.0] - Future (Major Release)
- Complete UI/UX design overhaul
- Major architecture changes
- Breaking changes (if any)

---

## How to Create a Release

### Automated (Recommended)
```powershell
# For minor changes (1.0 → 1.1)
.\scripts\create_release.ps1 -Version "1.1"

# For major changes (1.9 → 2.0)
.\scripts\create_release.ps1 -Version "2.0"
```

### Manual Steps
1. Update `CHANGELOG.md` - Move `[Unreleased]` to new version
2. Update version in code/config files
3. Commit changes: `git commit -m "chore: Release v1.1"`
4. Create tag: `git tag -a v1.1 -m "Release v1.1"`
5. Push: `git push origin main --tags`
6. Create GitHub release with release notes

### When to Bump Version

**Minor (1.0 → 1.1):**
- New features
- Bug fixes
- Small improvements
- Documentation updates
- Performance optimizations

**Major (1.x → 2.0):**
- Complete design overhaul
- Major architecture changes
- Breaking changes
- Significant refactoring
- Platform migration

---

**Last Updated:** 2025-12-07

