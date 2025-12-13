# Fix Minikube Directory Permissions on Windows
# Run this script as Administrator if needed

Write-Host "=== Fixing Minikube Directory Permissions ===" -ForegroundColor Cyan
Write-Host ""

$minikubeDir = "$env:USERPROFILE\.minikube"

# Check if directory exists
if (Test-Path $minikubeDir) {
    Write-Host "[1] Found existing .minikube directory" -ForegroundColor Yellow
    Write-Host "    Path: $minikubeDir" -ForegroundColor Gray
    
    # Try to remove it (will fail if in use)
    try {
        Write-Host "[2] Attempting to remove existing directory..." -ForegroundColor Yellow
        Remove-Item -Path $minikubeDir -Recurse -Force -ErrorAction Stop
        Write-Host "    [OK] Directory removed" -ForegroundColor Green
    } catch {
        Write-Host "    [WARN] Could not remove directory: $_" -ForegroundColor Yellow
        Write-Host "    [INFO] Directory may be in use. Try stopping minikube first:" -ForegroundColor Gray
        Write-Host "           minikube stop" -ForegroundColor Gray
        Write-Host ""
        Write-Host "    Attempting to fix permissions instead..." -ForegroundColor Yellow
        
        # Fix permissions on existing directory
        try {
            $acl = Get-Acl $minikubeDir
            $permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
            $acl.SetAccessRule($accessRule)
            Set-Acl $minikubeDir $acl
            Write-Host "    [OK] Permissions fixed" -ForegroundColor Green
        } catch {
            Write-Host "    [ERROR] Could not fix permissions: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "    Manual fix required:" -ForegroundColor Yellow
            Write-Host "    1. Right-click C:\Users\Dell\.minikube" -ForegroundColor Gray
            Write-Host "    2. Properties > Security > Edit" -ForegroundColor Gray
            Write-Host "    3. Add your user with Full Control" -ForegroundColor Gray
            exit 1
        }
    }
} else {
    Write-Host "[1] .minikube directory does not exist (will be created by minikube)" -ForegroundColor Green
}

# Create directory with proper permissions
Write-Host ""
Write-Host "[3] Creating .minikube directory with proper permissions..." -ForegroundColor Yellow
try {
    New-Item -Path $minikubeDir -ItemType Directory -Force | Out-Null
    
    # Set permissions
    $acl = Get-Acl $minikubeDir
    $permission = "$env:USERNAME", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $minikubeDir $acl
    
    Write-Host "    [OK] Directory created with proper permissions" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Could not create directory: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Try running PowerShell as Administrator:" -ForegroundColor Yellow
    Write-Host "    1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "    2. 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "    3. Run this script again" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "[4] Verifying permissions..." -ForegroundColor Yellow
$testFile = Join-Path $minikubeDir "test.txt"
try {
    "test" | Out-File -FilePath $testFile -Force
    Remove-Item $testFile -Force
    Write-Host "    [OK] Write permissions verified" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Write test failed: $_" -ForegroundColor Red
    Write-Host "    Permissions may still be incorrect" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Try running minikube again" -ForegroundColor White
Write-Host "  2. If it still fails, check Windows Defender/Antivirus exclusions" -ForegroundColor White
Write-Host "  3. Alternative: Use minikube with --profile flag to use different directory" -ForegroundColor White
Write-Host ""

