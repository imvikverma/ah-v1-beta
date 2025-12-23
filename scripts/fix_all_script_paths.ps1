# Fix All Script Paths
# Fixes path calculation issues in all scripts after folder reorganization

param(
    [switch]$DryRun = $false
)

Write-Host "=== FIXING ALL SCRIPT PATHS ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
$fixed = @()
$skipped = @()

# Function to get correct project root calculation code
function Get-ProjectRootCode {
    return @"
# Get project root (works from any location)
`$scriptPath = `$MyInvocation.MyCommand.Path
`$projectRoot = Split-Path -Parent `$scriptPath
`$maxDepth = 10
`$depth = 0

# Navigate up to find project root (look for .git or start-all.ps1)
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
"@
}

# Function to fix a script's path calculation
function Fix-ScriptPath {
    param(
        [string]$ScriptPath
    )
    
    $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $false
    }
    
    $originalContent = $content
    $modified = $false
    
    # Pattern 1: Split-Path -Parent (Split-Path -Parent ...) - assumes 2 levels
    if ($content -match "Split-Path\s+-Parent\s+\(Split-Path\s+-Parent") {
        # Replace with smart project root detection
        $projectRootCode = Get-ProjectRootCode
        $content = $content -replace '(?s)\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent[^`n]*', $projectRootCode
        $modified = $true
    }
    
    # Pattern 2: Hardcoded "scripts\" paths that should be relative
    if ($content -match 'scripts\\[^`"]*' -and $ScriptPath -like "*_local*") {
        # This is trickier - we'll note it but not auto-fix
        Write-Host "  ⚠️  Has hardcoded 'scripts\' path - manual review needed" -ForegroundColor Yellow
    }
    
    if ($modified -and -not $DryRun) {
        Set-Content -Path $ScriptPath -Value $content -Encoding UTF8
        return $true
    } elseif ($modified) {
        return $true
    }
    
    return $false
}

# Check scripts in _local/development/scripts/
Write-Host "1. Fixing scripts in _local/development/scripts/..." -ForegroundColor Yellow
Write-Host ""

$devScriptsPath = Join-Path $projectRoot "_local\development\scripts"
if (Test-Path $devScriptsPath) {
    $devScripts = Get-ChildItem $devScriptsPath -Filter "*.ps1" -File -Recurse
    foreach ($script in $devScripts) {
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        
        if (Fix-ScriptPath $script.FullName) {
            $fixed += $relativePath
            Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        } else {
            $skipped += $relativePath
        }
    }
}

# Check essential scripts in scripts/
Write-Host ""
Write-Host "2. Checking essential scripts in scripts/..." -ForegroundColor Yellow
Write-Host ""

$scriptsPath = Join-Path $projectRoot "scripts"
if (Test-Path $scriptsPath) {
    $scripts = Get-ChildItem $scriptsPath -Filter "*.ps1" -File
    foreach ($script in $scripts) {
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        
        # Check if it has path issues
        $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "Split-Path\s+-Parent\s+\(Split-Path\s+-Parent") {
            if (Fix-ScriptPath $script.FullName) {
                $fixed += $relativePath
                Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
            }
        } else {
            $skipped += $relativePath
        }
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

if ($fixed.Count -gt 0) {
    Write-Host "✅ Fixed $($fixed.Count) scripts:" -ForegroundColor Green
    foreach ($script in $fixed) {
        Write-Host "   - $script" -ForegroundColor White
    }
} else {
    Write-Host "ℹ️  No scripts needed fixing" -ForegroundColor Gray
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - No changes made. Run without -DryRun to fix scripts." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Script path fixes complete!" -ForegroundColor Green
}

