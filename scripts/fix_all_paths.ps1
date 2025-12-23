# Fix All Script Paths - Comprehensive Fix
# Fixes the path calculation issue in all scripts

$projectRoot = $PSScriptRoot
$fixed = @()

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

Write-Host "=== FIXING ALL SCRIPT PATHS ===" -ForegroundColor Cyan
Write-Host ""

# Fix scripts in _local/development/scripts/
$devScripts = Get-ChildItem "$projectRoot\_local\development\scripts" -Filter "*.ps1" -File -Recurse -ErrorAction SilentlyContinue
Write-Host "Found $($devScripts.Count) scripts in _local/development/scripts/" -ForegroundColor Gray

foreach ($script in $devScripts) {
    $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent') {
        $newContent = $content -replace '(?s)\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent[^\r\n]*', $replacementCode
        Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8
        $relativePath = $script.FullName.Replace($projectRoot, "").TrimStart("\")
        Write-Host "  ✅ Fixed: $relativePath" -ForegroundColor Green
        $fixed += $relativePath
    }
}

# Fix scripts in scripts/
$scripts = Get-ChildItem "$projectRoot\scripts" -Filter "*.ps1" -File -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Found $($scripts.Count) scripts in scripts/" -ForegroundColor Gray

foreach ($script in $scripts) {
    $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match '\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent') {
        $newContent = $content -replace '(?s)\$projectRoot\s*=\s*Split-Path\s+-Parent\s+\(Split-Path\s+-Parent[^\r\n]*', $replacementCode
        Set-Content -Path $script.FullName -Value $newContent -Encoding UTF8
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
        Write-Host "  - $script" -ForegroundColor White
    }
}
Write-Host ""
Write-Host "✅ All script paths fixed!" -ForegroundColor Green

