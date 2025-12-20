# Interactive Changelog Updater
# Helps you quickly add entries to CHANGELOG.md

param(
    [string]$Type = "",
    [string]$Message = ""
)

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$changelogPath = Join-Path $root "CHANGELOG.md"

if (-not (Test-Path $changelogPath)) {
    Write-Host "❌ CHANGELOG.md not found at: $changelogPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Update Changelog ===" -ForegroundColor Cyan
Write-Host ""

# If no parameters provided, run interactively
if ([string]::IsNullOrWhiteSpace($Type) -or [string]::IsNullOrWhiteSpace($Message)) {
    Write-Host "What type of change?" -ForegroundColor Yellow
    Write-Host "  1. Added (new features)"
    Write-Host "  2. Changed (changes to existing features)"
    Write-Host "  3. Fixed (bug fixes)"
    Write-Host "  4. Removed (removed features)"
    Write-Host "  5. Deprecated (soon-to-be removed)"
    Write-Host "  6. Security (security fixes)"
    Write-Host ""
    
    $typeChoice = Read-Host "Enter choice (1-6)"
    
    $typeMap = @{
        "1" = "Added"
        "2" = "Changed"
        "3" = "Fixed"
        "4" = "Removed"
        "5" = "Deprecated"
        "6" = "Security"
    }
    
    $Type = $typeMap[$typeChoice]
    if ([string]::IsNullOrWhiteSpace($Type)) {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    $Message = Read-Host "Enter description of the change"
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    Write-Host "❌ Message cannot be empty" -ForegroundColor Red
    exit 1
}

# Read current changelog
$content = Get-Content $changelogPath -Raw

# Find the [Unreleased] section and the first ### section
$unreleasedPattern = '(\[Unreleased\]\s*\n\s*\n)###\s+(\w+)'
$match = [regex]::Match($content, $unreleasedPattern)

if ($match.Success) {
    # Check if this type already exists
    $typePattern = "### $Type"
    if ($content -match "### $Type") {
        # Add to existing section
        $insertPoint = $content.IndexOf("### $Type") + ("### $Type").Length
        $newEntry = "`n- $Message"
        $content = $content.Insert($insertPoint, $newEntry)
    } else {
        # Add new section after [Unreleased]
        $insertPoint = $match.Index + $match.Length
        $newSection = "`n### $Type`n- $Message"
        $content = $content.Insert($insertPoint, $newSection)
    }
} else {
    # No [Unreleased] section found, add it
    $unreleasedSection = @"

## [Unreleased]

### $Type
- $Message

"@
    $content = $unreleasedSection + $content
}

# Write back
Set-Content -Path $changelogPath -Value $content -NoNewline

Write-Host "`n✅ Changelog updated!" -ForegroundColor Green
Write-Host "   Type: $Type" -ForegroundColor Gray
Write-Host "   Entry: $Message" -ForegroundColor Gray
Write-Host "`nView updated changelog: $changelogPath" -ForegroundColor Yellow

