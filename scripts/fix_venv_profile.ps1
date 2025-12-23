# Fix Venv Auto-Activation Profile
# Updates the PowerShell profile with correct project root path

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

Write-Host "=== Fixing Venv Auto-Activation ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $profilePath)) {
    Write-Host "❌ Profile not found at: $profilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading profile..." -ForegroundColor Yellow
$profileContent = Get-Content $profilePath -Raw

# Check if old incorrect path exists
$oldPath = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\scripts"
$correctPath = $projectRoot

if ($profileContent -match [regex]::Escape($oldPath)) {
    Write-Host "⚠️  Found incorrect path in profile: $oldPath" -ForegroundColor Yellow
    Write-Host "   Fixing to: $correctPath" -ForegroundColor Yellow
    
    # Remove old AurumHarmony section
    $lines = Get-Content $profilePath
    $newLines = @()
    $skipSection = $false
    
    foreach ($line in $lines) {
        if ($line -match "AurumHarmony Auto Venv Activation") {
            $skipSection = $true
            continue
        }
        if ($skipSection -and ($line -match "^`$" -or $line -match "^#")) {
            # Check if this is the end of the section (empty line or new comment)
            if ($line -match "^`$" -and $newLines[-1] -match "AurumHarmony") {
                $skipSection = $false
                continue
            }
        }
        if ($skipSection) {
            continue
        }
        $newLines += $line
    }
    
    # Add corrected section
    $activationCode = @"

# AurumHarmony Auto Venv Activation
# Auto-activates .venv when opening terminal in project directory
`$aurumHarmonyPath = "$correctPath"
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
    $newLines += $activationCode -split "`r?`n"
    
    $newLines | Set-Content $profilePath -Encoding UTF8
    Write-Host "✅ Profile fixed!" -ForegroundColor Green
} elseif ($profileContent -match [regex]::Escape($correctPath)) {
    Write-Host "✅ Profile already has correct path" -ForegroundColor Green
} else {
    Write-Host "⚠️  AurumHarmony section not found in profile" -ForegroundColor Yellow
    Write-Host "   Adding activation code..." -ForegroundColor Yellow
    
    $activationCode = @"

# AurumHarmony Auto Venv Activation
# Auto-activates .venv when opening terminal in project directory
`$aurumHarmonyPath = "$correctPath"
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
    Add-Content -Path $profilePath -Value $activationCode -Encoding UTF8
    Write-Host "✅ Activation code added!" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Venv auto-activation fixed!" -ForegroundColor Green
Write-Host ""
Write-Host "To test:" -ForegroundColor Yellow
Write-Host "  1. Close this terminal" -ForegroundColor Gray
Write-Host "  2. Open a new terminal in project directory" -ForegroundColor Gray
Write-Host "  3. Venv should auto-activate" -ForegroundColor Gray
Write-Host ""

