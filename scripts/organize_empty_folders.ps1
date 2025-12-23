# Organize Empty Folders
# Checks and removes empty folders: tools, utils, zzz-quick-access
# Handles templates and worker separately

param(
    [switch]$DryRun = $false
)

Write-Host "=== ORGANIZING EMPTY FOLDERS ===" -ForegroundColor Cyan
Write-Host ""

$emptyFolders = @("tools", "utils", "zzz-quick-access")
$stats = @{
    "removed" = 0
    "kept" = 0
    "checked" = 0
}

# Check and remove empty folders
Write-Host "1. Checking empty folders..." -ForegroundColor Yellow
Write-Host ""

foreach ($folder in $emptyFolders) {
    if (Test-Path $folder) {
        $items = Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue
        if (-not $items) {
            if (-not $DryRun) {
                Remove-Item -Path $folder -Force -ErrorAction SilentlyContinue
                Write-Host "  ✅ Removed empty: $folder/" -ForegroundColor Green
                $stats["removed"]++
            } else {
                Write-Host "  [DRY RUN] Would remove: $folder/" -ForegroundColor Cyan
                $stats["removed"]++
            }
        } else {
            Write-Host "  ⚠️  Not empty: $folder/ ($($items.Count) items)" -ForegroundColor Yellow
            $stats["kept"]++
        }
    } else {
        Write-Host "  ℹ️  Not found: $folder/" -ForegroundColor Gray
    }
    $stats["checked"]++
}

Write-Host ""
Write-Host "2. Checking templates folder..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "templates") {
    $templateFiles = Get-ChildItem "templates" -File
    if ($templateFiles) {
        Write-Host "  ℹ️  Templates folder contains files:" -ForegroundColor Gray
        $templateFiles | ForEach-Object {
            Write-Host "     - $($_.Name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  ⚠️  Templates folder is NOT empty" -ForegroundColor Yellow
        Write-Host "     These may be essential HTML templates" -ForegroundColor Gray
        Write-Host "     Keeping templates/ folder" -ForegroundColor Green
    } else {
        if (-not $DryRun) {
            Remove-Item -Path "templates" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Removed empty: templates/" -ForegroundColor Green
            $stats["removed"]++
        } else {
            Write-Host "  [DRY RUN] Would remove: templates/" -ForegroundColor Cyan
            $stats["removed"]++
        }
    }
} else {
    Write-Host "  ℹ️  Templates folder not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "3. Checking worker folder..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "worker") {
    $workerFiles = Get-ChildItem "worker" -Recurse -File -ErrorAction SilentlyContinue
    if ($workerFiles) {
        Write-Host "  ℹ️  Worker folder contains files:" -ForegroundColor Gray
        Write-Host "     - TypeScript source files" -ForegroundColor White
        Write-Host "     - SQL schema files" -ForegroundColor White
        Write-Host "     - package.json" -ForegroundColor White
        Write-Host "     Total: $($workerFiles.Count) files" -ForegroundColor White
        Write-Host ""
        Write-Host "  ⚠️  Worker folder is NOT empty" -ForegroundColor Yellow
        Write-Host "     This is Cloudflare Worker code (ESSENTIAL)" -ForegroundColor Gray
        Write-Host "     Keeping worker/ folder" -ForegroundColor Green
    } else {
        if (-not $DryRun) {
            Remove-Item -Path "worker" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Removed empty: worker/" -ForegroundColor Green
            $stats["removed"]++
        } else {
            Write-Host "  [DRY RUN] Would remove: worker/" -ForegroundColor Cyan
            $stats["removed"]++
        }
    }
} else {
    Write-Host "  ℹ️  Worker folder not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== STATISTICS ===" -ForegroundColor Cyan
Write-Host "  Checked: $($stats['checked']) folders" -ForegroundColor White
Write-Host "  Removed: $($stats['removed']) empty folders" -ForegroundColor Green
Write-Host "  Kept: $($stats['kept']) non-empty folders" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - No folders removed. Run without -DryRun to clean up." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Empty folders organized!" -ForegroundColor Green
}

