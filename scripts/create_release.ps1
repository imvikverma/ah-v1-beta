# Create a new release version
# Usage: .\scripts\create_release.ps1 -Version "1.1.0"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [string]$ReleaseDate = "",
    [switch]$CreateTag = $true,
    [switch]$PushTag = $false
)

$ErrorActionPreference = "Stop"

# Get project root
$scriptPath = $MyInvocation.MyCommand.Path
$scriptsDir = Split-Path -Parent $scriptPath
$root = Split-Path -Parent $scriptsDir
Set-Location $root

# Validate version format (MAJOR.MINOR)
if ($Version -notmatch '^\d+\.\d+$') {
    Write-Host "✗ Invalid version format. Use MAJOR.MINOR format (e.g., 1.1 or 2.0)" -ForegroundColor Red
    Write-Host "  Minor changes: 1.0 → 1.1 → 1.2" -ForegroundColor Yellow
    Write-Host "  Major changes: 1.x → 2.0 (design overhauls, breaking changes)" -ForegroundColor Yellow
    exit 1
}

# Set release date
if ([string]::IsNullOrWhiteSpace($ReleaseDate)) {
    $ReleaseDate = Get-Date -Format "yyyy-MM-dd"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Creating Release v$Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if CHANGELOG.md exists
$changelogPath = Join-Path $root "CHANGELOG.md"
if (-not (Test-Path $changelogPath)) {
    Write-Host "✗ CHANGELOG.md not found" -ForegroundColor Red
    exit 1
}

# Read changelog
$changelog = Get-Content $changelogPath -Raw

# Check if [Unreleased] section exists
if ($changelog -notmatch '\[Unreleased\]') {
    Write-Host "✗ No [Unreleased] section found in CHANGELOG.md" -ForegroundColor Red
    Write-Host "  Add changes to [Unreleased] section first" -ForegroundColor Yellow
    exit 1
}

# Extract [Unreleased] content
$unreleasedMatch = [regex]::Match($changelog, '\[Unreleased\]([\s\S]*?)(?=\n## \[|\Z)')
if (-not $unreleasedMatch.Success) {
    Write-Host "✗ Could not extract [Unreleased] content" -ForegroundColor Red
    exit 1
}

$unreleasedContent = $unreleasedMatch.Groups[1].Value.Trim()

if ([string]::IsNullOrWhiteSpace($unreleasedContent)) {
    Write-Host "⚠ [Unreleased] section is empty" -ForegroundColor Yellow
    Write-Host "  Continue anyway? (y/n): " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit 0
    }
}

# Replace [Unreleased] with new version
$newVersionSection = "## [$Version] - $ReleaseDate`n`n$unreleasedContent"
$newChangelog = $changelog -replace '\[Unreleased\]([\s\S]*?)(?=\n## \[|\Z)', $newVersionSection

# Add [Unreleased] section back at the top
$unreleasedHeader = "## [Unreleased]`n`n### Added`n- (No changes yet)`n`n"
$newChangelog = $newChangelog -replace '(## \[Unreleased\])', "$unreleasedHeader`$1"

# If [Unreleased] doesn't exist, add it
if ($newChangelog -notmatch '\[Unreleased\]') {
    $newChangelog = "## [Unreleased]`n`n### Added`n- (No changes yet)`n`n`n" + $newChangelog
}

# Write updated changelog
Set-Content -Path $changelogPath -Value $newChangelog -NoNewline
Write-Host "✓ Updated CHANGELOG.md" -ForegroundColor Green

# Update RELEASES.md if it exists
$releasesPath = Join-Path $root "RELEASES.md"
if (Test-Path $releasesPath) {
    $releases = Get-Content $releasesPath -Raw
    
    # Check if version already exists
    if ($releases -match "\[$Version\]") {
        Write-Host "⚠ Version $Version already exists in RELEASES.md" -ForegroundColor Yellow
    } else {
        # Add new release entry after the header
        $releaseEntry = @"

### [$Version] - $ReleaseDate

**Key Changes:**
$($unreleasedContent -split "`n" | Where-Object { $_ -match "^- " } | Select-Object -First 5 | ForEach-Object { "  " + $_ })

**Status:** Released

---
"@
        
        # Insert after "## Release History" section
        $releases = $releases -replace '(## Release History\s*\n)', "`$1`n$releaseEntry"
        Set-Content -Path $releasesPath -Value $releases -NoNewline
        Write-Host "✓ Updated RELEASES.md" -ForegroundColor Green
    }
}

# Update version in version.json if it exists
$versionJsonPath = Join-Path $root "docs\version.json"
if (Test-Path $versionJsonPath) {
    $versionJson = Get-Content $versionJsonPath -Raw | ConvertFrom-Json
    $versionJson.version = $Version
    $versionJson | ConvertTo-Json | Set-Content -Path $versionJsonPath
    Write-Host "✓ Updated version.json" -ForegroundColor Green
}

# Commit changes
Write-Host ""
Write-Host "Staging changes..." -ForegroundColor Yellow
git add CHANGELOG.md RELEASES.md docs/version.json 2>$null
git commit -m "chore: Release v$Version" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Committed release changes" -ForegroundColor Green
} else {
    Write-Host "⚠ No changes to commit (files may be unchanged)" -ForegroundColor Yellow
}

# Create git tag
if ($CreateTag) {
    Write-Host ""
    Write-Host "Creating git tag v$Version..." -ForegroundColor Yellow
    
    $tagMessage = "Release v$Version`n`n$unreleasedContent"
    git tag -a "v$Version" -m $tagMessage 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Created git tag v$Version" -ForegroundColor Green
        
        if ($PushTag) {
            Write-Host ""
            Write-Host "Pushing tag to remote..." -ForegroundColor Yellow
            git push origin "v$Version" 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Pushed tag to remote" -ForegroundColor Green
            } else {
                Write-Host "⚠ Failed to push tag (may need manual push)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  (Tag created locally. Push with: git push origin v$Version)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ Failed to create tag (may already exist)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Release v$Version Created!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review CHANGELOG.md and RELEASES.md" -ForegroundColor White
Write-Host "  2. Push commits: git push origin main" -ForegroundColor White
if ($CreateTag -and -not $PushTag) {
    Write-Host "  3. Push tag: git push origin v$Version" -ForegroundColor White
}
Write-Host "  4. Create GitHub release with release notes" -ForegroundColor White
Write-Host ""

