# AurumHarmony Cloudflare Deployment Script
# Builds Flutter web app and deploys to Cloudflare Pages via GitHub

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
            $CommitMessage = "chore: Update Flutter web build for Cloudflare"
        }
    }
    
    Write-Host "   Commit message: $CommitMessage" -ForegroundColor Gray

    Write-Host "`n[1/4] Building Flutter web app..." -ForegroundColor Cyan
    Write-Host "   Project root: $root" -ForegroundColor Gray
    $flutterDir = Join-Path $root "aurum_harmony\frontend\flutter_app"
    Set-Location $flutterDir
    flutter clean
    flutter pub get
    flutter build web --release

    Write-Host "`n[2/4] Copying build to docs/ ..." -ForegroundColor Cyan
    Set-Location $root
    if (Test-Path docs) {
        Remove-Item -Recurse -Force docs
    }
    New-Item -ItemType Directory -Path docs | Out-Null
    Copy-Item -Recurse "$flutterDir\build\web\*" -Destination "docs\"

    Write-Host "`n[3/4] Committing changes..." -ForegroundColor Cyan
    git add docs
    
    # Check if there are changes to commit
    $hasChanges = git diff --staged --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m "$CommitMessage"
        Write-Host "`n[4/4] Pushing to GitHub (this triggers Cloudflare)..." -ForegroundColor Cyan
        git push origin main
        Write-Host "`n✅ Deploy script finished. Cloudflare will pick up the new commit in a minute or two." -ForegroundColor Green
        Write-Host "   Live at: https://ah.saffronbolt.in" -ForegroundColor Yellow
    } else {
        Write-Host "`n⚠️  No changes to commit. Build output is identical to current docs/ folder." -ForegroundColor Yellow
        Write-Host "   Cloudflare is already up to date!" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n❌ Deploy failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

