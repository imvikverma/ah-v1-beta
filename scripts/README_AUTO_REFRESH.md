# Firefox Auto-Refresh & Force Deploy Tools for AurumHarmony

After deploying to Cloudflare Pages, browser caching can prevent you from seeing updates immediately. Use these tools to automatically refresh multiple tabs (GitHub, Cloudflare) and trigger force deployments.

## Option 1: Enhanced HTML Tool (Recommended)

**Location:** `scripts/firefox_auto_refresh.html`

### How to Use:
1. Open `scripts/firefox_auto_refresh.html` in Firefox
2. Click "▶ Start Auto-Refresh" to open all monitored tabs (Cloudflare, GitHub, Cloudflare Dashboard)
3. Tabs will automatically hard refresh every 30 seconds
4. Use "🔄 Hard Refresh All Tabs" to manually refresh all tabs immediately
5. Use "🚀 Force Deploy" to see instructions for triggering deployment

### Features:
- ✅ **Multi-tab monitoring** (Cloudflare Pages, GitHub, Cloudflare Dashboard)
- ✅ **Hard refresh** (bypasses browser cache with multiple fallback methods)
- ✅ **Force deploy instructions** (shows how to run PowerShell deployment script)
- ✅ **Auto-refresh** (automatically refreshes all tabs every 30 seconds)
- ✅ **Visual status** (shows which tabs are open/closed)
- ✅ **Refresh counter** and countdown timer

## Option 2: Bookmarklet (Quick & Simple)

**Location:** `scripts/firefox_auto_refresh_bookmarklet.js`

### How to Set Up:
1. Copy the entire code from `firefox_auto_refresh_bookmarklet.js`
2. In Firefox, right-click your bookmarks toolbar → **New Bookmark**
3. Name it: `AH Auto-Refresh`
4. Paste the code into the **Location** field
5. Save

### How to Use:
1. Navigate to `https://ah.saffronbolt.in` (or your target URL)
2. Click the bookmarklet to start auto-refreshing every 30 seconds
3. Click again to stop

## Option 3: Manual Hard Refresh

**Keyboard Shortcuts:**
- **Windows/Linux:** `Ctrl + Shift + R` or `Ctrl + F5`
- **Mac:** `Cmd + Shift + R`

This bypasses the browser cache for the current page.

## Why Use Auto-Refresh?

1. **Cloudflare Pages Deployment:** Takes 1-3 minutes to propagate
2. **Browser Caching:** Browsers cache static assets aggressively
3. **Cache-Busting:** The deployment script now adds build timestamps, but you still need to refresh to see changes

## Best Practice Workflow

### Force Deploy & Hard Refresh:
1. Open `scripts/firefox_auto_refresh.html` in Firefox
2. Click "🚀 Force Deploy" to see deployment instructions
3. Run the PowerShell script shown (or use `start-all.ps1` → Option 5)
4. Click "▶ Start Auto-Refresh" to open and monitor tabs
5. Wait 1-3 minutes for Cloudflare to build
6. Click "🔄 Hard Refresh All Tabs" to see changes immediately
7. Or let auto-refresh catch the changes automatically

### Quick Deploy Options:
- **Quick:** `.\scripts\trigger_deploy.ps1`
- **Menu:** `.\start-all.ps1` → Option 5
- **Direct:** `.\scripts\deploy_cloudflare.ps1 -Force`

## Troubleshooting

**Changes still not showing?**
- Check Cloudflare Pages dashboard for deployment status
- Try increasing refresh interval to 60 seconds
- Verify the commit was pushed successfully
- Check browser console for errors

**Bookmarklet not working?**
- Ensure popups are allowed
- Check browser console for errors
- Try the standalone HTML tool instead

