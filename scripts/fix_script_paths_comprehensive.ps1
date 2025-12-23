# Comprehensive Script Path Fixer
# Fixes all scripts with path calculation issues

$projectRoot = $PSScriptRoot
$fixedCount = 0
$checkedCount = 0

# The correct project root detection code
$projectRootCode = @'
# Get project root (works from any location)
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0

# Navigate up to find project root (look for .git or start-all.ps1)
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) {
        break
    }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) {
        break
    }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) {
        break
    }
    $projectRoot = $parent
    $depth++
}
'@

Write-Host "=== FIXING SCRIPT PATHS ===" -ForegroundColor Cyan
Write-Host ""

# Fix scripts in _local/development/scripts/
Write-Host "1. Fixing scripts in _local/development/scripts/..." -ForegroundColor Yellow
$devScripts = Get-ChildItem "$projectRoot\_local\development\scripts" -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue
foreach ($script in $devScripts) {
    $checkedCount++
    $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent') {
        $newContent = $content -replace '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent[^\r\n]*', $projectRootCode
        Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        $fixedCount++
    }
}

# Fix scripts in scripts/ (essential scripts)
Write-Host ""
Write-Host "2. Fixing scripts in scripts/..." -ForegroundColor Yellow
$scripts = Get-ChildItem "$projectRoot\scripts" -Filter "*.ps1" -File -ErrorAction SilentlyContinue
foreach ($script in $scripts) {
    $checkedCount++
    $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent') {
        $newContent = $content -replace '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent[^\r\n]*', $projectRootCode
        Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        $fixedCount++
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "  Checked: $checkedCount scripts" -ForegroundColor White
Write-Host "  Fixed: $fixedCount scripts" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Script path fixes complete!" -ForegroundColor Green

