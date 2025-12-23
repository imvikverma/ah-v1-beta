# Final Comprehensive Path Fix
# Fixes all scripts with old path calculation

$projectRoot = $PSScriptRoot
$fixed = @()

$replacementCode = @'
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
'@

Write-Host "=== FIXING ALL SCRIPT PATHS ===" -ForegroundColor Cyan
Write-Host ""

# Function to fix a single script
function Fix-Script {
    param([string]$ScriptPath)
    
    try {
        $content = Get-Content $ScriptPath -Raw -ErrorAction Stop
        
        # Multiple patterns to match
        $patterns = @(
            '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent\s+\$MyInvocation\.MyCommand\.Path\)',
            '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent\s+\$MyInvocation',
            'Split-Path\s+-Parent\s+\(Split-Path\s+-Parent\s+\$MyInvocation'
        )
        
        $modified = $false
        foreach ($pattern in $patterns) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $replacementCode
                $modified = $true
                break
            }
        }
        
        if ($modified) {
            Set-Content -Path $ScriptPath -Value $content -Encoding UTF8 -NoNewline
            return $true
        }
        return $false
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fix scripts in _local/development/scripts/
Write-Host "1. Fixing scripts in _local/development/scripts/..." -ForegroundColor Yellow
$devScripts = Get-ChildItem "$projectRoot\_local\development\scripts" -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue
foreach ($script in $devScripts) {
    if (Fix-Script $script.FullName) {
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        $fixed += $relativePath
    }
}

# Fix scripts in scripts/
Write-Host ""
Write-Host "2. Fixing scripts in scripts/..." -ForegroundColor Yellow
$scripts = Get-ChildItem "$projectRoot\scripts" -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue
foreach ($script in $scripts) {
    if (Fix-Script $script.FullName) {
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        $fixed += $relativePath
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "  ✅ Fixed $($fixed.Count) scripts" -ForegroundColor Green
if ($fixed.Count -gt 0) {
    Write-Host ""
    Write-Host "Fixed scripts:" -ForegroundColor Yellow
    foreach ($script in $fixed) {
        Write-Host "   - $script" -ForegroundColor White
    }
}
Write-Host ""
Write-Host "✅ All script paths fixed!" -ForegroundColor Green

