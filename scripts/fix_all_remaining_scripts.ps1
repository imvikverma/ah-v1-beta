# Fix All Remaining Scripts with Path Issues
# Comprehensive fix for all scripts using old path calculation

$projectRoot = $PSScriptRoot
$fixed = @()
$errors = @()

# The replacement code
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

Write-Host "=== FIXING ALL REMAINING SCRIPTS ===" -ForegroundColor Cyan
Write-Host ""

# Pattern to match
$pattern = '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent\s+\$MyInvocation\.MyCommand\.Path\)'

# Fix scripts in _local/development/scripts/
Write-Host "1. Fixing scripts in _local/development/scripts/..." -ForegroundColor Yellow
Write-Host ""

$devScriptsPath = Join-Path $projectRoot "_local\development\scripts"
if (Test-Path $devScriptsPath) {
    $devScripts = Get-ChildItem $devScriptsPath -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue
    foreach ($script in $devScripts) {
        try {
            $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match $pattern) {
                $newContent = $content -replace $pattern, $replacementCode
                Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8 -NoNewline
                $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
                Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
                $fixed += $relativePath
            }
        } catch {
            $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
            $errors += "$relativePath - $($_.Exception.Message)"
            Write-Host "  ❌ Error fixing: $relativePath" -ForegroundColor Red
        }
    }
}

# Fix scripts in scripts/
Write-Host ""
Write-Host "2. Fixing scripts in scripts/..." -ForegroundColor Yellow
Write-Host ""

$scriptsPath = Join-Path $projectRoot "scripts"
if (Test-Path $scriptsPath) {
    $scripts = Get-ChildItem $scriptsPath -Filter "*.ps1" -File -ErrorAction SilentlyContinue
    foreach ($script in $scripts) {
        try {
            $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match $pattern) {
                $newContent = $content -replace $pattern, $replacementCode
                Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8 -NoNewline
                $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
                Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
                $fixed += $relativePath
            }
        } catch {
            $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
            $errors += "$relativePath - $($_.Exception.Message)"
            Write-Host "  ❌ Error fixing: $relativePath" -ForegroundColor Red
        }
    }
}

# Summary
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

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Errors ($($errors.Count)):" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Script path fixes complete!" -ForegroundColor Green

