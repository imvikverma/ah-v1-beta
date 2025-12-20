# Local Files Directory

This `_local/` directory contains all files that are **local-only** and **NOT tracked in git**. These files are for development, documentation, and local use only.

## Structure

```
_local/
├── documentation/          # All instructional markdown files, guides, notes
│   ├── project-documentation/  # Organized project documentation
│   ├── other-files/            # Miscellaneous documentation
│   └── *.md                    # Various instructional files
│
├── development/            # Development tools and shortcuts
│   ├── zzz-quick-access/      # Quick launcher scripts
│   ├── *.ps1                   # Development scripts
│   └── *.code-workspace        # IDE workspace files
│
├── archive/                # Old/legacy files
│   ├── old-files/             # Legacy code files
│   ├── code-files/             # Old code versions
│   └── design/                 # Design files, mockups
│
├── logs/                    # All log files
│   ├── backend.log
│   ├── flutter.log
│   └── auto_deploy.log
│
└── snapshots/              # Snapshot files
```

## Important Notes

- **This entire directory is ignored by git** (via `.gitignore`)
- Files here are **NOT deployed** to production
- Files here are **NOT pushed** to GitHub
- All files remain accessible locally for development

## What Goes Where

- **Documentation** → `_local/documentation/`
- **Development scripts** → `_local/development/`
- **Old/legacy files** → `_local/archive/`
- **Log files** → `_local/logs/`
- **Snapshots** → `_local/snapshots/`

See `_local/documentation/FILE_ORGANIZATION_GUIDE.md` for detailed guidelines.
