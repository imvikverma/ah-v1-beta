# AurumHarmony Auto-Refresh Firefox Extension

This Firefox extension enables automatic hard refresh of monitored tabs, bypassing cross-origin restrictions that prevent the HTML-based auto-refresh tool from working.

## Features

- ✅ **Auto-refresh monitored tabs** at configurable intervals (10-300 seconds)
- ✅ **Bypass cross-origin restrictions** - can refresh any tab, regardless of origin
- ✅ **Hard refresh** - bypasses browser cache
- ✅ **Track monitored tabs** - automatically opens and monitors Cloudflare Pages, Dashboard, and GitHub
- ✅ **Manual refresh** - refresh all tabs on demand
- ✅ **Persistent settings** - remembers your preferences

## Installation

### Method 1: Temporary Installation (Development)

1. Open Firefox
2. Navigate to `about:debugging`
3. Click "This Firefox" in the left sidebar
4. Click "Load Temporary Add-on..."
5. Navigate to the `scripts/firefox_extension/` folder
6. Select `manifest.json`
7. The extension is now loaded!

### Method 2: Permanent Installation (Recommended)

1. Open Firefox
2. Navigate to `about:debugging`
3. Click "This Firefox" in the left sidebar
4. Click "Load Temporary Add-on..."
5. Navigate to the `scripts/firefox_extension/` folder
6. Select `manifest.json`
7. Click the gear icon next to the extension
8. Click "Make Permanent" (if available)

**Note:** For permanent installation, you may need to package the extension as an `.xpi` file and sign it, or use Firefox Developer Edition.

## Usage

1. **Click the extension icon** in the Firefox toolbar
2. **Set your refresh interval** (default: 30 seconds)
3. **Click "▶ Start"** to begin auto-refreshing
4. **Click "🔄 Refresh Now"** to manually refresh all monitored tabs
5. **Click "⏸ Stop"** to pause auto-refresh

## Monitored Tabs

By default, the extension monitors:
- **Cloudflare Pages**: `https://ah.saffronbolt.in`
- **Cloudflare Dashboard**: `https://dash.cloudflare.com/.../pages/view/ah-v1-beta`
- **GitHub Repository**: `https://github.com/imvikverma/ah-v1-beta`

These tabs will be automatically opened when you start auto-refresh (if not already open).

## Configuration

You can modify the monitored tabs by editing `background.js`:

```javascript
const DEFAULT_TABS = [
  {
    id: 'cloudflare-pages',
    label: 'Cloudflare Pages',
    url: 'https://ah.saffronbolt.in'
  },
  // Add more tabs here...
];
```

## Troubleshooting

### Extension not loading
- Make sure you're using Firefox (not Chrome/Edge)
- Check that `manifest.json` is valid JSON
- Look for errors in `about:debugging` → "This Firefox" → "Inspect"

### Tabs not refreshing
- Check that auto-refresh is enabled (status shows "Running")
- Verify that monitored tabs are open
- Check the browser console for errors (F12)

### Permission errors
- The extension needs `tabs` and `<all_urls>` permissions
- These are requested automatically when you load the extension

## Development

To modify the extension:

1. Edit files in `scripts/firefox_extension/`
2. Reload the extension in `about:debugging`
3. Test your changes

## Files

- `manifest.json` - Extension manifest (permissions, scripts, etc.)
- `background.js` - Background script (handles tab management and refresh logic)
- `content.js` - Content script (injected into pages for refresh functionality)
- `popup.html` - Extension popup UI
- `popup.js` - Popup script (handles UI interactions)
- `README.md` - This file

## Icons

The extension uses placeholder icons. To add custom icons:

1. Create `icons/` folder
2. Add `icon16.png`, `icon48.png`, `icon128.png`
3. Update `manifest.json` if needed

## License

Part of the AurumHarmony project.

