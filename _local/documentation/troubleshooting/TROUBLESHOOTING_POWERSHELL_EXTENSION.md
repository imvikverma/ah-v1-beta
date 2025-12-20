# PowerShell Extension Error Fix

## Error: `connect ENOENT \\.\pipe\PSES_...`

This error occurs when the PowerShell Extension Server (PSES) in Cursor/VS Code can't connect to its language server.

## Quick Solutions (Try in Order)

### 1. Reload Cursor Window
- Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
- Type: `Developer: Reload Window`
- Press Enter

### 2. Restart PowerShell Extension
- Press `Ctrl+Shift+P`
- Type: `PowerShell: Restart Extension`
- Press Enter

### 3. Restart Cursor Completely
- Close all Cursor windows
- Reopen Cursor
- The extension should reconnect automatically

### 4. Check PowerShell Extension Status
- Open Extensions (`Ctrl+Shift+X`)
- Search for "PowerShell"
- Ensure it's installed and enabled
- If disabled, click "Enable"

### 5. Clear Extension Cache (Last Resort)
- Close Cursor
- Delete: `%APPDATA%\Cursor\User\workspaceStorage\`
- Reopen Cursor

## Important Note

**This error does NOT prevent you from running PowerShell scripts!**

You can always run scripts directly in a terminal:

```powershell
# Run the main launcher
.\start-all.ps1

# Or run backend directly
.\scripts\start_backend_direct.ps1
```

The extension error only affects:
- IntelliSense/autocomplete
- Syntax highlighting (sometimes)
- Code navigation features

**Script execution works fine without the extension!**

## If Error Persists

The extension error is usually harmless. If you need IntelliSense:
1. Check PowerShell extension version (update if needed)
2. Check if multiple PowerShell processes are running (Task Manager)
3. Restart your computer (clears all named pipes)

But for running scripts, you don't need the extension to work.

