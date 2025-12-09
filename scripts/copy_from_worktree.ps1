# Copy all changes from worktree to main repo
$worktreePath = "C:\Users\Dell\.cursor\worktrees\AurumHarmonyTest\ljn"
$mainRepoPath = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"

Set-Location $worktreePath

# Get all changed and new files
$allFiles = @()

# Get modified and added files
$staged = git diff --cached --name-only 2>$null
$modified = git diff --name-only 2>$null
$untracked = git ls-files --others --exclude-standard 2>$null

$allFiles += $staged
$allFiles += $modified
$allFiles += $untracked

# Remove duplicates
$allFiles = $allFiles | Select-Object -Unique

Write-Host "Copying $($allFiles.Count) files from worktree to main repo..." -ForegroundColor Cyan

$copied = 0
$failed = 0

foreach ($file in $allFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    
    $src = Join-Path $worktreePath $file
    $dst = Join-Path $mainRepoPath $file
    
    if (Test-Path $src) {
        try {
            $dstDir = Split-Path $dst -Parent
            if ($dstDir -and -not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Copy-Item $src $dst -Force -ErrorAction Stop
            $copied++
            if ($copied % 50 -eq 0) {
                Write-Host "  Copied $copied files..." -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Failed to copy: $file - $_" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host "`n✅ Copy complete: $copied files copied, $failed failed" -ForegroundColor Green



