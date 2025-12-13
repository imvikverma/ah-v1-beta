# AurumHarmony - Full System Integrity Check
# Comprehensive verification of all system components

$ErrorActionPreference = "Continue"
# Get project root (parent of scripts directory)
$scriptPath = $MyInvocation.MyCommand.Path
$scriptsDir = Split-Path -Parent $scriptPath
$projectRoot = Split-Path -Parent $scriptsDir
Set-Location $projectRoot
Write-Host "Project Root: $projectRoot" -ForegroundColor Gray

Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   AurumHarmony System Integrity Check  ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

$allChecks = @{}
$criticalIssues = @()
$warnings = @()

# ============================================
# 1. PYTHON ENVIRONMENT
# ============================================
Write-Host "[1/10] Python Environment..." -ForegroundColor Cyan

# Check Python 3.11 installation
$python311 = "C:\Python311\python.exe"
if (Test-Path $python311) {
    $pyVersion = & $python311 --version 2>&1
    if ($pyVersion -match "3.11") {
        Write-Host "   [OK] Python 3.11 found: $pyVersion" -ForegroundColor Green
        $allChecks["Python311"] = $true
    } else {
        Write-Host "   [ERROR] Python 3.11 version mismatch: $pyVersion" -ForegroundColor Red
        $allChecks["Python311"] = $false
        $criticalIssues += "Python 3.11 version incorrect"
    }
} else {
    Write-Host "   [ERROR] Python 3.11 not found at: $python311" -ForegroundColor Red
    $allChecks["Python311"] = $false
    $criticalIssues += "Python 3.11 not installed"
}

# Check virtual environment
$venvPath = Join-Path $projectRoot ".venv"
if (Test-Path $venvPath) {
    $venvPython = Join-Path $venvPath "Scripts\python.exe"
    if (Test-Path $venvPython) {
        $venvVersion = & $venvPython --version 2>&1
        Write-Host "   [OK] Virtual environment exists: $venvVersion" -ForegroundColor Green
        $allChecks["VirtualEnv"] = $true
        
        # Check venv config
        $venvCfg = Join-Path $venvPath "pyvenv.cfg"
        if (Test-Path $venvCfg) {
            $venvConfig = Get-Content $venvCfg
            if ($venvConfig -match "3.11") {
                Write-Host "   [OK] Venv configured for Python 3.11" -ForegroundColor Green
            } else {
                Write-Host "   [WARN] Venv may not be Python 3.11" -ForegroundColor Yellow
                $warnings += "Virtual environment Python version unclear"
            }
        }
    } else {
        Write-Host "   [ERROR] Virtual environment incomplete (python.exe missing)" -ForegroundColor Red
        $allChecks["VirtualEnv"] = $false
        $criticalIssues += "Virtual environment incomplete"
    }
} else {
    Write-Host "   [ERROR] Virtual environment not found" -ForegroundColor Red
    $allChecks["VirtualEnv"] = $false
    $criticalIssues += "Virtual environment missing"
}

# ============================================
# 2. PACKAGE INSTALLATIONS
# ============================================
Write-Host "`n[2/10] Package Installations..." -ForegroundColor Cyan

if ($allChecks["VirtualEnv"]) {
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        . $activateScript
        
        $packagesToCheck = @(
            @{Name="Flask"; ExpectedVersion="3.0.3"},
            @{Name="tensorflow"; ExpectedVersion="2.15.0"},
            @{Name="SQLAlchemy"; ExpectedVersion="2.0.23"},
            @{Name="flask-cors"; ExpectedVersion="4.0.1"},
            @{Name="pandas"; ExpectedVersion="2.0.3"},
            @{Name="numpy"; ExpectedVersion="1.24.4"},
            @{Name="scikit-learn"; ExpectedVersion="1.3.2"},
            @{Name="bcrypt"; ExpectedVersion="4.0.1"},
            @{Name="PyJWT"; ExpectedVersion="2.8.0"},
            @{Name="python-dotenv"; ExpectedVersion="1.0.0"}
        )
        
        $packageIssues = 0
        foreach ($pkg in $packagesToCheck) {
            $pkgInfo = pip show $pkg.Name 2>&1
            if ($LASTEXITCODE -eq 0 -and $pkgInfo) {
                $version = ($pkgInfo | Select-String "Version:").ToString() -replace "Version:\s*", ""
                if ($version -eq $pkg.ExpectedVersion) {
                    Write-Host "   [OK] $($pkg.Name): $version" -ForegroundColor Green
                } else {
                    Write-Host "   [WARN] $($pkg.Name): $version (expected: $($pkg.ExpectedVersion))" -ForegroundColor Yellow
                    $warnings += "$($pkg.Name) version mismatch"
                    $packageIssues++
                }
            } else {
                Write-Host "   [ERROR] $($pkg.Name): Not installed" -ForegroundColor Red
                $criticalIssues += "$($pkg.Name) not installed"
                $packageIssues++
            }
        }
        
        if ($packageIssues -eq 0) {
            $allChecks["Packages"] = $true
        } else {
            $allChecks["Packages"] = $false
        }
    } else {
        Write-Host "   [ERROR] Cannot activate virtual environment" -ForegroundColor Red
        $allChecks["Packages"] = $false
    }
} else {
    Write-Host "   [SKIP] Cannot check packages (venv missing)" -ForegroundColor Gray
    $allChecks["Packages"] = $false
}

# ============================================
# 3. FLASK IMPORT TEST
# ============================================
Write-Host "`n[3/10] Flask Import Test..." -ForegroundColor Cyan

if ($allChecks["VirtualEnv"]) {
    try {
        $flaskTest = python -c "import flask; print(f'Flask {flask.__version__}')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] Flask imports successfully: $flaskTest" -ForegroundColor Green
            $allChecks["FlaskImport"] = $true
        } else {
            Write-Host "   [ERROR] Flask import failed: $flaskTest" -ForegroundColor Red
            $allChecks["FlaskImport"] = $false
            $criticalIssues += "Flask cannot be imported"
        }
    } catch {
        Write-Host "   [ERROR] Flask import error: $_" -ForegroundColor Red
        $allChecks["FlaskImport"] = $false
        $criticalIssues += "Flask import exception"
    }
} else {
    Write-Host "   [SKIP] Cannot test Flask import (venv missing)" -ForegroundColor Gray
    $allChecks["FlaskImport"] = $false
}

# ============================================
# 4. CRITICAL FILES
# ============================================
Write-Host "`n[4/10] Critical Files..." -ForegroundColor Cyan

$criticalFiles = @(
    @{Path="aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"; Name="Flask App"},
    @{Path="requirements.txt"; Name="Requirements"},
    @{Path="start-all.ps1"; Name="Start Script"},
    @{Path="scripts\start_backend_silent.ps1"; Name="Backend Script"},
    @{Path="scripts\start_backend_wrapper.bat"; Name="Backend Wrapper"},
    @{Path="rebuild_flask_env.ps1"; Name="Rebuild Script"}
)

$missingFiles = 0
foreach ($file in $criticalFiles) {
    $fullPath = Join-Path $projectRoot $file.Path
    if (Test-Path $fullPath) {
        Write-Host "   [OK] $($file.Name): Found" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] $($file.Name): Missing at $($file.Path)" -ForegroundColor Red
        $missingFiles++
        $criticalIssues += "$($file.Name) missing"
    }
}

if ($missingFiles -eq 0) {
    $allChecks["CriticalFiles"] = $true
} else {
    $allChecks["CriticalFiles"] = $false
}

# ============================================
# 5. DATABASE FILES
# ============================================
Write-Host "`n[5/10] Database Files..." -ForegroundColor Cyan

$dbFile = Join-Path $projectRoot "aurum_harmony.db"
if (Test-Path $dbFile) {
    $dbSize = (Get-Item $dbFile).Length / 1KB
    Write-Host "   [OK] Database file exists: $([math]::Round($dbSize, 2)) KB" -ForegroundColor Green
    $allChecks["Database"] = $true
} else {
    Write-Host "   [INFO] Database file not found (will be created on first run)" -ForegroundColor Yellow
    $allChecks["Database"] = $true  # Not critical, will be created
}

# ============================================
# 6. CONFIGURATION FILES
# ============================================
Write-Host "`n[6/10] Configuration Files..." -ForegroundColor Cyan

$envFile = Join-Path $projectRoot ".env"
if (Test-Path $envFile) {
    $envSize = (Get-Item $envFile).Length
    Write-Host "   [OK] .env file exists: $envSize bytes" -ForegroundColor Green
    $allChecks["Config"] = $true
} else {
    Write-Host "   [WARN] .env file not found (may need broker credentials)" -ForegroundColor Yellow
    $warnings += ".env file missing"
    $allChecks["Config"] = $false
}

# ============================================
# 7. DIRECTORY STRUCTURE
# ============================================
Write-Host "`n[7/10] Directory Structure..." -ForegroundColor Cyan

$requiredDirs = @(
    @{Path="aurum_harmony"; Name="Main App"},
    @{Path="aurum_harmony\master_codebase"; Name="Flask Backend"},
    @{Path="aurum_harmony\frontend"; Name="Flutter Frontend"},
    @{Path="scripts"; Name="Scripts"},
    @{Path="_local\logs"; Name="Logs Directory"}
)

$missingDirs = 0
foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $projectRoot $dir.Path
    if (Test-Path $fullPath) {
        Write-Host "   [OK] $($dir.Name): Exists" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] $($dir.Name): Missing" -ForegroundColor Yellow
        $missingDirs++
        $warnings += "$($dir.Name) directory missing"
    }
}

if ($missingDirs -eq 0) {
    $allChecks["Directories"] = $true
} else {
    $allChecks["Directories"] = $false
}

# ============================================
# 8. POWERSHELL VERSION
# ============================================
Write-Host "`n[8/10] PowerShell Version..." -ForegroundColor Cyan

$psVersion = $PSVersionTable.PSVersion
Write-Host "   [INFO] PowerShell: $psVersion" -ForegroundColor Gray

if ($psVersion.Major -ge 7) {
    Write-Host "   [OK] PowerShell 7+ (compatible)" -ForegroundColor Green
    $allChecks["PowerShell"] = $true
} elseif ($psVersion.Major -eq 5 -and $psVersion.Minor -ge 1) {
    Write-Host "   [OK] PowerShell 5.1+ (compatible)" -ForegroundColor Green
    $allChecks["PowerShell"] = $true
} else {
    Write-Host "   [WARN] PowerShell version may be too old" -ForegroundColor Yellow
    $warnings += "PowerShell version may be outdated"
    $allChecks["PowerShell"] = $true  # Not critical
}

# ============================================
# 9. PORT AVAILABILITY
# ============================================
Write-Host "`n[9/10] Port Availability..." -ForegroundColor Cyan

$portsToCheck = @(
    @{Port=5000; Service="Flask Backend"},
    @{Port=5001; Service="Admin Panel"},
    @{Port=58643; Service="Flutter Frontend"}
)

$portsInUse = 0
foreach ($portInfo in $portsToCheck) {
    $portNum = $portInfo.Port
    $connection = Get-NetTCPConnection -LocalPort $portNum -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "   [WARN] Port $portNum ($($portInfo.Service)): In use" -ForegroundColor Yellow
        $warnings += "Port $portNum already in use"
        $portsInUse++
    } else {
        Write-Host "   [OK] Port $portNum ($($portInfo.Service)): Available" -ForegroundColor Green
    }
}

if ($portsInUse -eq 0) {
    $allChecks["Ports"] = $true
} else {
    $allChecks["Ports"] = $false
}

# ============================================
# 10. PERMISSIONS & ACCESS
# ============================================
Write-Host "`n[10/10] Permissions & Access..." -ForegroundColor Cyan

# Check write access to logs directory
$logsDir = Join-Path $projectRoot "_local\logs"
if (Test-Path $logsDir) {
    try {
        $testFile = Join-Path $logsDir "test_write.tmp"
        "test" | Out-File -FilePath $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction SilentlyContinue
        Write-Host "   [OK] Logs directory: Writable" -ForegroundColor Green
        $allChecks["Permissions"] = $true
    } catch {
        Write-Host "   [ERROR] Logs directory: Not writable" -ForegroundColor Red
        $allChecks["Permissions"] = $false
        $criticalIssues += "Cannot write to logs directory"
    }
} else {
    try {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        Write-Host "   [OK] Logs directory: Created" -ForegroundColor Green
        $allChecks["Permissions"] = $true
    } catch {
        Write-Host "   [ERROR] Cannot create logs directory" -ForegroundColor Red
        $allChecks["Permissions"] = $false
        $criticalIssues += "Cannot create logs directory"
    }
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           INTEGRITY CHECK SUMMARY      ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

$passedChecks = ($allChecks.Values | Where-Object { $_ -eq $true }).Count
$totalChecks = $allChecks.Count
$passRate = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

Write-Host "Checks Passed: $passedChecks / $totalChecks ($passRate%)" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })

if ($criticalIssues.Count -eq 0) {
    Write-Host "`n[OK] No critical issues found!" -ForegroundColor Green
} else {
    Write-Host "`n[ERROR] Critical Issues Found:" -ForegroundColor Red
    foreach ($issue in $criticalIssues) {
        Write-Host "   - $issue" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n[WARN] Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n"

# Return exit code
if ($criticalIssues.Count -eq 0) {
    exit 0
} else {
    exit 1
}

