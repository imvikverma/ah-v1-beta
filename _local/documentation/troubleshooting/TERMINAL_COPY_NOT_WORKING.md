# Terminal Copy/Selection Not Working - Complete Workaround Guide

**Date:** December 13, 2025  
**Issue:** Terminal selection and copy (Ctrl+C) not working in Cursor IDE

---

## Problem

- ❌ Cannot select terminal text
- ❌ Ctrl+C doesn't copy selected text
- ❌ Right-click copy doesn't work
- ❌ "Send to Chat" feature not available

This is a terminal integration issue in Cursor IDE.

---

## ✅ Solution: Automated Output Capture

Since manual selection/copy doesn't work, use these automated methods:

### Method 1: Use Helper Scripts

#### Quick Share Script:
```powershell
.\scripts\quick_share_output.ps1 "git status"
```

This will:
- Run the command
- Save output to `_local\logs\share_TIMESTAMP.txt`
- Show you the file path
- You can then use `@file:_local\logs\share_TIMESTAMP.txt` in chat

#### Capture Script:
```powershell
.\scripts\capture_terminal_output.ps1 -Command "git status"
```

### Method 2: Direct PowerShell Redirection

For any command, redirect output to a file:

```powershell
# Single command
git status > _local\logs\output.txt

# With errors too
git status 2>&1 | Out-File "_local\logs\output.txt"

# Append to file
git status 2>&1 | Out-File "_local\logs\output.txt" -Append
```

### Method 3: Tee-Object (See Output AND Save)

```powershell
git status | Tee-Object -FilePath "_local\logs\output.txt"
```

This shows output in terminal AND saves to file.

---

## Common Commands with Output Capture

### Git Status:
```powershell
git status 2>&1 | Out-File "_local\logs\git_status.txt"
```

### Run Script and Capture:
```powershell
.\scripts\fix_gitignore_tracking.ps1 2>&1 | Out-File "_local\logs\fix_output.txt"
```

### PowerShell Command:
```powershell
Get-ChildItem -Recurse | Out-File "_local\logs\file_list.txt"
```

---

## Sharing Output in Chat

Once output is saved to a file:

1. **Use @file syntax:**
   ```
   @file:_local\logs\output.txt
   ```

2. **Or just mention the file:**
   ```
   Check _local\logs\output.txt for the results
   ```

3. **Or paste file contents manually:**
   - Open the file in Cursor
   - Select all (Ctrl+A)
   - Copy (Ctrl+C)
   - Paste in chat

---

## Quick Reference

| What You Want | Command |
|--------------|---------|
| Capture git status | `git status 2>&1 \| Out-File "_local\logs\git.txt"` |
| Capture script output | `.\script.ps1 2>&1 \| Out-File "_local\logs\script.txt"` |
| Capture with display | `.\script.ps1 \| Tee-Object -FilePath "_local\logs\script.txt"` |
| Quick share helper | `.\scripts\quick_share_output.ps1 "your-command"` |

---

## Troubleshooting Terminal Issues

### Check Terminal Type:
```powershell
$PSVersionTable
```

### Try Different Terminal:
- Switch between PowerShell, CMD, Git Bash
- Settings → Terminal → Default Profile

### Check Cursor Settings:
- Settings → Terminal → Copy on Select (try enabling/disabling)
- Settings → Terminal → Right Click Behavior

### Restart Terminal:
- Close terminal panel
- Open new terminal (Ctrl+`)
- Or restart Cursor completely

---

## Alternative: Use File Explorer

If terminal is completely broken:

1. Navigate to `_local\logs\` in file explorer
2. Create a text file manually
3. Copy-paste terminal output (if you can see it)
4. Save and reference in chat

---

## Status

**Workaround Available:** ✅ Yes (automated file capture)  
**Manual Copy:** ❌ Not working  
**Priority:** Medium (workarounds are sufficient for development)

---

## Next Steps

1. Use `quick_share_output.ps1` for quick captures
2. Use `Out-File` for one-off commands
3. Reference files using `@file:` syntax in chat
4. Report the terminal issue to Cursor support

---

## Example Workflow

```powershell
# 1. Run command and capture
.\scripts\fix_gitignore_tracking.ps1 2>&1 | Out-File "_local\logs\fix_result.txt"

# 2. Check if file was created
Test-Path "_local\logs\fix_result.txt"

# 3. Share in chat:
# @file:_local\logs\fix_result.txt
```

This workflow completely bypasses the terminal selection issue!

