Param(
    [string]$CommitMessage = ""
)

Write-Host "=== AurumHarmony Cloudflare Deploy ===" -ForegroundColor Yellow

try {
    # Get project root (parent of scripts directory)
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptsDir = Split-Path -Parent $scriptPath
    $root = Split-Path -Parent $scriptsDir
    Set-Location $root
    
    # Read commit message from CHANGELOG.md if not provided
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        $changelogPath = Join-Path $root "CHANGELOG.md"
        if (Test-Path $changelogPath) {
            $changelog = Get-Content $changelogPath -Raw
            # Extract latest [Unreleased] entries
            $unreleasedMatch = [regex]::Match($changelog, '\[Unreleased\]([\s\S]*?)(?=\n## \[|\Z)')
            if ($unreleasedMatch.Success) {
                $unreleasedContent = $unreleasedMatch.Groups[1].Value
                # Extract first few entries
                $entryMatches = [regex]::Matches($unreleasedContent, '- (.+)')
                if ($entryMatches.Count -gt 0) {
                    $entries = $entryMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 3
                    $CommitMessage = "Update: " + ($entries -join "; ")
                }
            }
        }
        
        # Fallback to default if still empty
        if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            $CommitMessage = "Update Flutter web build for Cloudflare"
        }
    }
    
    Write-Host "   Commit message: $CommitMessage" -ForegroundColor Gray

    Write-Host "`n[1/5] Building Flutter web app..." -ForegroundColor Cyan
    Write-Host "   Project root: $root" -ForegroundColor Gray
    Set-Location "$root\aurum_harmony\frontend\flutter_app"
    flutter clean
    flutter pub get
    flutter build web --release

    Write-Host "`n[2/5] Regenerating README..." -ForegroundColor Cyan
    Set-Location $root
    $generateReadmePath = Join-Path $root "scripts\generate-readme.ps1"
    if (Test-Path $generateReadmePath) {
        & $generateReadmePath | Out-Null
    } else {
        Write-Host "   ⚠️  README generator not found, skipping..." -ForegroundColor Yellow
    }
    
    Write-Host "`n[3/5] Copying build to docs/ ..." -ForegroundColor Cyan
    Set-Location $root
    
    # Verify build directory exists
    $buildPath = Join-Path $root "aurum_harmony\frontend\flutter_app\build\web"
    if (-not (Test-Path $buildPath)) {
        throw "Build directory not found: $buildPath"
    }
    Write-Host "   Source: $buildPath" -ForegroundColor Gray
    
    # Clean and create docs directory
    $docsPath = Join-Path $root "docs"
    if (Test-Path $docsPath) {
        Remove-Item -Recurse -Force $docsPath
    }
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
    Write-Host "   Destination: $docsPath" -ForegroundColor Gray
    
    # Copy build files
    Copy-Item -Recurse "$buildPath\*" -Destination $docsPath -Force
    Write-Host "   ✅ Build files copied successfully" -ForegroundColor Green

    Write-Host "`n[4/5] Committing changes..." -ForegroundColor Cyan
    
    # Ensure we're in the git repo root
    if (-not (Test-Path ".git")) {
        throw "Not in a git repository. Current directory: $(Get-Location)"
    }
    
    # Add files
    git add docs README.md CHANGELOG.md 2>&1 | Out-Null
    
    # Check if there are changes to commit
    $stagedFiles = git diff --staged --name-only
    if ($stagedFiles) {
        Write-Host "   Staged files:" -ForegroundColor Gray
        $stagedFiles | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
        
        $env:GIT_EDITOR = "true"
        git commit -m "$CommitMessage"
        
        Write-Host "`n[5/5] Pushing to GitHub (this triggers Cloudflare)..." -ForegroundColor Cyan
        $env:GIT_EDITOR = "true"
        git push origin main
        
        Write-Host "`n✅ Deploy script finished. Cloudflare will pick up the new commit in a minute or two." -ForegroundColor Green
        Write-Host "   Live URL: https://ah.saffronbolt.in" -ForegroundColor Yellow
    } else {
        Write-Host "`n⚠️  No changes to commit. Build output is identical to current docs/ folder." -ForegroundColor Yellow
        Write-Host "   Cloudflare is already up to date!" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n❌ Deploy failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


