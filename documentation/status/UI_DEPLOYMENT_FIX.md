# UI Deployment Fix - Persistent Old Design Issue

**Date:** 2025-12-06  
**Status:** 🔧 In Progress

## Problem

The Flutter web app is stuck between old and new designs:
- API key and Secret dialog boxes show up after login (should only show on button click)
- Recent UI changes (logo, theme toggle, simplified login) not appearing
- Old design elements still visible

## Root Causes Identified

### 1. ApiKeyDialog Bug
- **Issue:** `ApiKeyDialog` was calling `AuthService.login()` with non-existent parameters (`userId`, `apiKey`, `apiSecret`)
- **Fix:** Changed to save credentials directly to SharedPreferences
- **File:** `aurum_harmony/frontend/flutter_app/lib/widgets/api_key_dialog.dart`

### 2. Build Cache Issue
- **Issue:** Old build files in `docs/` directory
- **Last Build:** Dec 6, 2025 12:46:44
- **Fix Needed:** Clean rebuild and force deployment

### 3. Browser Cache
- **Issue:** Browsers may be serving cached JavaScript files
- **Fix Needed:** Hard refresh, clear cache, or use incognito mode

## Fixes Applied

### ✅ Fix 1: ApiKeyDialog Save Method
**Changed:**
```dart
// OLD (broken):
await AuthService.login(
  userId: userId,
  apiKey: _apiKeyController.text.trim(),
  apiSecret: _apiSecretController.text.trim(),
);

// NEW (fixed):
final prefs = await SharedPreferences.getInstance();
await prefs.setString('api_key', _apiKeyController.text.trim());
await prefs.setString('api_secret', _apiSecretController.text.trim());
```

### ✅ Fix 2: Added Missing Import
Added `import 'package:shared_preferences/shared_preferences.dart';` to `api_key_dialog.dart`

## Next Steps

1. **Clean Flutter Build**
   ```powershell
   cd aurum_harmony\frontend\flutter_app
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Copy to docs/**
   ```powershell
   cd ..\..\..
   Remove-Item -Recurse -Force docs
   New-Item -ItemType Directory -Path docs
   Copy-Item -Recurse "aurum_harmony\frontend\flutter_app\build\web\*" -Destination "docs\"
   ```

3. **Commit and Push**
   ```powershell
   git add docs/
   git commit -m "fix: Update Flutter build - fix ApiKeyDialog and UI changes"
   git push origin main
   ```

4. **Clear Browser Cache**
   - Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
   - Or use incognito/private browsing mode
   - Or clear browser cache completely

5. **Verify Deployment**
   - Check: https://ah.saffronbolt.in
   - Should see: Logo on login, theme toggle, no auto API dialog

## Verification Checklist

- [ ] Logo appears on login screen (not "AurumHarmony" text)
- [ ] Theme toggle button visible in AppBar
- [ ] Simplified login (email/phone + password only)
- [ ] API key dialog only shows when clicking key icon (not automatically)
- [ ] Theme-aware colors throughout app
- [ ] No old design elements visible

## Files Modified

1. `aurum_harmony/frontend/flutter_app/lib/widgets/api_key_dialog.dart`
   - Fixed `_handleSave()` method
   - Added SharedPreferences import
   - Changed to save credentials directly

## Notes

- The dialog should only appear when user clicks the key icon in AppBar
- No automatic triggers found in codebase
- If dialog still appears automatically, check browser console for errors
- May need to clear browser localStorage/SharedPreferences if old data persists

---

**Next Action:** Clean rebuild and deploy

