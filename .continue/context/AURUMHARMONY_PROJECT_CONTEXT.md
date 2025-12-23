# AurumHarmony Project Context

**Last Updated:** December 23, 2025  
**Purpose:** Context file for Continue AI assistant in VS Code

## Project Overview

AurumHarmony is a production-ready AI-powered algorithmic trading platform with:
- **Flutter Frontend**: Responsive web application
- **Flask Backend**: RESTful API with comprehensive endpoints
- **Multi-Broker Integration**: HDFC Sky, Kotak Neo, Mangal Keshav
- **Trading Engines**: AI predictions, risk management, compliance
- **Blockchain**: Hyperledger Fabric for trade settlement
- **Deployment**: Cloudflare Pages, GitHub Actions, Render.com

## Key Directories

```
AurumHarmonyTest/
├── aurum_harmony/          # Main application
│   ├── frontend/          # Flutter web app
│   ├── master_codebase/   # Flask backend API
│   ├── engines/           # Trading engines
│   ├── blockchain/        # Hyperledger Fabric
│   └── app/               # Core logic
├── api/                    # Broker API clients
├── scripts/               # Utility scripts
├── _local/                # Local files (not in git)
│   ├── backups/          # Automated backups
│   ├── documentation/     # Project docs
│   └── development/      # Dev tools
├── .venv/                 # Python virtual environment (3.11.9)
└── start-all.ps1          # Master launcher
```

## Current Project State (Dec 23, 2025)

### ✅ Completed Recently
- Virtual environment rebuilt (Python 3.11.9)
- Comprehensive backup system created
- VS Code workspace mirror created
- Broker API integration ready
- EOD flow includes automatic backups
- Project structure organized

### 🔄 In Progress
- Broker API integration testing
- Live trading preparation
- Production deployment

### 📋 Key Files

**Configuration:**
- `requirements.txt` - Python dependencies
- `wrangler.toml` - Cloudflare Workers config
- `render.yaml` - Render.com deployment
- `.env` - Environment variables (not in git)

**Documentation:**
- `README.md` - Project overview
- `CHANGELOG.md` - Version history
- `_local/documentation/` - Comprehensive guides
- `FILE_STRUCTURE.md` - Project structure

**Scripts:**
- `start-all.ps1` - Master launcher menu
- `scripts/backup_project.ps1` - Automated backups
- `scripts/mirror_to_vscode.ps1` - VS Code mirror
- `scripts/run-eod-flow.ps1` - End of day workflow

## Development Workflow

### Starting the Project
```powershell
.\start-all.ps1
# Option 1: Start Backend
# Option 2: Start Frontend
# Option 3: Start Both
```

### Virtual Environment
- Location: `.venv/`
- Python: 3.11.9
- Auto-activation: Configured in PowerShell profile
- Rebuild: `.\rebuild_flask_env.ps1`

### Backup System
- **Automated**: Nightly at 11 PM (if scheduled)
- **EOD Flow**: Automatic during end-of-day
- **Manual**: `.\scripts\backup_project.ps1`
- **Location**: `_local\backups\backup_YYYYMMDD-HHMMSS.zip`
- **VS Code Mirror**: Parent directory with timestamp

### Broker Integration
- **HDFC Sky**: Primary broker for live trading
- **Kotak Neo**: Secondary broker for live data
- **Test**: `.\scripts\test_broker_connections.ps1`
- **Guide**: `_local\documentation\BROKER_API_INTEGRATION_GUIDE.md`

## Code Patterns

### Flask Backend
- Blueprint-based routing
- SQLAlchemy for database
- JWT authentication
- CORS enabled
- Error handling with try/except

### Flutter Frontend
- Provider for state management
- Theme-aware colors (light/dark mode)
- Responsive design
- REST API integration
- WebSocket for real-time updates

### PowerShell Scripts
- Robust project root detection
- Error handling with try/catch
- Color-coded output
- Progress indicators

## Important Notes

1. **Never commit sensitive files**: `.env`, `_local/`, `.venv/`
2. **Backup before major changes**: Run backup script manually
3. **EOD flow**: Always run before closing for the day
4. **Git workflow**: Use feature branches, PRs to main
5. **Documentation**: Update `_local/documentation/` for new features

## Common Tasks

### Add New Feature
1. Create feature branch
2. Implement feature
3. Update documentation
4. Test thoroughly
5. Run EOD flow
6. Create PR

### Deploy to Production
1. Ensure all tests pass
2. Update CHANGELOG.md
3. Run backup
4. Push to GitHub
5. GitHub Actions deploys automatically

### Troubleshooting
- Check `_local/documentation/` for guides
- Review `scripts/comprehensive_integrity_check.ps1` output
- Check backup logs: `_local\backups\backup_log.txt`
- Review EOD summaries: `_local\documentation\summaries\`

## AI Assistant Guidelines

When helping with this project:
1. **Always check context**: Read relevant files before suggesting changes
2. **Follow patterns**: Match existing code style and patterns
3. **Update docs**: Document new features in `_local/documentation/`
4. **Test scripts**: Verify PowerShell scripts work from any directory
5. **Backup awareness**: Remind about backups before major changes
6. **Git safety**: Never force push to main, use branches

## Quick Reference

- **Project Root**: `D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest`
- **Backend Port**: 5000
- **Frontend Port**: 58643
- **Git Remote**: `https://github.com/imvikverma/ah-v1-beta.git`
- **Main Branch**: `main`
- **Backup Schedule**: Daily at 23:00 (11 PM)

---

*This context file helps Continue AI assistant understand the project structure and current state.*

