# Setup Auto Venv Activation
# Configures PowerShell profile to auto-activate .venv when opening terminal

$ErrorActionPreference = "Continue"

# Get project root (works from any location)
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) { break }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) { break }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) { break }
    $projectRoot = $parent
    $depth++
}

$profilePath = $PROFILE.CurrentUserAllHosts

Write-Host "=== Setting Up Auto Venv Activation ===" -ForegroundColor Cyan
Write-Host ""

# Check if profile exists
if (-not (Test-Path $profilePath)) {
    Write-Host "Creating PowerShell profile..." -ForegroundColor Yellow
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "  ✅ Profile created at: $profilePath" -ForegroundColor Green
} else {
    Write-Host "Profile exists at: $profilePath" -ForegroundColor Gray
}

# Check if auto-activation code already exists
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

# Escape backslashes for PowerShell string
$projectRootEscaped = $projectRoot -replace '\\', '\\'

$activationCode = @"

# AurumHarmony Auto Venv Activation
# Auto-activates .venv when opening terminal in project directory
`$aurumHarmonyPath = "$projectRootEscaped"
if (`$PWD.Path -like "`$aurumHarmonyPath*") {
    `$venvPath = Join-Path `$aurumHarmonyPath ".venv\Scripts\Activate.ps1"
    if (Test-Path `$venvPath) {
        if (-not `$env:VIRTUAL_ENV) {
            & `$venvPath
            Write-Host "[AurumHarmony] Virtual environment activated" -ForegroundColor Green
        }
    }
}
"@

if ($profileContent -and $profileContent -match "AurumHarmony Auto Venv Activation") {
    Write-Host "⚠️  Auto-activation already configured in profile" -ForegroundColor Yellow
    Write-Host "   Skipping to avoid duplicates" -ForegroundColor Gray
} else {
    Write-Host "Adding auto-activation code to profile..." -ForegroundColor Yellow
    Add-Content -Path $profilePath -Value $activationCode -Encoding UTF8
    Write-Host "  ✅ Auto-activation configured!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Auto venv activation is now configured!" -ForegroundColor Green
Write-Host ""
Write-Host "How it works:" -ForegroundColor Yellow
Write-Host "  - When you open a new terminal in the project directory" -ForegroundColor Gray
Write-Host "  - PowerShell will automatically activate .venv" -ForegroundColor Gray
Write-Host "  - You'll see: [AurumHarmony] Virtual environment activated" -ForegroundColor Gray
Write-Host ""
Write-Host "To test:" -ForegroundColor Yellow
Write-Host "  1. Close this terminal" -ForegroundColor Gray
Write-Host "  2. Open a new terminal in the project directory" -ForegroundColor Gray
Write-Host "  3. Venv should auto-activate" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Make sure .venv\Scripts\Activate.ps1 exists" -ForegroundColor Yellow
Write-Host "      Run rebuild_flask_env.ps1 if needed" -ForegroundColor Yellow

