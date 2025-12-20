# Git Non-Interactive Helper
# Sets environment variables to prevent Git from hanging on editor prompts

# Set editor to "true" (does nothing, uses default messages)
$env:GIT_EDITOR = "true"

# Alternative: Use notepad (visible, easy to close)
# $env:GIT_EDITOR = "notepad.exe"

# Disable interactive prompts
$env:GIT_TERMINAL_PROMPT = "0"

Write-Host "Git non-interactive mode enabled" -ForegroundColor Green
Write-Host "GIT_EDITOR = $env:GIT_EDITOR" -ForegroundColor Cyan

# Run the provided git command
if ($args.Count -gt 0) {
    $command = $args -join " "
    Write-Host "Running: git $command" -ForegroundColor Yellow
    Invoke-Expression "git $command"
} else {
    Write-Host "Usage: .\git-non-interactive.ps1 <git-command>" -ForegroundColor Yellow
    Write-Host "Example: .\git-non-interactive.ps1 rebase --continue" -ForegroundColor Gray
}

