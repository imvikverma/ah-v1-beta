# Cleanup Unnecessary Folders
# Removes backup, old files, and other unnecessary folders

param(
    [switch]$DryRun = $false
)

Write-Host "=== CLEANING UP UNNECESSARY FOLDERS ===" -ForegroundColor Cyan
Write-Host ""

# Get project root (works from any location)
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

$removed = @()
$kept = @()

# Folders to check for removal
$foldersToCheck = @(
    @{
        "Path" = "backup"
        "Reason" = "Old backup folder - recovery already done"
        "KeepIf" = $null
    },
    @{
        "Path" = "Code_Files"
        "Reason" = "Old code files from Nov 26 - recovery already done"
        "KeepIf" = $null
    },
    @{
        "Path" = "local_docs"
        "Reason" = "Empty folder"
        "KeepIf" = { (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0 }
    },
    @{
        "Path" = "Recovered"
        "Reason" = "Recovery already completed - files extracted"
        "KeepIf" = $null
    }
)

Write-Host "1. Checking folders for removal..." -ForegroundColor Yellow
Write-Host ""

foreach ($folderInfo in $foldersToCheck) {
    $folderPath = Join-Path $projectRoot $folderInfo.Path
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "  ℹ️  Not found: $($folderInfo.Path)/" -ForegroundColor Gray
        continue
    }
    
    # Check if we should keep it
    $shouldKeep = $false
    if ($folderInfo.KeepIf) {
        $item = Get-Item $folderPath
        $shouldKeep = & $folderInfo.KeepIf $item
    }
    
    if ($shouldKeep) {
        $kept += $folderInfo.Path
        Write-Host "  ✅ KEEP: $($folderInfo.Path)/ (has content)" -ForegroundColor Green
    } else {
        $itemCount = (Get-ChildItem $folderPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  🗑️  REMOVE: $($folderInfo.Path)/ ($itemCount items)" -ForegroundColor Yellow
        Write-Host "     Reason: $($folderInfo.Reason)" -ForegroundColor Gray
        
        if (-not $DryRun) {
            try {
                Remove-Item -Path $folderPath -Recurse -Force -ErrorAction Stop
                $removed += $folderInfo.Path
                Write-Host "     ✅ Removed" -ForegroundColor Green
            } catch {
                Write-Host "     ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "     [DRY RUN] Would remove" -ForegroundColor Cyan
            $removed += $folderInfo.Path
        }
    }
}

# Check for other potentially unnecessary folders
Write-Host ""
Write-Host "2. Checking other folders..." -ForegroundColor Yellow
Write-Host ""

$otherFolders = @("Old_Files", "Other_Files")
foreach ($folder in $otherFolders) {
    $folderPath = Join-Path $projectRoot $folder
    if (Test-Path $folderPath) {
        $itemCount = (Get-ChildItem $folderPath -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($itemCount -eq 0) {
            Write-Host "  🗑️  REMOVE: $folder/ (empty)" -ForegroundColor Yellow
            if (-not $DryRun) {
                Remove-Item -Path $folderPath -Force -ErrorAction SilentlyContinue
                $removed += $folder
                Write-Host "     ✅ Removed" -ForegroundColor Green
            } else {
                Write-Host "     [DRY RUN] Would remove" -ForegroundColor Cyan
                $removed += $folder
            }
        } else {
            Write-Host "  ⚠️  CHECK: $folder/ ($itemCount items) - manual review needed" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

if ($removed.Count -gt 0) {
    Write-Host "✅ Removed $($removed.Count) folders:" -ForegroundColor Green
    foreach ($folder in $removed) {
        Write-Host "   - $folder/" -ForegroundColor White
    }
} else {
    Write-Host "ℹ️  No folders removed" -ForegroundColor Gray
}

if ($kept.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ Kept $($kept.Count) folders:" -ForegroundColor Green
    foreach ($folder in $kept) {
        Write-Host "   - $folder/" -ForegroundColor White
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - No folders removed. Run without -DryRun to clean up." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

