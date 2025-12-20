# File Organization Guide

## Quick Reference: Where to Put New Files

### Production Files (Tracked in Git)

#### Application Code
- `aurum_harmony/` - Main application code
- `api/` - API client modules (HDFC Sky, Kotak Neo, etc.)
- `config/` - Configuration scripts
- `engines/` - Trading engines
- `worker/` - Cloudflare Worker code
- `scripts/` - Production scripts (deployment, startup, etc.)

#### Configuration & Documentation
- Root level: `README.md`, `CHANGELOG.md`, `SECURITY.md`, `requirements.txt`, `rules.md`, `FILE_STRUCTURE.md`
- `wrangler.toml` - Cloudflare Worker config
- `CNAME` - Custom domain config

#### Deployment
- `.github/` - GitHub Actions workflows
- `k8s/` - Kubernetes deployment configs
- `ci/` - CI configuration
- `docs/` - Flutter web build output (for Cloudflare Pages)

#### Templates
- `templates/` - HTML templates

---

### Local-Only Files (NOT Tracked in Git - `_local/`)

#### Documentation
- `_local/documentation/` - All instructional markdown files, guides, notes
  - `_local/documentation/project-documentation/` - Organized project docs
  - `_local/documentation/other-files/` - Miscellaneous docs

#### Development Tools
- `_local/development/` - Development shortcuts, quick access scripts
  - `_local/development/zzz-quick-access/` - Quick launcher scripts

#### Archive
- `_local/archive/old-files/` - Legacy/old code files
- `_local/archive/code-files/` - Old code versions
- `_local/archive/design/` - Design files, mockups

#### Logs
- `_local/logs/` - All log files (backend.log, flutter.log, etc.)

#### Snapshots
- `_local/snapshots/` - Snapshot files

---

## Rules for New Files

### ✅ DO:
- Put production code in appropriate production folders
- Put documentation in `_local/documentation/`
- Put development tools in `_local/development/`
- Put logs in `_local/logs/`
- Put old/legacy files in `_local/archive/`
- Put design files in `_local/archive/design/`

### ❌ DON'T:
- Don't put instructional docs in root (use `_local/documentation/`)
- Don't put development shortcuts in root (use `_local/development/`)
- Don't put logs in root (use `_local/logs/`)
- Don't put old files in root (use `_local/archive/`)

---

## Examples

### Creating a new documentation file:
```
✅ _local/documentation/NEW_FEATURE_GUIDE.md
❌ NEW_FEATURE_GUIDE.md (root)
```

### Creating a new development script:
```
✅ _local/development/quick-test.ps1
❌ quick-test.ps1 (root)
```

### Creating a new production script:
```
✅ scripts/deploy_feature.ps1
❌ deploy_feature.ps1 (root)
```

### Creating a new API module:
```
✅ api/new_broker.py
❌ new_broker.py (root)
```

---

## Remember

- **Production files** = Tracked in git, deployed to production
- **Local files** = Development only, stored in `_local/`, ignored by git
