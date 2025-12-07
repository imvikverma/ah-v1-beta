# Auto-Deploy & Silent Mode Guide

## Overview

The system now supports:
1. **Silent/Minimized Execution**: Flask and Flutter run in minimized windows, only showing popups for critical errors
2. **Auto-Deploy**: Automatically watches for changes and deploys to GitHub & Cloudflare
3. **Force Push Support**: Option to force push when needed

## Silent Mode

### How It Works

**Backend (Flask):**
- Runs in minimized PowerShell window
- All output goes to `logs\backend.log`
- Only critical errors show popup dialogs
- Window stays minimized unless there's a critical error

**Frontend (Flutter):**
- Runs in minimized PowerShell window
- All output goes to `logs\flutter.log`
- Only critical errors show popup dialogs
- Window stays minimized unless there's a critical error

### Log Files

All logs are stored in `logs\` directory:
- `logs\backend.log` - Flask backend logs
- `logs\flutter.log` - Flutter frontend logs
- `logs\auto_deploy.log` - Auto-deploy watcher logs

### Critical Errors

Only these trigger popup dialogs:
- Virtual environment not found
- Python/Flutter not accessible
- Application file not found
- Fatal exceptions/crashes

Regular errors and warnings are logged but don't show popups.

## Auto-Deploy

### How It Works

The auto-deploy watcher:
1. Runs in completely hidden window (no taskbar icon)
2. Checks for Git changes every 30 seconds
3. Automatically builds Flutter web app
4. Commits and pushes to GitHub
5. Cloudflare automatically deploys from GitHub

### Starting Auto-Deploy

**From Menu:**
1. Run `start-all.ps1`
2. Select Option 5: "Enable Auto-Deploy"
3. Watcher starts in background (hidden)

**Manual Start:**
```powershell
.\scripts\auto_deploy.ps1
```

**Force Deploy (immediate):**
```powershell
.\scripts\auto_deploy.ps1 -Force
```

### Stopping Auto-Deploy

1. Open Task Manager (Ctrl+Shift+Esc)
2. Find PowerShell process running `auto_deploy.ps1`
3. End the process

Or restart your computer (it doesn't auto-start on boot).

### What Triggers Deploy

Auto-deploy triggers when:
- Uncommitted changes in `docs/` directory
- Uncommitted changes in `README.md` or `CHANGELOG.md`
- Unpushed commits to `main` branch
- Force mode enabled (`-Force` flag)

### Logs

Check `logs\auto_deploy.log` for:
- Deployment status
- Errors
- Timestamps
- Commit messages

## Force Push

### When to Use

Force push is needed when:
- Local branch has diverged from remote
- Need to overwrite remote history
- Emergency deployment required

### How to Use

**In Deploy Script:**
```powershell
.\scripts\deploy_cloudflare.ps1 -Force
```

**In Auto-Deploy:**
```powershell
.\scripts\auto_deploy.ps1 -Force
```

⚠️ **Warning**: Force push overwrites remote history. Use with caution!

## Menu Options

Updated menu in `start-all.ps1`:
1. Start Backend (Flask) - **Now runs in silent mode**
2. Start Frontend (Flutter) - **Now runs in silent mode**
3. Start Both - **Both run in silent mode**
4. Deploy to Cloudflare Pages (Build + Push)
5. **Enable Auto-Deploy** (NEW) - Starts background watcher
6. Send Monthly Birthday/Anniversary Report
7. View Documentation
8. Exit

## Troubleshooting

### Services Not Starting

1. Check logs: `logs\backend.log` or `logs\flutter.log`
2. Look for critical error popups
3. Verify paths in scripts are correct
4. Check if ports 5000 and 58643 are available

### Auto-Deploy Not Working

1. Check `logs\auto_deploy.log`
2. Verify you're on `main` branch
3. Check if there are actual changes to deploy
4. Verify Git credentials are set up
5. Check if Cloudflare Pages is connected to GitHub

### Windows Not Minimizing

- PowerShell windows should minimize automatically
- If they don't, check Windows display settings
- Try running scripts directly (not through start-all.ps1)

### Force Push Issues

- Ensure you have write access to the repository
- Check if branch protection rules allow force push
- Verify you're pushing to the correct branch (`main`)

## Best Practices

1. **Check Logs First**: Before investigating issues, check log files
2. **Monitor Auto-Deploy**: Check `logs\auto_deploy.log` periodically
3. **Use Force Sparingly**: Only use force push when absolutely necessary
4. **Keep Services Running**: Let Flask and Flutter run in background
5. **Regular Cleanup**: Archive old log files periodically

## File Structure

```
scripts/
├── start_backend_silent.ps1    # Silent Flask startup
├── start_flutter_silent.ps1    # Silent Flutter startup
├── auto_deploy.ps1             # Auto-deploy watcher
└── deploy_cloudflare.ps1       # Deployment script (with force support)

logs/
├── backend.log                 # Flask logs
├── flutter.log                 # Flutter logs
└── auto_deploy.log            # Auto-deploy logs
```

