# Mirror Project to VS Code Workspace
# Creates a mirror/snapshot of the project for VS Code backup
# Useful when hitting usage limits or need quick recovery

param(
    [string]$VSCodeWorkspacePath = "",
    [switch]$CreateWorkspace = $true,
    [switch]$SyncGit = $true
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VS Code Workspace Mirror" -ForegroundColor Yellow
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

# Determine VS Code workspace location
if ([string]::IsNullOrEmpty($VSCodeWorkspacePath)) {
    # Default: Create in parent directory with timestamp
    $parentDir = Split-Path -Parent $projectRoot
    $projectName = Split-Path -Leaf $projectRoot
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $VSCodeWorkspacePath = Join-Path $parentDir "${projectName}_vscode_backup_$timestamp"
}

Write-Host "[1] Configuration" -ForegroundColor Yellow
Write-Host "  Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "  VS Code Workspace: $VSCodeWorkspacePath" -ForegroundColor Gray
Write-Host "  Create Workspace: $CreateWorkspace" -ForegroundColor Gray
Write-Host "  Sync Git: $SyncGit" -ForegroundColor Gray
Write-Host ""

# Create VS Code workspace directory
if ($CreateWorkspace) {
    Write-Host "[2] Creating VS Code Workspace..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $VSCodeWorkspacePath -Force | Out-Null
    Write-Host "  [OK] Workspace directory created" -ForegroundColor Green
}

# Create .vscode folder in workspace
$vscodeConfigDir = Join-Path $VSCodeWorkspacePath ".vscode"
New-Item -ItemType Directory -Path $vscodeConfigDir -Force | Out-Null

# Create workspace settings
Write-Host "`n[3] Creating Workspace Settings..." -ForegroundColor Yellow

$workspaceSettings = @{
    folders = @(
        @{
            name = "AurumHarmony"
            path = "."
        }
    )
    settings = @{
        "files.exclude" = @{
            "**/.venv" = $true
            "**/node_modules" = $true
            "**/__pycache__" = $true
            "**/*.pyc" = $true
            "**/.git" = $true
            "**/logs" = $true
            "**/_local/backups" = $true
            "**/_local/cache" = $true
            "**/_local/temporary" = $true
            "**/build" = $true
            "**/dist" = $true
            "**/docs" = $true
        }
        "python.defaultInterpreterPath" = ".venv\Scripts\python.exe"
        "python.terminal.activateEnvironment" = $true
        "files.watcherExclude" = @{
            "**/.venv/**" = $true
            "**/node_modules/**" = $true
            "**/_local/backups/**" = $true
            "**/_local/cache/**" = $true
        }
    }
    extensions = @{
        recommendations = @(
            "ms-python.python",
            "ms-python.vscode-pylance",
            "dart-code.dart-code",
            "dart-code.flutter"
        )
    }
}

$workspaceFile = Join-Path $VSCodeWorkspacePath "aurumharmony.code-workspace"
$workspaceSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $workspaceFile -Encoding UTF8
Write-Host "  [OK] Workspace file created: aurumharmony.code-workspace" -ForegroundColor Green

# Mirror essential files using robocopy
Write-Host "`n[4] Mirroring Project Files..." -ForegroundColor Yellow

$robocopyArgs = @(
    $projectRoot,
    $VSCodeWorkspacePath,
    "/E",  # Copy subdirectories
    "/NFL",  # No file list
    "/NDL",  # No directory list
    "/NJH",  # No job header
    "/NJS",  # No job summary
    "/R:3",  # Retry 3 times
    "/W:1",  # Wait 1 second between retries
    "/XD"    # Exclude directories
)

# Exclude unnecessary directories
$robocopyArgs += "__pycache__", ".venv", "node_modules", ".git", "logs", "build", "dist", ".pytest_cache", ".mypy_cache", ".idea", "docs", "Recovered", "backup", "Old_Files", "Code_Files", "_local\backups", "_local\cache", "_local\temporary"

$robocopyArgs += "/XF"  # Exclude files
$robocopyArgs += "*.pyc", "*.log", "*.tmp", "*.zip"

$result = & robocopy @robocopyArgs 2>&1
$exitCode = $LASTEXITCODE

# Robocopy returns 0-7 for success
if ($exitCode -le 7) {
    $fileCount = (Get-ChildItem $VSCodeWorkspacePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $size = (Get-ChildItem $VSCodeWorkspacePath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    Write-Host "  [OK] Files mirrored: $fileCount files ($sizeMB MB)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Mirroring failed (exit code: $exitCode)" -ForegroundColor Red
    exit 1
}

# Sync git if requested
if ($SyncGit -and (Test-Path (Join-Path $projectRoot ".git"))) {
    Write-Host "`n[5] Syncing Git Repository..." -ForegroundColor Yellow
    try {
        Push-Location $VSCodeWorkspacePath
        
        # Initialize git if not exists
        if (-not (Test-Path ".git")) {
            git init
            Write-Host "  [OK] Git repository initialized" -ForegroundColor Green
        }
        
        # Add remote if exists in original
        Push-Location $projectRoot
        $remoteUrl = git config --get remote.origin.url 2>$null
        Pop-Location
        
        if ($remoteUrl) {
            Push-Location $VSCodeWorkspacePath
            $existingRemote = git remote get-url origin 2>$null
            if (-not $existingRemote) {
                git remote add origin $remoteUrl
                Write-Host "  [OK] Git remote added: $remoteUrl" -ForegroundColor Green
            }
            Pop-Location
        }
        
        # Create a snapshot commit
        Push-Location $VSCodeWorkspacePath
        git add -A
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "VS Code Mirror Snapshot - $timestamp" -q 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Git snapshot created" -ForegroundColor Green
        }
        Pop-Location
        
    } catch {
        Write-Host "  [WARN] Git sync failed: $_" -ForegroundColor Yellow
    }
}

# Create README in workspace
Write-Host "`n[6] Creating Workspace README..." -ForegroundColor Yellow

$readmeContent = @"
# AurumHarmony VS Code Workspace Backup

**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Source:** $projectRoot

## Purpose

This is a mirror/snapshot of the AurumHarmony project created for VS Code backup.
Use this workspace if you need to recover from usage limit downtime or other issues.

## Opening in VS Code

1. Open VS Code
2. File → Open Workspace from File...
3. Select: `aurumharmony.code-workspace`

## Important Notes

- This is a **read-only backup** - do not make changes here
- Original project is at: $projectRoot
- Git repository is synced but may be behind
- Some files are excluded (see workspace settings)

## Recovery

To restore from this backup:
1. Copy files back to original project location
2. Or use this workspace directly if original is corrupted

## Last Updated

$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$readmePath = Join-Path $VSCodeWorkspacePath "README_BACKUP.md"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
Write-Host "  [OK] README created" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  VS Code Mirror Complete" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Workspace Location: $VSCodeWorkspacePath" -ForegroundColor White
Write-Host "  Workspace File: aurumharmony.code-workspace" -ForegroundColor White
Write-Host "  Files Mirrored: $fileCount" -ForegroundColor White
Write-Host "  Size: $sizeMB MB" -ForegroundColor White
Write-Host ""

Write-Host "To open in VS Code:" -ForegroundColor Yellow
Write-Host "  code `"$workspaceFile`"" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ VS Code workspace mirror created successfully!" -ForegroundColor Green

