# _local Folder Organization - December 13, 2025

**Status:** ✅ Complete

---

## Organization Structure

```
_local/
├── development/          # Development scripts, tools, and utilities
├── documentation/        # All documentation files (.md)
├── logs/                 # Log files (.log, .txt)
└── Summaries/            # EOD .json files for cross-sharing
```

---

## Files Organized

### ✅ Development Folder
- `.db_migration_completed` - Database migration marker
- `This crash may already be reported.bat` - Crash report handler
- All Python scripts (`.py`)
- All PowerShell scripts (`.ps1`)
- Workspace files (`.code-workspace`)
- Development documentation (e.g., `DOB_ANNIVERSARY_IMPLEMENTATION.md`)

### ✅ Documentation Folder
- All markdown documentation files (`.md`)
- Setup guides
- Troubleshooting guides (in `documentation/troubleshooting/`)
- Status reports
- Summaries and progress updates
- README files

**Subdirectories:**
- `documentation/troubleshooting/` - Troubleshooting guides

### ✅ Logs Folder
- `backend.log` - Backend application logs
- `flutter.log` - Flutter frontend logs
- `watch_deploy.log` - Auto-deploy watcher logs
- Diagnostic test logs (`.txt`)
- `_archive/` - Archived diagnostic logs

### ✅ Summaries Folder
- `EOD_2025-12-11_Charlie.json` - End-of-day summary
- `G_C_summary.json` - Cross-sharing summary
- **Purpose:** EOD .json files for cross-sharing between team members

---

## Organization Rules

1. **Development/** - Scripts, tools, utilities, development docs
2. **Documentation/** - All markdown documentation, guides, summaries
3. **Logs/** - All log files (.log, .txt), diagnostic outputs
4. **Summaries/** - EOD .json files only (for cross-sharing)

---

## Before Organization

- 30+ files in `_local/` root
- Mixed file types
- Difficult to find specific files

## After Organization

- ✅ Clean root folder
- ✅ Files organized by purpose
- ✅ Easy to find files
- ✅ Clear structure for team collaboration

---

## Notes

- All `.json` files in `Summaries/` are for cross-sharing between team members (Charlie, G, Jeeves)
- Troubleshooting guides are in `documentation/troubleshooting/`
- Development scripts remain in `development/`
- Logs are automatically generated in `logs/`

---

**Last Updated:** December 13, 2025

