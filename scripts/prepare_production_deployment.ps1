# Prepare Clean Production Deployment
# Ensures codebase is ready for production deployment

$ErrorActionPreference = "Continue"

# Get project root
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
Set-Location $projectRoot

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Production Deployment Preparation                   ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Git Status
Write-Host "[1] Checking Git Status..." -ForegroundColor Yellow
Write-Host "─────────────────────────────" -ForegroundColor Gray

try {
    $gitStatus = git status --short 2>&1
    if ($gitStatus) {
        Write-Host "  ⚠️  Uncommitted changes found:" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
        Write-Host ""
        $commit = Read-Host "  Commit changes before deployment? (y/N)"
        if ($commit -eq 'y' -or $commit -eq 'Y') {
            git add -A
            $commitMsg = Read-Host "  Enter commit message (or press Enter for default)"
            if ([string]::IsNullOrWhiteSpace($commitMsg)) {
                $commitMsg = "Production deployment preparation - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            }
            git commit -m $commitMsg
            Write-Host "  ✅ Changes committed" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✅ Working directory clean" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Not a git repository or git not available" -ForegroundColor Yellow
}

# Step 2: Verify .gitignore
Write-Host "`n[2] Verifying .gitignore..." -ForegroundColor Yellow
Write-Host "───────────────────────────────" -ForegroundColor Gray

$gitignorePath = Join-Path $projectRoot ".gitignore"
if (Test-Path $gitignorePath) {
    $gitignore = Get-Content $gitignorePath -Raw
    $requiredIgnores = @(".env", "_local", ".venv", "*.log", "*.db", "node_modules")
    $missing = @()
    
    foreach ($ignore in $requiredIgnores) {
        if ($gitignore -notmatch [regex]::Escape($ignore)) {
            $missing += $ignore
        }
    }
    
    if ($missing.Count -eq 0) {
        Write-Host "  ✅ .gitignore looks good" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Missing ignores: $($missing -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ .gitignore not found!" -ForegroundColor Red
}

# Step 3: Check for sensitive data
Write-Host "`n[3] Checking for Sensitive Data..." -ForegroundColor Yellow
Write-Host "──────────────────────────────────────" -ForegroundColor Gray

$sensitivePatterns = @(
    "password\s*=\s*['`"][^'`"]+['`"]",
    "api_key\s*=\s*['`"][^'`"]+['`"]",
    "secret\s*=\s*['`"][^'`"]+['`"]",
    "token\s*=\s*['`"][^'`"]+['`"]"
)

$foundSensitive = $false
$filesToCheck = Get-ChildItem -Path $projectRoot -Recurse -Include *.py,*.ts,*.js,*.json,*.toml,*.yaml,*.yml -Exclude node_modules,__pycache__,.git -ErrorAction SilentlyContinue | Select-Object -First 100

foreach ($file in $filesToCheck) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        foreach ($pattern in $sensitivePatterns) {
            if ($content -match $pattern) {
                # Check if it's a placeholder or example
                if ($content -notmatch "example|placeholder|your_|TODO|FIXME") {
                    Write-Host "  ⚠️  Potential sensitive data in: $($file.FullName)" -ForegroundColor Yellow
                    $foundSensitive = $true
                    break
                }
            }
        }
    } catch {
        # Skip files that can't be read
    }
}

if (-not $foundSensitive) {
    Write-Host "  ✅ No obvious sensitive data found" -ForegroundColor Green
}

# Step 4: Verify Repository Structure
Write-Host "`n[4] Verifying Repository Structure..." -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────" -ForegroundColor Gray

$requiredDirs = @(
    "aurum_harmony",
    "engines",
    "scripts",
    "worker"
)

$missingDirs = @()
foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path $projectRoot $dir
    if (-not (Test-Path $dirPath)) {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -eq 0) {
    Write-Host "  ✅ Required directories present" -ForegroundColor Green
} else {
    Write-Host "  ❌ Missing directories: $($missingDirs -join ', ')" -ForegroundColor Red
}

# Step 5: Check Deployment Files
Write-Host "`n[5] Checking Deployment Files..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Gray

$deploymentFiles = @(
    "wrangler.toml",
    "DEPLOYMENT_GUIDE.md",
    "REPOSITORY_DEPLOYMENT.md",
    ".github/workflows/deploy-worker.yml"
)

$missingFiles = @()
foreach ($file in $deploymentFiles) {
    $filePath = Join-Path $projectRoot $file
    if (-not (Test-Path $filePath)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "  ✅ Deployment files present" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Missing files: $($missingFiles -join ', ')" -ForegroundColor Yellow
}

# Step 6: Generate Deployment Summary
Write-Host "`n[6] Generating Deployment Summary..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────" -ForegroundColor Gray

$summary = @"
# Production Deployment Checklist
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Repositories to Deploy

1. **ah-v1-beta** - Main v1 codebase
   - Status: Ready
   - Contains: Flask backend, admin panel, documentation

2. **aurumharmony-v2-frontend** - v2 Frontend
   - Status: Ready
   - Contains: Flutter frontend for v2

3. **aurumharmony-v2** - v2 Full Stack
   - Status: Ready
   - Contains: Complete v2 codebase

4. **aurum-api-v2-production** - v2 Worker API
   - Status: Ready
   - Contains: Cloudflare Worker API (aurum-api-v2)
   - Domain: api-v2.saffronbolt.in

## Pre-Deployment Checklist

- [ ] All changes committed to Git
- [ ] .gitignore verified (no sensitive data)
- [ ] Login issues fixed
- [ ] Backend tested locally
- [ ] Frontend builds successfully
- [ ] Worker builds successfully
- [ ] Environment variables configured in Cloudflare/Render
- [ ] DNS configured for custom domains

## Deployment Steps

1. Push to GitHub repositories
2. Deploy Worker: aurum-api-v2-production
3. Deploy Frontend: Cloudflare Pages
4. Deploy Backend: Render.com or similar
5. Verify all endpoints working
6. Test login flow
7. Monitor for errors

## Post-Deployment

- [ ] Test login functionality
- [ ] Test API endpoints
- [ ] Verify reports generation
- [ ] Check error logs
- [ ] Monitor performance
"@

$summaryPath = Join-Path $projectRoot "_local\documentation\DEPLOYMENT_CHECKLIST.md"
$summaryDir = Split-Path -Parent $summaryPath
if (-not (Test-Path $summaryDir)) {
    New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null
}
$summary | Set-Content $summaryPath -Encoding UTF8
Write-Host "  ✅ Deployment checklist saved to: $summaryPath" -ForegroundColor Green

Write-Host "`n✅ Production Deployment Preparation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review deployment checklist: _local\documentation\DEPLOYMENT_CHECKLIST.md" -ForegroundColor White
Write-Host "  2. Fix any issues found above" -ForegroundColor White
Write-Host "  3. Push to GitHub repositories" -ForegroundColor White
Write-Host "  4. Deploy Worker, Frontend, and Backend" -ForegroundColor White
Write-Host ""

