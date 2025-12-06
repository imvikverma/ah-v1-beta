# Git Rebase Troubleshooting Guide

## Why Git Commands Hang

Git commands can appear to "hang" when they're actually waiting for user input. This commonly happens during rebases when Git tries to open an editor for commit messages.

## Common Causes

1. **Editor Not Configured**: Git tries to open an editor but can't find one
2. **Editor Opens in Background**: Editor (vim/nano) opens but you don't see it
3. **Interactive Rebase**: Git is waiting for you to edit the rebase todo list
4. **Commit Message Prompt**: Git needs a commit message but editor isn't accessible

## Solutions

### 1. Set a Non-Interactive Editor (Recommended for Windows)

```powershell
# Use Notepad (opens in foreground)
git config --global core.editor "notepad.exe"

# Or use VS Code (if installed)
git config --global core.editor "code --wait"

# Or use PowerShell (for quick edits)
git config --global core.editor "powershell -Command \"& { Get-Content \$args[0] | Out-String | Set-Content \$args[0] }\""
```

### 2. Use Environment Variable (Temporary)

```powershell
# For current session only
$env:GIT_EDITOR = "notepad.exe"
git rebase --continue
```

### 3. Skip Editor Entirely (For Simple Cases)

```powershell
# Use --no-edit flag when continuing rebase
git rebase --continue --no-edit

# Or set environment variable
$env:GIT_EDITOR = "true"  # Does nothing, uses default message
```

### 4. Check What Git is Waiting For

```powershell
# Check if rebase is in progress
git status

# Check rebase todo list
git rebase --edit-todo

# See current commit being edited
git log --oneline -1
```

## Quick Fixes

### If Rebase is Stuck:

```powershell
# Option 1: Continue with default message (no editor)
$env:GIT_EDITOR = "true"
git rebase --continue

# Option 2: Abort and start fresh
git rebase --abort

# Option 3: Skip current commit
git rebase --skip
```

### If Editor Opens But You Can't See It:

1. Check Task Manager for `notepad.exe`, `vim.exe`, or `nano.exe`
2. Alt+Tab to find the editor window
3. Save and close the editor to continue

### For Interactive Rebase:

```powershell
# Edit the rebase todo list
git rebase --edit-todo

# If stuck, set editor first
$env:GIT_EDITOR = "notepad.exe"
git rebase --edit-todo
```

## Prevention

### Set Git Config Globally:

```powershell
# Always use Notepad (visible, easy to close)
git config --global core.editor "notepad.exe"

# Auto-stash changes during rebase
git config --global rebase.autoStash true

# Use merge strategy (alternative to rebase)
git config --global pull.rebase false
```

### Use Rebase Flags:

```powershell
# Continue without opening editor
git rebase --continue --no-edit

# Skip interactive mode
git rebase --no-verify
```

## Current Configuration

Check your current Git config:

```powershell
git config --list | Select-String "editor|rebase"
```

## Best Practices

1. **Always set an editor** you can see and use easily
2. **Use `--no-edit`** when you don't need to change commit messages
3. **Check `git status`** before running rebase commands
4. **Use `git rebase --abort`** if unsure what to do
5. **Commit or stash changes** before starting a rebase

---

**Note**: On Windows, `notepad.exe` is the safest choice as it always opens in the foreground and is easy to close.

