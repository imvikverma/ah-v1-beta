# Organize Scripts Folder
# Keeps essential scripts, moves rest to _local/development/

param(
    [switch]$DryRun = $false
)

Write-Host "=== ORGANIZING SCRIPTS FOLDER ===" -ForegroundColor Cyan
Write-Host ""

$devPath = "_local\development\scripts"
$brokersDevPath = "_local\development\scripts\brokers"

# Create target directories
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $devPath -Force | Out-Null
    New-Item -ItemType Directory -Path $brokersDevPath -Force | Out-Null
}

# Essential scripts (KEEP in scripts/)
$essentialScripts = @(
    # Core startup scripts
    "start_backend.ps1",
    "start_backend_direct.ps1",
    "start_backend_silent.ps1",
    "start_flutter.ps1",
    "start_flutter_silent.ps1",
    "start_both.ps1",
    "auto_start.ps1",
    "start_ngrok.ps1",
    "start_flask.sh",
    "start_backend_wrapper.bat",
    
    # Deployment scripts
    "deploy_cloudflare.ps1",
    "deploy_worker.ps1",
    "deploy_incremental.ps1",
    "auto_deploy.ps1",
    "trigger_deploy.ps1",
    "watch_and_deploy.ps1",
    
    # Database scripts
    "setup_d1_database.ps1",
    "setup_d1_complete.ps1",
    "migrate_to_d1.ps1",
    "migrate_d1_schema.ps1",
    "migrate_signup_improvements.ps1",
    "sync_sqlite_to_d1.ps1",
    "update_d1_database_id.ps1",
    "fix_database_schema.ps1",
    
    # Admin/User scripts
    "create_admin_user.ps1",
    "create_admin_user.py",
    
    # System checks
    "check_services.ps1",
    "system_verify.ps1",
    "system_integrity_check.ps1",
    "check_production_readiness.ps1",
    
    # EOD and updates
    "run-eod-flow.ps1",
    "update-changelog.ps1",
    "generate-readme.ps1",
    
    # Setup scripts
    "install_wrangler.ps1",
    "setup_fabric_network.ps1",
    "activate_fabric.ps1",
    
    # App entry point
    "app.py"
)

# Development/Test scripts (MOVE to _local/development/scripts/)
$devScripts = @(
    # Recovery scripts
    "assess_recovery.ps1",
    "compare_code_recovery.ps1",
    "full_recovery.ps1",
    "recover_documentation.ps1",
    "recover_missing_modules.ps1",
    "recover_unknown_files.ps1",
    
    # Organization scripts
    "organize_development_files.ps1",
    "organize_documentation_folder.ps1",
    "organize_non_essential_docs.ps1",
    "organize_other_files.ps1",
    "rebuild_local_structure.ps1",
    "find_all_summaries.ps1",
    
    # Utility scripts
    "capture_terminal_output.ps1",
    "quick_share_output.ps1",
    "run_tests.sh",
    "generate-eod-summary.ps1",
    
    # Cleanup scripts
    "cleanup_credentials.ps1",
    "cleanup_old_backup_venvs.ps1",
    "prevent_backup_venv.ps1",
    
    # Fix scripts (non-essential)
    "fix_gitignore_tracking.ps1",
    "fix_minikube_permissions.ps1",
    "fix_venv_activation.ps1",
    "ensure_correct_venv.ps1",
    
    # Other utilities
    "copy_from_worktree.ps1",
    "create_release.ps1",
    "git-non-interactive.ps1",
    
    # Flutter utilities
    "clean_flutter_safe.ps1",
    "restart_flutter_clean.ps1",
    
    # Browser utilities
    "firefox_auto_refresh_bookmarklet.js",
    "firefox_auto_refresh.html",
    
    # Minikube
    "start_minikube_alt.ps1"
)

# Diagnostic/Troubleshooting scripts (MOVE to _local/development/scripts/)
$diagnosticScripts = @(
    "diagnose_login_root_cause.ps1",
    "diagnose_worker.ps1",
    "check_login_issues.ps1",
    "check_cloudflare_worker.ps1",
    "fix_worker.ps1"
)

# Broker scripts to move (non-essential setup/utilities)
$brokerDevScripts = @(
    "brokers\decode_hdfc_jwt.py",
    "brokers\diagnose_hdfc_endpoints.py",
    "brokers\diagnose_hdfc_positions.py",
    "brokers\get_hdfc_request_token.ps1",
    "brokers\get_hdfc_token_id.ps1",
    "brokers\get_fresh_hdfc_token.ps1",
    "brokers\import_hdfc_credentials.ps1",
    "brokers\import_hdfc_token_id.ps1",
    "brokers\import_kotak_credentials.ps1",
    "brokers\update_hdfc_credentials.ps1",
    "brokers\update_hdfc_trading_token.ps1",
    "brokers\add_hdfc_jwt_token.ps1",
    "brokers\add_kotak_token.ps1",
    "brokers\add_kotak_token_direct.ps1",
    "brokers\add_kotak_token_simple.ps1"
)

# Keep these broker scripts (essential):
# - setup_hdfc_sky.ps1
# - setup_kotak_credentials.ps1

$stats = @{
    "kept" = 0
    "moved_dev" = 0
    "moved_diagnostic" = 0
    "moved_broker" = 0
}

Write-Host "1. Categorizing scripts..." -ForegroundColor Yellow
Write-Host ""

# Process root scripts
$allScripts = Get-ChildItem "scripts" -File | Where-Object { $_.Name -notlike "README*" -and $_.Name -notlike "AUTO_*" }

foreach ($script in $allScripts) {
    $scriptName = $script.Name
    
    # Skip the organization script itself
    if ($scriptName -eq "organize_scripts_folder.ps1") {
        Write-Host "  ℹ️  SKIP (self): $scriptName" -ForegroundColor Gray
        continue
    }
    
    if ($essentialScripts -contains $scriptName) {
        Write-Host "  ✅ KEEP: $scriptName" -ForegroundColor Green
        $stats["kept"]++
    } elseif ($devScripts -contains $scriptName) {
        $targetPath = Join-Path $devPath $scriptName
        if (-not $DryRun) {
            Move-Item -Path $script.FullName -Destination $targetPath -Force
            Write-Host "  📦 MOVE (dev): $scriptName" -ForegroundColor Yellow
        } else {
            Write-Host "  [DRY RUN] Would move (dev): $scriptName" -ForegroundColor Cyan
        }
        $stats["moved_dev"]++
    } elseif ($diagnosticScripts -contains $scriptName) {
        $targetPath = Join-Path $devPath $scriptName
        if (-not $DryRun) {
            Move-Item -Path $script.FullName -Destination $targetPath -Force
            Write-Host "  🔍 MOVE (diagnostic): $scriptName" -ForegroundColor Magenta
        } else {
            Write-Host "  [DRY RUN] Would move (diagnostic): $scriptName" -ForegroundColor Cyan
        }
        $stats["moved_diagnostic"]++
    } else {
        Write-Host "  ⚠️  UNCATEGORIZED: $scriptName" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "2. Processing broker scripts..." -ForegroundColor Yellow
Write-Host ""

# Process broker scripts
if (Test-Path "scripts\brokers") {
    $brokerScripts = Get-ChildItem "scripts\brokers" -File | Where-Object { 
        $_.Name -notlike "README*" -and 
        $_.Name -notlike "*.md" -and 
        $_.Name -notlike "*.txt" -and 
        $_.Name -notlike "*.html" -and
        $_.Name -ne "setup_hdfc_sky.ps1" -and
        $_.Name -ne "setup_kotak_credentials.ps1"
    }
    
    foreach ($script in $brokerScripts) {
        $scriptPath = "brokers\$($script.Name)"
        if ($brokerDevScripts -contains $scriptPath) {
            $targetPath = Join-Path $brokersDevPath $script.Name
            if (-not $DryRun) {
                Move-Item -Path $script.FullName -Destination $targetPath -Force
                Write-Host "  📦 MOVE (broker dev): brokers/$($script.Name)" -ForegroundColor Yellow
            } else {
                Write-Host "  [DRY RUN] Would move (broker dev): brokers/$($script.Name)" -ForegroundColor Cyan
            }
            $stats["moved_broker"]++
        } else {
            Write-Host "  ✅ KEEP: brokers/$($script.Name)" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "3. Processing archive folder..." -ForegroundColor Yellow
Write-Host ""

# Move archive folder
if (Test-Path "scripts\_archive") {
    $archivePath = Join-Path $devPath "_archive"
    if (-not $DryRun) {
        Move-Item -Path "scripts\_archive" -Destination $archivePath -Force
        Write-Host "  📦 Moved: _archive/" -ForegroundColor Yellow
    } else {
        Write-Host "  [DRY RUN] Would move: _archive/" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== STATISTICS ===" -ForegroundColor Cyan
Write-Host "  ✅ Kept (essential): $($stats['kept'])" -ForegroundColor Green
Write-Host "  📦 Moved (dev): $($stats['moved_dev'])" -ForegroundColor Yellow
Write-Host "  🔍 Moved (diagnostic): $($stats['moved_diagnostic'])" -ForegroundColor Magenta
Write-Host "  📦 Moved (broker dev): $($stats['moved_broker'])" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - No files moved. Run without -DryRun to organize." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Scripts folder organized!" -ForegroundColor Green
    Write-Host "   Essential scripts remain in: scripts/" -ForegroundColor Cyan
    Write-Host "   Dev scripts moved to: $devPath" -ForegroundColor Cyan
}

