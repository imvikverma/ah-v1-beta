# Quick Access Guide

## 🚀 Accessing the Menu Without Restarting Services

When your services (Flask, Ngrok, Flutter) are already running, you can access the menu in two ways:

### Option 1: Menu-Only Script (Recommended)
```powershell
.\zzz-quick-access\menu-only.ps1
```

This opens the menu **without** affecting any running services. Perfect for:
- Deploying to Cloudflare
- Updating Changelog
- Regenerating README
- Testing credentials
- Accessing other tools

### Option 2: Regular Launcher
```powershell
.\zzz-quick-access\start-all.ps1
```

This is the same menu, but the name suggests it starts services. Both scripts work identically - they just show the menu and let you choose what to do.

## 📋 Available Options

1. **Flask Backend** - Start Flask (if not running)
2. **Ngrok Tunnel** - Start Ngrok (if not running)
3. **Flutter Dev Server** - Start Flutter (if not running)
4. **Deploy to Cloudflare Pages** - Build and deploy Flutter web
5. **Update Changelog** - Add entries to CHANGELOG.md
6. **Regenerate README** - Update README.md dynamically
7. **Test Credentials** - Test HDFC Sky or Kotak Neo

## 💡 Pro Tip

Create a desktop shortcut or add to your PATH for even faster access:

```powershell
# Create a shortcut (right-click menu-only.ps1 → Create Shortcut)
# Or add to PATH for command-line access
```

## ⚠️ Important

- The menu **does NOT** automatically stop or restart services
- Options 1-5 will start services in **new windows** if they're not already running
- Options 6-10 are safe to use anytime (they don't affect running services)

