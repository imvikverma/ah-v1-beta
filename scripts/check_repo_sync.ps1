# Check Local vs Remote Repo Sync Status
# Verifies .gitignore robustness and prepares for deployment

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
Write-Host "║     🔍 REPO SYNC STATUS CHECK                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check .gitignore coverage
Write-Host "[1/4] Checking .gitignore robustness..." -ForegroundColor Cyan

$gitignorePath = Join-Path $projectRoot ".gitignore"
if (-not (Test-Path $gitignorePath)) {
    Write-Host "   ❌ .gitignore not found!" -ForegroundColor Red
    exit 1
}

$gitignoreContent = Get-Content $gitignorePath -Raw
$criticalPatterns = @(
    @{Name=".env"; Patterns=@("\.env", "^\.env", "\.env$")},
    @{Name="_local"; Patterns=@("_local", "_local/", "^_local/")},
    @{Name=".venv"; Patterns=@("\.venv", "\.venv/", "^\.venv/")},
    @{Name="__pycache__"; Patterns=@("__pycache__", "__pycache__/", "^__pycache__/")},
    @{Name="node_modules"; Patterns=@("node_modules", "node_modules/", "^node_modules/")},
    @{Name="build"; Patterns=@("^build/", "build/", "/build/")},
    @{Name=".dart_tool"; Patterns=@("\.dart_tool", "\.dart_tool/", "^\.dart_tool/")}
)

$missingPatterns = @()
foreach ($patternObj in $criticalPatterns) {
    $found = $false
    foreach ($pattern in $patternObj.Patterns) {
        if ($gitignoreContent -match $pattern) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $missingPatterns += $patternObj.Name
    }
}

if ($missingPatterns.Count -eq 0) {
    Write-Host "   ✅ .gitignore covers all critical patterns" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Missing patterns: $($missingPatterns -join ', ')" -ForegroundColor Yellow
}

# Step 2: Check untracked files
Write-Host "`n[2/4] Checking untracked files..." -ForegroundColor Cyan

$untrackedFiles = git ls-files --others --exclude-standard
$untrackedCount = ($untrackedFiles | Measure-Object).Count

if ($untrackedCount -eq 0) {
    Write-Host "   ✅ No untracked files" -ForegroundColor Green
} else {
    Write-Host "   📋 Found $untrackedCount untracked file(s)" -ForegroundColor Yellow
    
    # Categorize untracked files
    $shouldTrack = @()
    $shouldIgnore = @()
    
    foreach ($file in $untrackedFiles) {
        $fullPath = Join-Path $projectRoot $file
        
        # Check if file should be tracked (not in .gitignore)
        $gitCheck = git check-ignore -v $file 2>&1
        if ($gitCheck) {
            $shouldIgnore += $file
        } else {
            # Check if it's a production file
            if ($file -match "^(scripts|engines|aurum_harmony|\.continue|DEPLOYMENT_GUIDE\.md|README\.md|CHANGELOG\.md)") {
                $shouldTrack += $file
            } elseif ($file -match "^\.continue/") {
                $shouldTrack += $file
            } else {
                $shouldIgnore += $file
            }
        }
    }
    
    if ($shouldTrack.Count -gt 0) {
        Write-Host "   📝 Files to add: $($shouldTrack.Count)" -ForegroundColor Cyan
        $shouldTrack | Select-Object -First 10 | ForEach-Object {
            Write-Host "      + $_" -ForegroundColor Green
        }
        if ($shouldTrack.Count -gt 10) {
            Write-Host "      ... and $($shouldTrack.Count - 10) more" -ForegroundColor Gray
        }
    }
    
    if ($shouldIgnore.Count -gt 0) {
        Write-Host "   ⏭️  Files ignored (correctly): $($shouldIgnore.Count)" -ForegroundColor Gray
    }
}

# Step 3: Check local changes
Write-Host "`n[3/4] Checking local changes..." -ForegroundColor Cyan

$modifiedFiles = git status --porcelain | Where-Object { $_ -match "^ M" } | ForEach-Object { ($_ -split "\s+", 2)[1] }
$deletedFiles = git status --porcelain | Where-Object { $_ -match "^ D" } | ForEach-Object { ($_ -split "\s+", 2)[1] }
$newFiles = git status --porcelain | Where-Object { $_ -match "^??" } | ForEach-Object { ($_ -split "\s+", 2)[1] }

$modifiedCount = ($modifiedFiles | Measure-Object).Count
$deletedCount = ($deletedFiles | Measure-Object).Count
$newCount = ($newFiles | Measure-Object).Count

Write-Host "   Modified: $modifiedCount file(s)" -ForegroundColor Yellow
Write-Host "   Deleted:  $deletedCount file(s)" -ForegroundColor Yellow
Write-Host "   New:      $newCount file(s)" -ForegroundColor Yellow

if ($modifiedCount -gt 0 -or $deletedCount -gt 0 -or $newCount -gt 0) {
    Write-Host "   ⚠️  Local repo has uncommitted changes" -ForegroundColor Yellow
} else {
    Write-Host "   ✅ Working directory clean" -ForegroundColor Green
}

# Step 4: Check remote sync
Write-Host "`n[4/4] Checking remote sync..." -ForegroundColor Cyan

try {
    git fetch origin 2>&1 | Out-Null
    
    $localCommit = git rev-parse HEAD
    $remoteCommit = git rev-parse origin/main 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ⚠️  Remote branch 'main' not found or not accessible" -ForegroundColor Yellow
        Write-Host "   💡 This might be the first push" -ForegroundColor Gray
    } else {
        $ahead = git rev-list --count HEAD ^origin/main 2>&1
        $behind = git rev-list --count origin/main ^HEAD 2>&1
        
        if ($ahead -gt 0) {
            Write-Host "   📤 Local is $ahead commit(s) ahead of remote" -ForegroundColor Cyan
        }
        if ($behind -gt 0) {
            Write-Host "   📥 Local is $behind commit(s) behind remote" -ForegroundColor Yellow
            Write-Host "   ⚠️  Consider pulling remote changes first" -ForegroundColor Yellow
        }
        if ($ahead -eq 0 -and $behind -eq 0) {
            Write-Host "   ✅ Local and remote are in sync" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   ⚠️  Could not check remote status" -ForegroundColor Yellow
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     📊 SYNC STATUS SUMMARY                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$issues = @()
if ($missingPatterns.Count -gt 0) { $issues += ".gitignore missing patterns" }
if ($modifiedCount -gt 0 -or $deletedCount -gt 0) { $issues += "Uncommitted changes" }
if ($shouldTrack.Count -gt 0) { $issues += "Untracked production files" }

if ($issues.Count -eq 0) {
    Write-Host "✅ Repository is ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review changes: git status" -ForegroundColor White
    Write-Host "  2. Stage files: git add ." -ForegroundColor White
    Write-Host "  3. Commit: git commit -m 'Your message'" -ForegroundColor White
    Write-Host "  4. Deploy: .\scripts\deploy_incremental.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️  Issues found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  • $issue" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "💡 Recommendations:" -ForegroundColor Cyan
    if ($shouldTrack.Count -gt 0) {
        Write-Host "  • Add production files: git add scripts/ engines/ .continue/" -ForegroundColor White
    }
    if ($modifiedCount -gt 0 -or $deletedCount -gt 0) {
        Write-Host "  • Review and commit changes" -ForegroundColor White
    }
    if ($missingPatterns.Count -gt 0) {
        Write-Host "  • Update .gitignore with missing patterns" -ForegroundColor White
    }
}

Write-Host ""
Set-Location $projectRoot

