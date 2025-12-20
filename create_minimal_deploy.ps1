# AurumHarmony Minimal Deployment Package Creator
# Creates a small deployment package (< 25MB) with only essential files

param(
    [string]$OutputPath = "aurumharmony-minimal-deploy.zip"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "📦 AurumHarmony Minimal Deployment Creator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Remove existing file
if (Test-Path $OutputPath) {
    Write-Host "🗑️  Removing existing package..." -ForegroundColor Yellow
    Remove-Item $OutputPath -Force
}

Write-Host "📋 Creating minimal deployment package..." -ForegroundColor Gray

# Create a temporary directory with only essential files
$tempDir = Join-Path $env:TEMP "aurum_minimal_deploy"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy only essential directories and files
$essentialItems = @(
    "aurum_harmony\master_codebase",
    "aurum_harmony\admin_panel",
    "requirements.txt",
    "render.yaml",
    "wrangler.toml",
    "README.md",
    "CHANGELOG.md",
    "AurumHarmony_Intro.md",
    "AurumHarmony_Simple_Intro.md",
    "DEPLOYMENT_GUIDE.md"
)

foreach ($item in $essentialItems) {
    $sourcePath = Join-Path $projectRoot $item
    if (Test-Path $sourcePath) {
        $destPath = Join-Path $tempDir $item
        $destDir = Split-Path $destPath -Parent

        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if ((Get-Item $sourcePath) -is [System.IO.DirectoryInfo]) {
            # Copy directory
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Copied directory: $item" -ForegroundColor Green
        } else {
            # Copy file
            Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Copied file: $item" -ForegroundColor Green
        }
    }
}

# Calculate size before compression
$tempSize = (Get-ChildItem $tempDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
$tempSizeMB = [math]::Round($tempSize / 1MB, 2)
Write-Host "📊 Uncompressed size: $tempSizeMB MB" -ForegroundColor Cyan

# Create ZIP
Write-Host "📦 Compressing deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal -Force

# Cleanup
Remove-Item $tempDir -Recurse -Force

# Final size check
$finalSize = (Get-Item $OutputPath).Length
$finalSizeMB = [math]::Round($finalSize / 1MB, 2)

Write-Host ""
Write-Host "✅ Minimal deployment package created!" -ForegroundColor Green
Write-Host "📦 File: $OutputPath" -ForegroundColor Cyan
Write-Host "💾 Size: $finalSizeMB MB" -ForegroundColor Cyan

if ($finalSizeMB -gt 25) {
    Write-Host "⚠️  WARNING: File is still over 25MB limit!" -ForegroundColor Yellow
} else {
    Write-Host "✅ File is under 25MB limit - perfect for upload!" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Go to https://github.com/imvikverma/ah-v1-beta" -ForegroundColor White
Write-Host "2. Click 'Add file' → 'Upload files'" -ForegroundColor White
Write-Host "3. Upload this ZIP file" -ForegroundColor White
Write-Host "4. Commit with message: 'AurumHarmony v1.0 Production Release'" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Ready for minimal deployment!" -ForegroundColor Magenta
