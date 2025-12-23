# AurumHarmony Project Backup Script
# Creates comprehensive backup of essential project files
# Designed to run nightly after EOD flow

param(
    [string]$BackupLocation = "",
    [switch]$FullBackup = $false,
    [switch]$Verify = $true,
    [switch]$Compress = $true
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AurumHarmony Project Backup" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

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

# Determine backup location
if ([string]::IsNullOrEmpty($BackupLocation)) {
    $BackupLocation = Join-Path $projectRoot "_local\backups"
}

# Create backup directory with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $BackupLocation "backup_$timestamp"

# Ensure backup location exists
New-Item -ItemType Directory -Path $BackupLocation -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "[1] Backup Configuration" -ForegroundColor Yellow
Write-Host "  Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "  Backup Location: $backupDir" -ForegroundColor Gray
Write-Host "  Full Backup: $FullBackup" -ForegroundColor Gray
Write-Host "  Compress: $Compress" -ForegroundColor Gray
Write-Host ""

# Define essential files and folders to backup
$essentialPaths = @(
    # Core application code
    "aurum_harmony",
    "api",
    "engines",
    "config",
    "scripts",
    "worker",
    "templates",
    
    # Configuration files
    "requirements.txt",
    "wrangler.toml",
    "render.yaml",
    ".gitignore",
    "README.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "RELEASES.md",
    "FILE_STRUCTURE.md",
    "start-all.ps1",
    "start-backend.ps1",
    "rebuild_flask_env.ps1",
    
    # GitHub workflows
    ".github",
    
    # Database (if exists)
    "*.db",
    "*.sqlite",
    "*.sqlite3",
    
    # Documentation (essential only)
    "DEPLOYMENT_GUIDE.md",
    "DEPLOYMENT_STEP_BY_STEP.md",
    "AurumHarmony_Intro.md",
    "AurumHarmony_Simple_Intro.md"
)

# Exclude patterns
$excludePatterns = @(
    "**/__pycache__/**",
    "**/*.pyc",
    "**/.venv/**",
    "**/node_modules/**",
    "**/.git/**",
    "**/logs/**",
    "**/_local/backups/**",
    "**/_local/cache/**",
    "**/_local/temporary/**",
    "**/build/**",
    "**/dist/**",
    "**/.pytest_cache/**",
    "**/.mypy_cache/**",
    "**/.idea/**",
    "**/.vscode/**",
    "**/*.log",
    "**/docs/**",  # Flutter build output
    "**/Recovered/**",
    "**/backup/**",
    "**/Old_Files/**",
    "**/Code_Files/**"
)

Write-Host "[2] Starting Backup..." -ForegroundColor Yellow

$backupStats = @{
    FilesCopied = 0
    FoldersCopied = 0
    Errors = 0
    SizeBytes = 0
}

# Function to copy files with progress
function Copy-ProjectFiles {
    param(
        [string]$Source,
        [string]$Destination,
        [string[]]$ExcludePatterns
    )
    
    $sourcePath = Join-Path $projectRoot $Source
    $destPath = Join-Path $backupDir $Source
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  [SKIP] $Source (not found)" -ForegroundColor Gray
        return
    }
    
    try {
        $item = Get-Item $sourcePath
        
        # Check if should be excluded
        $shouldExclude = $false
        foreach ($pattern in $ExcludePatterns) {
            if ($sourcePath -like $pattern) {
                $shouldExclude = $true
                break
            }
        }
        
        if ($shouldExclude) {
            Write-Host "  [SKIP] $Source (excluded)" -ForegroundColor Gray
            return
        }
        
        if ($item.PSIsContainer) {
            # Copy directory
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            
            # Use Robocopy for better performance and exclusion
            $robocopyArgs = @(
                $sourcePath,
                $destPath,
                "/E",  # Copy subdirectories
                "/NFL",  # No file list
                "/NDL",  # No directory list
                "/NJH",  # No job header
                "/NJS",  # No job summary
                "/R:3",  # Retry 3 times
                "/W:1"   # Wait 1 second between retries
            )
            
            # Add exclusions
            $robocopyArgs += "/XD"
            $robocopyArgs += "__pycache__", ".venv", "node_modules", ".git", "logs", "build", "dist", ".pytest_cache", ".mypy_cache", ".idea", ".vscode", "docs", "Recovered", "backup", "Old_Files", "Code_Files"
            
            $robocopyArgs += "/XF"
            $robocopyArgs += "*.pyc", "*.log", "*.tmp"
            
            $result = & robocopy @robocopyArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            # Robocopy returns 0-7 for success
            if ($exitCode -le 7) {
                $backupStats.FoldersCopied++
                $fileCount = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
                $backupStats.FilesCopied += $fileCount
                $size = (Get-ChildItem $destPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $backupStats.SizeBytes += $size
                Write-Host "  [OK] $Source ($fileCount files)" -ForegroundColor Green
            } else {
                Write-Host "  [ERROR] $Source (robocopy exit code: $exitCode)" -ForegroundColor Red
                $backupStats.Errors++
            }
        } else {
            # Copy file
            $destDir = Split-Path -Parent $destPath
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
            $backupStats.FilesCopied++
            $size = (Get-Item $destPath).Length
            $backupStats.SizeBytes += $size
            Write-Host "  [OK] $Source" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [ERROR] $Source : $_" -ForegroundColor Red
        $backupStats.Errors++
    }
}

# Backup essential paths
foreach ($path in $essentialPaths) {
    Copy-ProjectFiles -Source $path -Destination $backupDir -ExcludePatterns $excludePatterns
}

# Create backup manifest
Write-Host "`n[3] Creating Backup Manifest..." -ForegroundColor Yellow

$manifest = @{
    timestamp = $timestamp
    date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $projectRoot
    backup_location = $backupDir
    files_copied = $backupStats.FilesCopied
    folders_copied = $backupStats.FoldersCopied
    errors = $backupStats.Errors
    size_bytes = $backupStats.SizeBytes
    size_mb = [math]::Round($backupStats.SizeBytes / 1MB, 2)
    git_commit = ""
    git_branch = ""
}

# Get git info if available
try {
    Push-Location $projectRoot
    $gitCommit = git rev-parse HEAD 2>$null
    $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($gitCommit) {
        $manifest.git_commit = $gitCommit
        $manifest.git_branch = $gitBranch
    }
} catch {
    # Git not available or not a git repo
}

$manifestPath = Join-Path $backupDir "backup_manifest.json"
$manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $manifestPath -Encoding UTF8
Write-Host "  [OK] Manifest created: backup_manifest.json" -ForegroundColor Green

# Compress backup if requested
if ($Compress) {
    Write-Host "`n[4] Compressing Backup..." -ForegroundColor Yellow
    $zipPath = "$backupDir.zip"
    try {
        Compress-Archive -Path $backupDir -DestinationPath $zipPath -Force -ErrorAction Stop
        $zipSize = (Get-Item $zipPath).Length
        $zipSizeMB = [math]::Round($zipSize / 1MB, 2)
        Write-Host "  [OK] Backup compressed: $zipSizeMB MB" -ForegroundColor Green
        
        # Remove uncompressed folder
        Remove-Item -Path $backupDir -Recurse -Force
        Write-Host "  [OK] Uncompressed folder removed" -ForegroundColor Green
        
        $manifest.compressed = $true
        $manifest.compressed_size_bytes = $zipSize
        $manifest.compressed_size_mb = $zipSizeMB
        $manifest.backup_location = $zipPath
    } catch {
        Write-Host "  [WARN] Compression failed: $_" -ForegroundColor Yellow
        $manifest.compressed = $false
    }
}

# Verify backup
if ($Verify) {
    Write-Host "`n[5] Verifying Backup..." -ForegroundColor Yellow
    
    $verifyPath = if ($Compress -and (Test-Path "$backupDir.zip")) {
        "$backupDir.zip"
    } else {
        $backupDir
    }
    
    if (Test-Path $verifyPath) {
        if ($Compress -and (Test-Path "$backupDir.zip")) {
            # Verify zip file
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::OpenRead($verifyPath)
                $entryCount = $zip.Entries.Count
                $zip.Dispose()
                Write-Host "  [OK] Backup verified: $entryCount entries" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Backup verification failed: $_" -ForegroundColor Red
            }
        } else {
            # Verify directory
            $fileCount = (Get-ChildItem $verifyPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host "  [OK] Backup verified: $fileCount files" -ForegroundColor Green
        }
    } else {
        Write-Host "  [ERROR] Backup not found!" -ForegroundColor Red
    }
}

# Cleanup old backups (keep last 7 days)
Write-Host "`n[6] Cleaning Up Old Backups..." -ForegroundColor Yellow
try {
    $backupFiles = Get-ChildItem -Path $BackupLocation -Filter "backup_*.zip" -ErrorAction SilentlyContinue
    $backupDirs = Get-ChildItem -Path $BackupLocation -Directory -Filter "backup_*" -ErrorAction SilentlyContinue
    
    $cutoffDate = (Get-Date).AddDays(-7)
    $removed = 0
    
    foreach ($backup in $backupFiles) {
        if ($backup.LastWriteTime -lt $cutoffDate) {
            Remove-Item -Path $backup.FullName -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    
    foreach ($backup in $backupDirs) {
        if ($backup.LastWriteTime -lt $cutoffDate) {
            Remove-Item -Path $backup.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    
    if ($removed -gt 0) {
        Write-Host "  [OK] Removed $removed old backup(s)" -ForegroundColor Green
    } else {
        Write-Host "  [OK] No old backups to remove" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARN] Cleanup failed: $_" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Backup Complete" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Files Copied: $($backupStats.FilesCopied)" -ForegroundColor White
Write-Host "  Folders Copied: $($backupStats.FoldersCopied)" -ForegroundColor White
Write-Host "  Size: $($manifest.size_mb) MB" -ForegroundColor White
if ($manifest.compressed) {
    Write-Host "  Compressed Size: $($manifest.compressed_size_mb) MB" -ForegroundColor White
}
Write-Host "  Errors: $($backupStats.Errors)" -ForegroundColor $(if ($backupStats.Errors -eq 0) { "Green" } else { "Red" })
Write-Host "  Location: $($manifest.backup_location)" -ForegroundColor White
if ($manifest.git_commit) {
    Write-Host "  Git Commit: $($manifest.git_commit.Substring(0, 7))" -ForegroundColor White
    Write-Host "  Git Branch: $($manifest.git_branch)" -ForegroundColor White
}

Write-Host ""

# Save summary to log
$logPath = Join-Path $BackupLocation "backup_log.txt"
$logEntry = "$($manifest.date) | Files: $($backupStats.FilesCopied) | Size: $($manifest.size_mb) MB | Errors: $($backupStats.Errors) | Location: $($manifest.backup_location)`n"
Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue

if ($backupStats.Errors -eq 0) {
    Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Backup completed with errors. Review output above." -ForegroundColor Yellow
    exit 1
}

