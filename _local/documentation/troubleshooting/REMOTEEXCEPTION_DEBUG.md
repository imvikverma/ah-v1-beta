# RemoteException Debug Guide

**Issue:** PowerShell 7.5.4 `System.Management.Automation.RemoteException` when starting backend

**Status:** Multiple workarounds attempted, error persists

---

## Attempted Solutions

### 1. Batch File Wrapper ✅ Created
- File: `scripts\start_backend_wrapper.bat`
- Method: Use batch file to launch PowerShell
- Status: Still triggers RemoteException

### 2. cmd.exe via Start-Process ✅ Tried
- Method: Use cmd.exe to execute start command
- Status: Still triggers RemoteException

### 3. WMI Win32_Process.Create ✅ Implemented
- Method: Use WMI to create process directly
- Status: Test successful, but error may occur elsewhere

---

## Current Implementation

The `Start-Backend` function now uses WMI:

```powershell
$processClass = [WmiClass]"Win32_Process"
$startup = ([WmiClass]"Win32_ProcessStartup").CreateInstance()
$startup.ShowWindow = 7  # Minimized
$result = $processClass.Create($commandLine, $projectRoot, $startup)
```

This completely bypasses `Start-Process`.

---

## Possible Error Locations

1. **Script Loading:** Error during `start-all.ps1` parsing
2. **Function Definition:** Error when defining `Start-Backend`
3. **Function Call:** Error when calling `Start-Backend`
4. **Other Functions:** Error in `Start-Frontend` or `Invoke-BackendAndFrontend`

---

## Next Steps to Debug

1. **Check exact error location:**
   ```powershell
   # Add try-catch around function definition
   # Add try-catch around function call
   # Check error stack trace
   ```

2. **Test WMI method directly:**
   ```powershell
   $pwshPath = (Get-Command pwsh.exe).Source
   $scriptPath = Resolve-Path "scripts\start_backend_silent.ps1"
   $cmdLine = "`"$pwshPath`" -NoExit -ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""
   $processClass = [WmiClass]"Win32_Process"
   $startup = ([WmiClass]"Win32_ProcessStartup").CreateInstance()
   $startup.ShowWindow = 7
   $result = $processClass.Create($cmdLine, $PWD, $startup)
   ```

3. **Alternative: Use Start-Job (runs in background, no window)**
   ```powershell
   $job = Start-Job -ScriptBlock {
       Set-Location "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
       .\scripts\start_backend_silent.ps1
   }
   ```

4. **Alternative: Manual launch instruction**
   - Just tell user to manually run the script
   - Or create a simple .bat file they can double-click

---

## Quick Workaround

**For now, user can manually start backend:**

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
.\scripts\start_backend_silent.ps1
```

Or create a desktop shortcut to the batch wrapper.

---

**Last Updated:** 2025-12-13  
**Status:** Investigating

