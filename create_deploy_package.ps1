# AurumHarmony Deployment Package Creator
# This script creates a clean ZIP file for manual GitHub upload

param(
    [string]$OutputPath = "aurumharmony-deploy.zip"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "📦 AurumHarmony Deployment Package Creator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$excludePatterns = @(
    "*.log",
    ".git",
    "__pycache__",
    "*.pyc",
    ".env*",
    "node_modules",
    ".DS_Store",
    "Thumbs.db",
    "*.tmp",
    "temp",
    "tmp",
    "_local",
    ".venv",
    "*.zip",
    "*.exe",
    "*.dll",
    "*.pdb",
    "*.nupkg",
    "*.msi",
    "*.dmg",
    "*.pkg",
    "*.deb",
    "*.rpm",
    "*.tar.gz",
    "*.tgz",
    "*.7z",
    "*.rar",
    "*.iso",
    "*.img",
    "*.vhd",
    "*.vhdx",
    "*.vmdk",
    "*.ova",
    "*.ovf",
    "*.qcow2",
    "*.vdi",
    "*.bin",
    "*.out",
    "*.o",
    "*.obj",
    "*.lib",
    "*.a",
    "*.so",
    "*.dylib",
    "*.bundle",
    "*.app",
    "*.dSYM",
    "*.framework",
    "*.xcarchive",
    "*.ipa",
    "*.apk",
    "*.aab",
    "*.xap",
    "*.appx",
    "*.msix",
    "*.nupkg",
    "*.snupkg",
    "*.symbols.nupkg",
    "*.msp",
    "*.msm",
    "*.cab",
    "*.dmp",
    "*.hdmp",
    "*.mdmp",
    "*.crash",
    "*.core",
    "*.stackdump",
    "*.minidump",
    "*.wer",
    "*.sym",
    "*.pdb",
    "*.map",
    "*.ilk",
    "*.exp",
    "*.lib",
    "*.a",
    "*.o",
    "*.obj",
    "*.so",
    "*.dylib",
    "*.bundle",
    "*.app",
    "*.dSYM",
    "*.framework",
    "*.xcarchive",
    "*.ipa",
    "*.apk",
    "*.aab",
    "*.xap",
    "*.appx",
    "*.msix",
    "*.nupkg",
    "*.snupkg",
    "*.symbols.nupkg",
    "*.msp",
    "*.msm",
    "*.cab",
    "*.dmp",
    "*.hdmp",
    "*.mdmp",
    "*.crash",
    "*.core",
    "*.stackdump",
    "*.minidump",
    "*.wer"
)

Write-Host "📁 Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "📦 Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Check if output file exists
if (Test-Path $OutputPath) {
    Write-Host "🗑️  Removing existing package..." -ForegroundColor Yellow
    Remove-Item $OutputPath -Force
}

Write-Host "🔍 Scanning project files..." -ForegroundColor Gray

# Only include essential deployment files
$essentialPatterns = @(
    "aurum_harmony\master_codebase\*.py",
    "aurum_harmony\frontend\flutter_app\*.dart",
    "aurum_harmony\frontend\flutter_app\pubspec.yaml",
    "aurum_harmony\admin_panel\*",
    "requirements.txt",
    "render.yaml",
    "wrangler.toml",
    "README.md",
    "CHANGELOG.md",
    "AurumHarmony_Intro.md",
    "AurumHarmony_Simple_Intro.md",
    "DEPLOYMENT_GUIDE.md",
    "scripts\*.ps1",
    "scripts\*.py",
    "scripts\*.bat",
    "aurum_harmony\engines\*.py",
    "aurum_harmony\api\*.py",
    "aurum_harmony\auth\*.py",
    "aurum_harmony\brokers\*.py",
    "aurum_harmony\backtesting\*.py",
    "aurum_harmony\paper_trading\*.py",
    "aurum_harmony\settlement\*.py",
    "aurum_harmony\compliance\*.py",
    "aurum_harmony\notifications\*.py",
    "aurum_harmony\reporting\*.py",
    "aurum_harmony\risk_management\*.py",
    "aurum_harmony\services\*.py"
)

$filesToInclude = Get-ChildItem -Path $projectRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $include = $false
    $relativePath = $_.FullName.Replace($projectRoot, "").TrimStart("\")

    # Skip files larger than 1MB
    if ($_.Length -gt 1MB) {
        return $false
    }

    # Check if file matches essential patterns
    foreach ($pattern in $essentialPatterns) {
        if ($relativePath -like $pattern) {
            $include = $true
            break
        }
    }

    # Exclude problematic patterns even if they match essential
    if ($include) {
        foreach ($pattern in $excludePatterns) {
            if ($relativePath -like $pattern) {
                $include = $false
                break
            }
        }
    }

    $include
}

$fileCount = $filesToInclude.Count
Write-Host "📊 Found $fileCount files to include" -ForegroundColor Green

# Calculate total size
$totalSize = ($filesToInclude | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "💾 Total size: $totalSizeMB MB" -ForegroundColor Green
Write-Host ""

# Create temporary directory for clean copy
$tempDir = Join-Path $env:TEMP "aurum_deploy_temp"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "📋 Copying files to temporary location..." -ForegroundColor Gray

# Copy files to temp directory
$copiedCount = 0
foreach ($file in $filesToInclude) {
    $relativePath = $file.FullName.Replace($projectRoot, "").TrimStart("\")
    $destPath = Join-Path $tempDir $relativePath
    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

        try {
            Copy-Item $file.FullName $destPath -Force -ErrorAction Stop
        } catch {
            Write-Host "⚠️  Skipping file (access denied): $($file.FullName)" -ForegroundColor Yellow
            continue
        }
    $copiedCount++

    if ($copiedCount % 100 -eq 0) {
        Write-Host "📋 Copied $copiedCount/$fileCount files..." -ForegroundColor Gray
    }
}

Write-Host "📋 File copying complete!" -ForegroundColor Green
Write-Host ""

# Create ZIP archive
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path "$tempDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal

# Cleanup
Remove-Item $tempDir -Recurse -Force

# Verify ZIP
$zipSize = (Get-Item $OutputPath).Length
$zipSizeMB = [math]::Round($zipSize / 1MB, 2)

Write-Host ""
Write-Host "✅ Deployment package created successfully!" -ForegroundColor Green
Write-Host "📦 File: $OutputPath" -ForegroundColor Cyan
Write-Host "💾 Size: $zipSizeMB MB" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Go to https://github.com/imvikverma/ah-v1-beta" -ForegroundColor White
Write-Host "2. Click 'Add file' → 'Upload files'" -ForegroundColor White
Write-Host "3. Drag and drop the ZIP contents" -ForegroundColor White
Write-Host "4. Commit with message: 'AurumHarmony v1.0 Production Release'" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Ready for deployment!" -ForegroundColor Magenta
