# Check Scripts Integrity
# Verifies all scripts for path issues, corruption, and common problems

param(
    [switch]$Fix = $false
)

Write-Host "=== CHECKING SCRIPTS INTEGRITY ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
$issues = @()
$fixed = @()

# Function to get correct project root from any script location
function Get-ProjectRoot {
    param([string]$ScriptPath)
    
    $currentPath = $ScriptPath
    $maxDepth = 10
    $depth = 0
    
    while ($depth -lt $maxDepth) {
        if (Test-Path (Join-Path $currentPath ".git")) {
            return $currentPath
        }
        if (Test-Path (Join-Path $currentPath "start-all.ps1")) {
            return $currentPath
        }
        $parent = Split-Path -Parent $currentPath
        if ($parent -eq $currentPath) {
            break
        }
        $currentPath = $parent
        $depth++
    }
    
    # Fallback: assume script is in _local/development/scripts/ or scripts/
    if ($ScriptPath -like "*_local\development\scripts*") {
        return Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptPath)))
    } elseif ($ScriptPath -like "*scripts*") {
        return Split-Path -Parent $ScriptPath
    }
    
    return $projectRoot
}

# Check scripts in scripts/ folder
Write-Host "1. Checking scripts/ folder..." -ForegroundColor Yellow
Write-Host ""

$scriptsPath = Join-Path $projectRoot "scripts"
if (Test-Path $scriptsPath) {
    $scripts = Get-ChildItem $scriptsPath -Filter "*.ps1" -File
    foreach ($script in $scripts) {
        $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            $issues += "❌ $($script.Name) - File is empty or unreadable"
            continue
        }
        
        # Check for common path issues
        $scriptProjectRoot = Get-ProjectRoot $script.FullName
        
        # Check for hardcoded paths
        if ($content -match "scripts\\[^`"]*" -and $content -notmatch "Get-ProjectRoot|PSScriptRoot") {
            $issues += "⚠️  $($script.Name) - May have hardcoded 'scripts\' path"
        }
        
        # Check for relative path calculations
        if ($content -match "Split-Path.*Parent.*Split-Path.*Parent" -and $script.FullName -like "*_local*") {
            $issues += "⚠️  $($script.Name) - Path calculation may be wrong (moved to _local/)"
        }
        
        # Check for syntax errors
        $syntaxErrors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$syntaxErrors)
        if ($syntaxErrors) {
            $issues += "❌ $($script.Name) - Syntax errors detected"
        }
    }
    Write-Host "   Checked $($scripts.Count) scripts" -ForegroundColor Gray
}

# Check scripts in _local/development/scripts/
Write-Host ""
Write-Host "2. Checking _local/development/scripts/ folder..." -ForegroundColor Yellow
Write-Host ""

$devScriptsPath = Join-Path $projectRoot "_local\development\scripts"
if (Test-Path $devScriptsPath) {
    $devScripts = Get-ChildItem $devScriptsPath -Filter "*.ps1" -File -Recurse
    foreach ($script in $devScripts) {
        $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            $issues += "❌ $($script.Name) - File is empty or unreadable"
            continue
        }
        
        # Check for path calculation issues
        if ($content -match "Split-Path.*Parent.*Split-Path.*Parent" -and $content -notmatch "Get-ProjectRoot") {
            $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
            $issues += "⚠️  $relativePath - Path calculation may be wrong (4 levels deep now)"
        }
        
        # Check for hardcoded 'scripts\' references
        if ($content -match "scripts\\[^`"]*" -and $content -notmatch "Get-ProjectRoot|PSScriptRoot") {
            $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
            $issues += "⚠️  $relativePath - May have hardcoded 'scripts\' path"
        }
    }
    Write-Host "   Checked $($devScripts.Count) scripts" -ForegroundColor Gray
}

# Fix fix_venv_activation.ps1 specifically
Write-Host ""
Write-Host "3. Fixing fix_venv_activation.ps1..." -ForegroundColor Yellow
Write-Host ""

$fixVenvPath = Join-Path $projectRoot "_local\development\scripts\fix_venv_activation.ps1"
if (Test-Path $fixVenvPath) {
    $content = Get-Content $fixVenvPath -Raw
    $newContent = @"
# Fix Virtual Environment Activation
# Use this script to ensure you're using the correct .venv

# Get project root (works from any location)
`$scriptPath = `$MyInvocation.MyCommand.Path
`$projectRoot = `$PSScriptRoot
`$maxDepth = 10
`$depth = 0

while (`$depth -lt `$maxDepth) {
    if (Test-Path (Join-Path `$projectRoot ".git")) {
        break
    }
    if (Test-Path (Join-Path `$projectRoot "start-all.ps1")) {
        break
    }
    `$parent = Split-Path -Parent `$projectRoot
    if (`$parent -eq `$projectRoot) {
        break
    }
    `$projectRoot = `$parent
    `$depth++
}

Set-Location `$projectRoot

Write-Host "`n=== Fixing Virtual Environment Activation ===" -ForegroundColor Cyan
Write-Host ""

# Check current activation
if (`$env:VIRTUAL_ENV) {
    Write-Host "Current venv: `$env:VIRTUAL_ENV" -ForegroundColor Yellow
    
    if (`$env:VIRTUAL_ENV -match "backup") {
        Write-Host "[WARN] Backup venv is activated!" -ForegroundColor Red
        Write-Host "Deactivating..." -ForegroundColor Yellow
        deactivate
        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "[INFO] Deactivating current venv..." -ForegroundColor Gray
        deactivate
        Start-Sleep -Milliseconds 500
    }
} else {
    Write-Host "[INFO] No venv currently activated" -ForegroundColor Gray
}

# Activate correct .venv
`$correctVenv = Join-Path `$projectRoot ".venv\Scripts\Activate.ps1"

if (Test-Path `$correctVenv) {
    Write-Host "Activating correct .venv..." -ForegroundColor Green
    & `$correctVenv
    
    Start-Sleep -Milliseconds 500
    
    # Verify
    if (`$env:VIRTUAL_ENV -eq (Join-Path `$projectRoot ".venv")) {
        Write-Host "[OK] Correct venv activated!" -ForegroundColor Green
        Write-Host "   Path: `$env:VIRTUAL_ENV" -ForegroundColor Gray
        
        # Verify Python version
        `$pyVersion = python --version 2>&1
        Write-Host "   Python: `$pyVersion" -ForegroundColor Gray
        
        # Verify Flask
        `$flaskVersion = pip show Flask 2>&1 | Select-String "Version:"
        if (`$flaskVersion) {
            Write-Host "   `$flaskVersion" -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Failed to activate correct venv" -ForegroundColor Red
        Write-Host "   Current: `$env:VIRTUAL_ENV" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] Correct venv not found at: `$correctVenv" -ForegroundColor Red
    Write-Host "   Run .\rebuild_flask_env.ps1 to create it" -ForegroundColor Yellow
}

Write-Host ""
"@
    
    if ($Fix) {
        Set-Content -Path $fixVenvPath -Value $newContent -Encoding UTF8
        $fixed += "✅ Fixed: fix_venv_activation.ps1"
        Write-Host "   ✅ Fixed fix_venv_activation.ps1" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Would fix: fix_venv_activation.ps1" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "✅ No issues found!" -ForegroundColor Green
} else {
    Write-Host "Found $($issues.Count) potential issues:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "  $issue" -ForegroundColor White
    }
}

if ($fixed.Count -gt 0) {
    Write-Host ""
    Write-Host "Fixed scripts:" -ForegroundColor Green
    foreach ($fix in $fixed) {
        Write-Host "  $fix" -ForegroundColor White
    }
}

if (-not $Fix -and $issues.Count -gt 0) {
    Write-Host ""
    Write-Host "Run with -Fix to automatically fix issues" -ForegroundColor Yellow
}

