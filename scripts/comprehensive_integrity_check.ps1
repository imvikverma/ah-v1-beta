# Comprehensive System & Project Integrity Check
# Verifies project is at production-ready state (Dec 20, 2025)

param(
    [switch]$Quick = $false,
    [switch]$Fix = $false
)

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

$checkErrors = @()
$checkWarnings = @()
$checkPassed = @()

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  AURUMHARMONY COMPREHENSIVE INTEGRITY CHECK            ║" -ForegroundColor Yellow
Write-Host "║  Target State: Production Ready (Dec 20, 2025)          ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Essential Files & Folders
Write-Host "1. CHECKING ESSENTIAL FILES & FOLDERS..." -ForegroundColor Yellow
Write-Host ""

$essentialFiles = @(
    "start-all.ps1",
    "requirements.txt",
    "README.md",
    "CHANGELOG.md",
    "wrangler.toml",
    "render.yaml",
    ".gitignore"
)

$essentialFolders = @(
    "aurum_harmony",
    "engines",
    "scripts",
    "worker",
    "templates",
    "aurum_harmony\master_codebase",
    "aurum_harmony\engines",
    "aurum_harmony\frontend",
    "aurum_harmony\admin",
    "engines\backtesting",
    "engines\compliance",
    "engines\fund_push_pull",
    "engines\notifications",
    "engines\predictive_ai",
    "engines\risk_management",
    "engines\settlement",
    "engines\white_label"
)

foreach ($file in $essentialFiles) {
    $path = Join-Path $projectRoot $file
    if (Test-Path $path) {
        $checkPassed += "✅ $file"
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        $checkErrors += "❌ Missing: $file"
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
    }
}

foreach ($folder in $essentialFolders) {
    $path = Join-Path $projectRoot $folder
    if (Test-Path $path) {
        $checkPassed += "✅ $folder/"
        Write-Host "  ✅ $folder/" -ForegroundColor Green
    } else {
        $checkErrors += "❌ Missing: $folder/"
        Write-Host "  ❌ Missing: $folder/" -ForegroundColor Red
    }
}

# 2. Core Modules
Write-Host ""
Write-Host "2. CHECKING CORE MODULES..." -ForegroundColor Yellow
Write-Host ""

$coreModules = @(
    "aurum_harmony\master_codebase\Master_AurumHarmony_261125.py",
    "aurum_harmony\app\orchestrator.py",
    "aurum_harmony\app\routes.py",
    "aurum_harmony\engines\backtesting\backtesting.py",
    "engines\compliance\SEBI_Compliance_Engine.py",
    "engines\risk_management\Risk_Management_Engine.py",
    "engines\settlement\Settlement_Engine.py",
    "engines\predictive_ai\Predictive_AI_Engine.py",
    "engines\white_label\AH_White_Label_Plugin.py"
)

foreach ($module in $coreModules) {
    $path = Join-Path $projectRoot $module
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -gt 0) {
            $checkPassed += "✅ $module"
            Write-Host "  ✅ $module ($([math]::Round($size/1KB, 1)) KB)" -ForegroundColor Green
        } else {
            $checkErrors += "❌ Empty: $module"
            Write-Host "  ❌ Empty: $module" -ForegroundColor Red
        }
    } else {
        $checkErrors += "❌ Missing: $module"
        Write-Host "  ❌ Missing: $module" -ForegroundColor Red
    }
}

# 3. Virtual Environment
Write-Host ""
Write-Host "3. CHECKING VIRTUAL ENVIRONMENT..." -ForegroundColor Yellow
Write-Host ""

$venvPath = Join-Path $projectRoot ".venv"
if (Test-Path $venvPath) {
    $hasScripts = Test-Path (Join-Path $venvPath "Scripts\Activate.ps1")
    $hasLib = Test-Path (Join-Path $venvPath "Lib")
    $hasPyvenv = Test-Path (Join-Path $venvPath "pyvenv.cfg")
    
    if ($hasScripts -and $hasLib -and $hasPyvenv) {
        $checkPassed += "✅ .venv complete"
        Write-Host "  ✅ .venv folder exists and is complete" -ForegroundColor Green
        
        # Check if activated
        if ($env:VIRTUAL_ENV) {
            Write-Host "  ✅ Venv is currently activated" -ForegroundColor Green
        } else {
            $checkWarnings += "⚠️  Venv not activated (run fix_venv_activation.ps1)"
            Write-Host "  ⚠️  Venv not activated" -ForegroundColor Yellow
        }
    } else {
        $checkErrors += "❌ .venv incomplete (missing Scripts/ or Lib/)"
        Write-Host "  ❌ .venv incomplete" -ForegroundColor Red
        Write-Host "     Missing Scripts/: $(if(-not $hasScripts){'Yes'}else{'No'})" -ForegroundColor Gray
        Write-Host "     Missing Lib/: $(if(-not $hasLib){'Yes'}else{'No'})" -ForegroundColor Gray
    }
} else {
    $checkErrors += "❌ .venv folder missing"
    Write-Host "  ❌ .venv folder missing" -ForegroundColor Red
}

# 4. Python Dependencies
Write-Host ""
Write-Host "4. CHECKING PYTHON DEPENDENCIES..." -ForegroundColor Yellow
Write-Host ""

if ($env:VIRTUAL_ENV) {
    $requiredPackages = @("flask", "flask-cors", "requests", "python-dotenv")
    foreach ($pkg in $requiredPackages) {
        $result = pip show $pkg 2>&1
        if ($LASTEXITCODE -eq 0) {
            $version = ($result | Select-String "Version:").ToString().Split(":")[1].Trim()
            $checkPassed += "✅ $pkg ($version)"
            Write-Host "  ✅ $pkg ($version)" -ForegroundColor Green
        } else {
            $checkErrors += "❌ Missing package: $pkg"
            Write-Host "  ❌ Missing: $pkg" -ForegroundColor Red
        }
    }
} else {
    $checkWarnings += "⚠️  Cannot check dependencies (venv not activated)"
    Write-Host "  ⚠️  Skipping (venv not activated)" -ForegroundColor Yellow
}

# 5. Database Setup
Write-Host ""
Write-Host "5. CHECKING DATABASE SETUP..." -ForegroundColor Yellow
Write-Host ""

$dbFiles = @(
    "aurum_harmony.db",
    "worker\schema.sql",
    "worker\data_migration.sql"
)

foreach ($dbFile in $dbFiles) {
    $path = Join-Path $projectRoot $dbFile
    if (Test-Path $path) {
        $checkPassed += "✅ $dbFile"
        Write-Host "  ✅ $dbFile" -ForegroundColor Green
    } else {
        $checkWarnings += "⚠️  Missing: $dbFile"
        Write-Host "  ⚠️  Missing: $dbFile" -ForegroundColor Yellow
    }
}

# 6. Configuration Files
Write-Host ""
Write-Host "6. CHECKING CONFIGURATION FILES..." -ForegroundColor Yellow
Write-Host ""

$configFiles = @(
    "wrangler.toml",
    "render.yaml",
    "requirements.txt"
)

foreach ($config in $configFiles) {
    $path = Join-Path $projectRoot $config
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content.Length -gt 0) {
            $checkPassed += "✅ $config"
            Write-Host "  ✅ $config" -ForegroundColor Green
        } else {
            $checkErrors += "❌ Empty: $config"
            Write-Host "  ❌ Empty: $config" -ForegroundColor Red
        }
    } else {
        $checkErrors += "❌ Missing: $config"
        Write-Host "  ❌ Missing: $config" -ForegroundColor Red
    }
}

# 7. Essential Scripts
Write-Host ""
Write-Host "7. CHECKING ESSENTIAL SCRIPTS..." -ForegroundColor Yellow
Write-Host ""

$essentialScripts = @(
    "scripts\start_backend.ps1",
    "scripts\start_flutter.ps1",
    "scripts\start_both.ps1",
    "scripts\deploy_cloudflare.ps1",
    "scripts\deploy_worker.ps1"
)

foreach ($script in $essentialScripts) {
    $path = Join-Path $projectRoot $script
    if (Test-Path $path) {
        $checkPassed += "✅ $script"
        Write-Host "  ✅ $script" -ForegroundColor Green
    } else {
        $checkErrors += "❌ Missing: $script"
        Write-Host "  ❌ Missing: $script" -ForegroundColor Red
    }
}

# 8. Trading Calendar & Scheduler
Write-Host ""
Write-Host "8. CHECKING TRADING FEATURES..." -ForegroundColor Yellow
Write-Host ""

$tradingFeatures = @(
    "aurum_harmony\engines\timing\trading_scheduler.py"
)

foreach ($feature in $tradingFeatures) {
    $path = Join-Path $projectRoot $feature
    if (Test-Path $path) {
        $checkPassed += "✅ $feature"
        Write-Host "  ✅ $feature" -ForegroundColor Green
    } else {
        $checkErrors += "❌ Missing: $feature"
        Write-Host "  ❌ Missing: $feature" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    SUMMARY                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Passed: $($checkPassed.Count)" -ForegroundColor Green
Write-Host "⚠️  Warnings: $($checkWarnings.Count)" -ForegroundColor Yellow
Write-Host "❌ Errors: $($checkErrors.Count)" -ForegroundColor Red
Write-Host ""

if ($checkErrors.Count -eq 0 -and $checkWarnings.Count -eq 0) {
    Write-Host "🎉 PROJECT IS PRODUCTION READY!" -ForegroundColor Green
    Write-Host "   All checks passed - ready for broker API integration" -ForegroundColor Green
} elseif ($checkErrors.Count -eq 0) {
    Write-Host "✅ PROJECT IS MOSTLY READY" -ForegroundColor Yellow
    Write-Host "   Some warnings to address, but core functionality OK" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Warnings:" -ForegroundColor Yellow
    foreach ($warning in $checkWarnings) {
        Write-Host "  $warning" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ PROJECT NEEDS ATTENTION" -ForegroundColor Red
    Write-Host "   Critical issues found - fix before proceeding" -ForegroundColor Red
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($err in $checkErrors) {
        Write-Host "  $err" -ForegroundColor Gray
    }
    if ($checkWarnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $checkWarnings) {
            Write-Host "  $warning" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
if ($checkErrors -match "venv") {
    Write-Host "  1. Run rebuild_flask_env.ps1 to fix venv" -ForegroundColor Yellow
}
if ($checkErrors -match "Missing package") {
    Write-Host "  2. Activate venv and run: pip install -r requirements.txt" -ForegroundColor Yellow
}
if ($checkErrors.Count -eq 0) {
    Write-Host "  1. ✅ Ready for broker API integration" -ForegroundColor Green
    Write-Host "  2. ✅ Ready for live testing" -ForegroundColor Green
}

Write-Host ""

