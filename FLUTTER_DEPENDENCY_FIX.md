# Flutter Dependency Fix Guide

## Issue
Flutter dependency installation failed with:
1. File permission error - Can't delete `windows\flutter\ephemeral\.plugin_symlinks`
2. Dependency version conflicts

## Solution Steps

### 1. Fix File Permissions (Run as Administrator)
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"

# Remove problematic directory
if (Test-Path "windows\flutter\ephemeral\.plugin_symlinks") {
    Remove-Item -Path "windows\flutter\ephemeral\.plugin_symlinks" -Recurse -Force
}

# Clean Flutter build
flutter clean
```

### 2. Fix Dependency Versions
Updated `pubspec.yaml`:
- `vibration: ^1.9.0` (was 1.8.4, updated to match resolved version)

### 3. Reinstall Dependencies
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony\frontend\flutter_app"
flutter pub get
```

### 4. If Still Failing - Manual Cleanup
```powershell
# Stop any running Flutter processes
Get-Process | Where-Object {$_.ProcessName -like "*flutter*"} | Stop-Process -Force

# Remove build directories
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue

# Reinstall
flutter pub get
```

### 5. Alternative: Use Compatible Versions
If dependency conflicts persist, you can lock to specific versions:
```yaml
dependencies:
  lottie: 2.7.0  # Remove ^ to lock version
  confetti: 0.7.0
  vibration: 1.9.0
```

## Notes
- The error shows packages were updated but some have newer incompatible versions
- This is normal - Flutter resolved compatible versions
- The main issue is the file permission error preventing cleanup
- Run PowerShell as Administrator if permission errors persist

