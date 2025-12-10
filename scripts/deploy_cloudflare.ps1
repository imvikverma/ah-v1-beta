Param(
    [string]$CommitMessage = "",
    [switch]$Force = $false
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

    Write-Host "`n[1/6] Building Flutter web app..." -ForegroundColor Cyan
    Write-Host "   Project root: $root" -ForegroundColor Gray
    Set-Location "$root\aurum_harmony\frontend\flutter_app"
    
    # Clean Flutter with better error handling
    Write-Host "   Cleaning Flutter project..." -ForegroundColor Gray
    $cleanOutput = flutter clean 2>&1 | Out-String
    
    # Filter out confusing "Removed X of Y files" messages (Flutter sometimes reports inconsistent counts)
    $cleanOutput = $cleanOutput -replace 'Removed \d+ of \d+ files?', 'Cleaned build files'
    $cleanOutput = $cleanOutput -replace 'Removed \d+ files?', 'Cleaned build files'
    
    # Ignore deletion errors for ephemeral directories (they're recreated anyway)
    if ($cleanOutput -match "Failed to remove|cannot access") {
        Write-Host "   ⚠️  Some directories couldn't be deleted (safe to ignore)" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ Clean completed" -ForegroundColor Green
    }
    
    Write-Host "   Getting dependencies..." -ForegroundColor Gray
    flutter pub get 2>&1 | Out-Null
    
    Write-Host "   Building web app (this may take 1-2 minutes)..." -ForegroundColor Gray
    flutter build web --release 2>&1 | Out-Null

    Write-Host "`n[2/6] Regenerating README..." -ForegroundColor Cyan
    Set-Location $root
    $generateReadmePath = Join-Path $root "scripts\generate-readme.ps1"
    if (Test-Path $generateReadmePath) {
        & $generateReadmePath | Out-Null
    } else {
        Write-Host "   ⚠️  README generator not found, skipping..." -ForegroundColor Yellow
    }
    
    Write-Host "`n[3/6] Copying build to docs/ ..." -ForegroundColor Cyan
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
    
    # Copy Cloudflare cache headers file
    $headersSource = Join-Path $root "docs\_headers"
    if (Test-Path $headersSource) {
        Copy-Item $headersSource -Destination (Join-Path $docsPath "_headers") -Force
        Write-Host "   ✅ Cache headers file copied" -ForegroundColor Green
    }
    
    # Add cache-busting: Inject build timestamp into index.html
    Write-Host "   Adding cache-busting timestamp..." -ForegroundColor Gray
    $indexHtmlPath = Join-Path $docsPath "index.html"
    if (Test-Path $indexHtmlPath) {
        $buildTimestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $indexContent = Get-Content $indexHtmlPath -Raw
        # Add meta tag for cache-busting if not present
        if ($indexContent -notmatch 'meta name="build-timestamp"') {
            $indexContent = $indexContent -replace '(</head>)', "  <meta name=`"build-timestamp`" content=`"$buildTimestamp`">`n`$1"
            Set-Content -Path $indexHtmlPath -Value $indexContent -NoNewline
            Write-Host "   ✅ Cache-busting timestamp added: $buildTimestamp" -ForegroundColor Green
        }
    }

    Write-Host "`n[4/6] Pulling latest changes from GitHub (before committing)..." -ForegroundColor Cyan
    $env:GIT_EDITOR = "true"
    
    # First, ensure we have latest changes before committing
    # This reduces conflicts later
    $pullOutput = git pull origin main --rebase --autostash 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0 -and $pullOutput -match "CONFLICT") {
        Write-Host "   ⚠️  Conflicts detected during pull. Resolving..." -ForegroundColor Yellow
        
        # Check what's conflicted
        $conflictStatus = git status --short 2>&1 | Out-String
        
        if ($conflictStatus -match "docs/") {
            Write-Host "   Resolving docs/ conflicts (using local version)..." -ForegroundColor Gray
            git checkout --ours docs/ 2>&1 | Out-Null
            git add docs/ 2>&1 | Out-Null
        }
        
        # Resolve any other conflicts
        git add -A 2>&1 | Out-Null
        git rebase --continue --no-edit 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ⚠️  Could not auto-resolve. Aborting rebase..." -ForegroundColor Yellow
            git rebase --abort 2>&1 | Out-Null
            # Try regular pull instead
            git pull origin main --no-edit 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Pulled with merge" -ForegroundColor Green
            }
        } else {
            Write-Host "   ✅ Rebase completed" -ForegroundColor Green
        }
    } else {
        Write-Host "   ✅ Pulled latest changes" -ForegroundColor Green
    }
    
    Write-Host "`n[5/6] Committing changes..." -ForegroundColor Cyan
    
    # Ensure we're in the git repo root
    if (-not (Test-Path ".git")) {
        throw "Not in a git repository. Current directory: $(Get-Location)"
    }
    
    # Add files (including any changes from pull)
    git add docs README.md CHANGELOG.md 2>&1 | Out-Null
    
    # Check if there are changes to commit
    $stagedFiles = git diff --staged --name-only
    $modifiedFiles = git diff --name-only
    $untrackedFiles = git ls-files --others --exclude-standard
    
    if ($stagedFiles -or $modifiedFiles -or $untrackedFiles) {
        # Add all changes
        git add -A 2>&1 | Out-Null
        $stagedFiles = git diff --staged --name-only
        
        if ($stagedFiles) {
            Write-Host "   Staged files:" -ForegroundColor Gray
            $stagedFiles | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
            
            $env:GIT_EDITOR = "true"
            $commitOutput = git commit -m "$CommitMessage" 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Committed successfully" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Commit may have failed: $commitOutput" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ℹ️  No changes to commit (already up to date)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ℹ️  No changes detected" -ForegroundColor Gray
    }
        
    Write-Host "`n[6/6] Pushing to GitHub (this triggers Cloudflare)..." -ForegroundColor Cyan
    $env:GIT_EDITOR = "true"
    
    # Check if we're ahead of remote
    $statusOutput = git status -sb 2>&1 | Out-String
    $isAhead = $statusOutput -match "ahead"
    
    if (-not $isAhead -and -not $stagedFiles) {
        Write-Host "   ℹ️  No commits to push (already up to date)" -ForegroundColor Gray
    } else {
        if ($Force) {
            Write-Host "   ⚠️  Force push enabled" -ForegroundColor Yellow
            $pushOutput = git push origin main --force 2>&1 | Out-String
        } else {
            $pushOutput = git push origin main 2>&1 | Out-String
        }
        
        if ($LASTEXITCODE -eq 0) {
            # Get the commit hash for verification
            $commitHash = (git rev-parse HEAD).Trim()
            Write-Host "   ✅ Push successful!" -ForegroundColor Green
            Write-Host "   Commit hash: $commitHash" -ForegroundColor Gray
        } else {
            if ($pushOutput -match "rejected.*fetch first" -or $pushOutput -match "Updates were rejected" -or $pushOutput -match "non-fast-forward") {
                Write-Host "   ⚠️  Remote has new changes. Pulling and retrying..." -ForegroundColor Yellow
                
                # Pull with rebase
                git pull origin main --rebase --autostash 2>&1 | Out-Null
                
                # Resolve docs/ conflicts if any
                if ($LASTEXITCODE -ne 0) {
                    $conflictStatus = git status --short 2>&1 | Out-String
                    if ($conflictStatus -match "docs/") {
                        git checkout --ours docs/ 2>&1 | Out-Null
                        git add docs/ 2>&1 | Out-Null
                    }
                    git add -A 2>&1 | Out-Null
                    git rebase --continue --no-edit 2>&1 | Out-Null
                }
                
                # Try push again
                if ($Force) {
                    $pushOutput = git push origin main --force 2>&1 | Out-String
                } else {
                    $pushOutput = git push origin main 2>&1 | Out-String
                }
                
                if ($LASTEXITCODE -eq 0) {
                    $commitHash = (git rev-parse HEAD).Trim()
                    Write-Host "   ✅ Push successful after rebase!" -ForegroundColor Green
                    Write-Host "   Commit hash: $commitHash" -ForegroundColor Gray
                } else {
                    Write-Host "   ❌ Push failed after rebase" -ForegroundColor Red
                    Write-Host "   Error: $pushOutput" -ForegroundColor Gray
                    Write-Host "   💡 Manual fix needed. Run these commands:" -ForegroundColor Cyan
                    Write-Host "      git pull origin main --rebase" -ForegroundColor Gray
                    Write-Host "      git checkout --ours docs/  # if conflicts in docs/" -ForegroundColor Gray
                    Write-Host "      git add docs/ && git rebase --continue" -ForegroundColor Gray
                    Write-Host "      git push origin main" -ForegroundColor Gray
                    throw "Git push failed after rebase"
                }
            } else {
                Write-Host "   ❌ Push failed: $pushOutput" -ForegroundColor Red
                throw "Git push failed: $pushOutput"
            }
        }
    }
    
    # Success message (only if we got here without errors)
    if ($stagedFiles -or $isAhead) {
        Write-Host "`n✅ Deploy script finished. Cloudflare will pick up the new commit in 1-3 minutes." -ForegroundColor Green
        Write-Host "   Live URL: https://ah.saffronbolt.in" -ForegroundColor Yellow
        Write-Host "   Preview URL: https://aurumharmony-v1-beta.pages.dev" -ForegroundColor Yellow
        Write-Host "`n💡 Tip: Use Ctrl+Shift+R (or Cmd+Shift+R on Mac) to hard refresh and bypass cache." -ForegroundColor Cyan
        Write-Host "   Or use the auto-refresh tool: scripts\firefox_auto_refresh.html" -ForegroundColor Cyan
    } else {
        Write-Host "`n⚠️  No changes to commit. Build output is identical to current docs/ folder." -ForegroundColor Yellow
        Write-Host "   Cloudflare is already up to date!" -ForegroundColor Green
    }
}
catch {
    Write-Host "`n❌ Deploy failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


