# Incremental Deployment Script
# Only deploys changed files, skips rebuild if no changes

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "`n=== Incremental Deployment ===" -ForegroundColor Magenta
Write-Host "Only deploying changed files to reduce payload size" -ForegroundColor Yellow
Write-Host ""

$flutterDir = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"
$buildPath = Join-Path $flutterDir "build\web"
$docsPath = Join-Path $projectRoot "docs"

# Step 1: Check if Flutter source files changed
Write-Host "[1/4] Checking for changes..." -ForegroundColor Cyan

$sourceChanged = $false
$lastBuildHash = Join-Path $projectRoot "_local\last_build_hash.txt"

# Get list of Flutter source files
$flutterSourceFiles = Get-ChildItem -Path $flutterDir -Include *.dart,*.yaml,*.json -Recurse | 
    Where-Object { $_.FullName -notmatch "build|\.dart_tool" }

# Calculate hash of source files
$sourceHash = ($flutterSourceFiles | Get-FileHash -Algorithm SHA256 | Select-Object -ExpandProperty Hash) -join ""
$currentHash = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sourceHash))

# Check if we have a previous build hash
if (Test-Path $lastBuildHash) {
    $previousHash = Get-Content $lastBuildHash -Raw
    if ($currentHash -ne $previousHash) {
        $sourceChanged = $true
        Write-Host "   ✅ Source files changed - rebuild needed" -ForegroundColor Green
    } else {
        Write-Host "   ⏭️  No source changes - skipping rebuild" -ForegroundColor Yellow
    }
} else {
    $sourceChanged = $true
    Write-Host "   ✅ First build - building everything" -ForegroundColor Green
}

# Step 2: Build only if needed
if ($sourceChanged) {
    Write-Host "`n[2/4] Building Flutter web..." -ForegroundColor Cyan
    Set-Location $flutterDir
    
    # Skip flutter clean for incremental builds (faster)
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get 2>&1 | Out-Null
    
    Write-Host "   Building web (incremental)..." -ForegroundColor Gray
    $buildOutput = flutter build web --release 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Build completed" -ForegroundColor Green
    
    # Save build hash
    $hashDir = Split-Path $lastBuildHash -Parent
    if (-not (Test-Path $hashDir)) {
        New-Item -ItemType Directory -Path $hashDir -Force | Out-Null
    }
    Set-Content -Path $lastBuildHash -Value $currentHash
} else {
    Write-Host "`n[2/4] Skipping build (no changes)" -ForegroundColor Yellow
}

# Step 3: Copy only changed files to docs/
Write-Host "`n[3/4] Copying changed files to docs/..." -ForegroundColor Cyan
Set-Location $projectRoot

if (-not (Test-Path $buildPath)) {
    Write-Host "❌ Build directory not found - forcing rebuild..." -ForegroundColor Red
    Set-Location $flutterDir
    flutter build web --release 2>&1 | Out-Null
    Set-Location $projectRoot
}

# Create docs directory if it doesn't exist
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
}

# Copy files, but track what changed
$changedFiles = @()
$buildFiles = Get-ChildItem -Path $buildPath -Recurse -File

foreach ($file in $buildFiles) {
    $relativePath = $file.FullName.Substring($buildPath.Length + 1)
    $destPath = Join-Path $docsPath $relativePath
    $destDir = Split-Path $destPath -Parent
    
    # Create directory if needed
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    # Only copy if file doesn't exist or is different
    $shouldCopy = $true
    if (Test-Path $destPath) {
        $sourceHash = (Get-FileHash $file.FullName).Hash
        $destHash = (Get-FileHash $destPath).Hash
        if ($sourceHash -eq $destHash) {
            $shouldCopy = $false
        }
    }
    
    if ($shouldCopy) {
        Copy-Item -Path $file.FullName -Destination $destPath -Force
        $changedFiles += $relativePath
    }
}

if ($changedFiles.Count -gt 0) {
    Write-Host "   ✅ Copied $($changedFiles.Count) changed file(s)" -ForegroundColor Green
    Write-Host "   Files: $($changedFiles -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "   ⏭️  No files changed - nothing to copy" -ForegroundColor Yellow
}

# Step 4: Commit only if there are changes
Write-Host "`n[4/4] Checking git status..." -ForegroundColor Cyan

git add docs 2>&1 | Out-Null
$stagedFiles = git diff --staged --name-only

if ($stagedFiles) {
    Write-Host "   📝 Staged $($stagedFiles.Count) file(s) for commit" -ForegroundColor Green
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMsg = "Deploy: Incremental update ($($changedFiles.Count) files changed) - $timestamp [skip ci]"
    git commit -m $commitMsg 2>&1 | Out-Null
    
    Write-Host "   📤 Pushing to GitHub..." -ForegroundColor Gray
    $pushOutput = git push origin main 2>&1 | Out-String
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Incremental deployment completed!" -ForegroundColor Green
        Write-Host "   Files changed: $($changedFiles.Count)" -ForegroundColor Cyan
        Write-Host "   Cloudflare will auto-deploy in ~60 seconds" -ForegroundColor Yellow
        Write-Host "   URL: https://ah.saffronbolt.in" -ForegroundColor Cyan
    } else {
        Write-Host "`n⚠️  Push may have issues - check output above" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⏭️  No changes to commit - deployment skipped" -ForegroundColor Yellow
    Write-Host "   Everything is up to date!" -ForegroundColor Green
}

Set-Location $projectRoot

