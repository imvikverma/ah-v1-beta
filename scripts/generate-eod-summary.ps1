# Generate EOD Summary JSON
# Creates a comprehensive summary of the day's work for handoff

$ErrorActionPreference = "Continue"

# Get project root (script is in scripts/, so go up one level)
$scriptPath = $MyInvocation.MyCommand.Path
$scriptsDir = Split-Path -Parent $scriptPath
$projectRoot = Split-Path -Parent $scriptsDir
Set-Location $projectRoot

# Get current timestamp in IST
$utcNow = [DateTimeOffset]::UtcNow
$istOffset = [TimeSpan]::FromHours(5.5)
$istNow = $utcNow.ToOffset($istOffset)
$timestamp = $istNow.ToString("dd") + "/" + $istNow.ToString("MM") + "/" + $istNow.ToString("yyyy") + " " + $istNow.ToString("HH:mm:ss") + " IST"
$dateOnly = $istNow.ToString("yyyy-MM-dd")
# Create filename with date and time stamp (format: EOD_YYYY-MM-DD_HHMMSS_Charlie.json)
$timeStamp = $istNow.ToString("HHmmss")
$fileName = "EOD_$($dateOnly)_$($timeStamp)_Charlie.json"

Write-Host "`n📝 Generating EOD Summary..." -ForegroundColor Cyan

# Get version
$version = "1.0.0"
$versionFile = Join-Path $projectRoot ".version"
if (Test-Path $versionFile) {
    $version = Get-Content $versionFile -Raw | ForEach-Object { $_.Trim() }
}

# Get last commit info
$lastCommit = ""
$lastCommitDate = ""
try {
    $gitLog = git log -1 --pretty=format:"%H|%s|%ad" --date=short 2>$null
    if ($gitLog) {
        $parts = $gitLog -split '\|'
        $lastCommit = $parts[0]
        $lastCommitMessage = $parts[1]
        $lastCommitDate = $parts[2]
    }
} catch {
    # Git not available or not a repo
}

# Get README timestamps
$lastUpdate = "N/A"
$currentUpdate = $timestamp
$readmePath = Join-Path $projectRoot "README.md"
if (Test-Path $readmePath) {
    $readme = Get-Content $readmePath -Raw
    $lastUpdateMatch = [regex]::Match($readme, 'Last Update[:\*\s]+(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2} IST)')
    if ($lastUpdateMatch.Success) {
        $lastUpdate = $lastUpdateMatch.Groups[1].Value
    }
}

# Get project stats
$pythonFiles = (Get-ChildItem -Path $projectRoot -Recurse -Include *.py -ErrorAction SilentlyContinue | Measure-Object).Count
$flutterFiles = (Get-ChildItem -Path "$projectRoot\aurum_harmony\frontend\flutter_app" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$scriptFiles = (Get-ChildItem -Path "$projectRoot\scripts" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue | Measure-Object).Count

# Get recent changes (last 24 hours)
$recentFiles = @()
try {
    $changedFiles = git diff --name-only HEAD 2>$null
    if ($changedFiles) {
        $recentFiles = $changedFiles | Select-Object -First 20
    }
} catch {
    # Git not available
}

# Key files and their purposes
$keyFiles = @{
    "start-all.ps1" = "Master launcher script for all services"
    "scripts/generate-readme.ps1" = "Dynamic README generator with version control"
    "scripts/run-eod-flow.ps1" = "End of Day workflow automation"
    "scripts/update-changelog.ps1" = "Interactive changelog updater"
    "worker/src/index.ts" = "Cloudflare Worker API (v1 and v2)"
    "aurum_harmony/master_codebase/Master_AurumHarmony_261125.py" = "Flask backend API"
    "aurum_harmony/frontend/flutter_app/lib/services/auth_service.dart" = "Frontend authentication service"
    ".version" = "Version tracking file (auto-increments)"
    "wrangler.toml" = "Cloudflare Worker configuration"
    "CHANGELOG.md" = "Project changelog"
}

# Deployment status
$deploymentStatus = @{
    "v1_frontend" = "https://ah.saffronbolt.in (Cloudflare Pages)"
    "v1_api" = "https://api.ah.saffronbolt.in (Cloudflare Worker)"
    "v2_frontend" = "https://ah-v2.saffronbolt.in (Cloudflare Pages - deployed)"
    "v2_api" = "https://api-v2.saffronbolt.in (Cloudflare Worker - deployed)"
    "v2_admin" = "https://admin-v2.saffronbolt.in (pending - git repo ready, needs GitHub push)"
    "v2_repo" = "AurumHarmony-v2 (separate GitHub repo)"
    "v2_admin_repo" = "AurumHarmony-v2-admin (git initialized, ready for GitHub)"
}

# Recent work summary (from today's session)
$todayWork = @(
    "Fixed Session Expired issue (5-minute grace period after login) - v1 & v2",
    "Separated v2 frontend from v1 completely - new repo and deployment",
    "Set up v2 Worker (aurum-api-v2) - deployed to api-v2.saffronbolt.in",
    "Created v2 frontend deployment pipeline - GitHub Actions workflow",
    "Set up Cloudflare Pages for v2 frontend - aurumharmony-v2-frontend project",
    "Configured DNS for v2 - ah-v2.saffronbolt.in custom domain",
    "Fixed session expired in v2 frontend - same 5-minute grace period",
    "Created v2 admin panel - Astro + shadcn/ui, connected to v2 API",
    "Set up admin panel git repo - initialized, committed, deployment workflow",
    "Updated v2 frontend constants - points to api-v2.saffronbolt.in",
    "Created EOD flow automation script - complete workflow",
    "Updated README generator - IST timestamps, version auto-increment, DD/MM/YYYY format",
    "Created EOD summary JSON system - comprehensive handoff document",
    "Reviewed all _local documentation - caught up on pending work",
    "Created pending work summary - documented all tasks"
)

# Pending tasks
$pendingTasks = @(
    "Verify Session Expired fix works (system check tomorrow) - v1 & v2",
    "Run system integrity tests",
    "Test broker API connectivity (HDFC Sky, Kotak Neo)",
    "Run backtesting tests (realistic and edge cases)",
    "Review IMPLEMENTATION_STATUS.md and MVP_COMPLETION_ASSESSMENT.md",
    "Deploy v2 admin panel to Cloudflare Pages (git repo ready, needs GitHub push)",
    "Complete v2 admin panel deployment - create GitHub repo and push",
    "Configure DNS for admin panel - admin-v2.saffronbolt.in"
)

# Important configurations
$configurations = @{
    "date_format" = "DD/MM/YYYY"
    "timezone" = "IST (UTC+5:30)"
    "version_format" = "MAJOR.MINOR.PATCH (auto-increments patch on EOD)"
    "jwt_secret" = "Configured in Worker and local .env"
    "database" = "Cloudflare D1 (aurum-harmony-db)"
    "deployment" = "Cloudflare Pages (frontend) + Workers (API)"
}

# Create summary object
$summary = @{
    "metadata" = @{
        "generated_at" = $timestamp
        "date" = $dateOnly
        "version" = $version
        "assistant" = "Charlie"
        "user" = "Vik"
        "session_type" = "EOD Summary"
    }
    "project_status" = @{
        "version" = $version
        "last_update" = $lastUpdate
        "current_update" = $currentUpdate
        "last_commit" = @{
            "hash" = $lastCommit
            "date" = $lastCommitDate
            "message" = $lastCommitMessage
        }
    }
    "project_stats" = @{
        "python_files" = $pythonFiles
        "flutter_files" = $flutterFiles
        "powershell_scripts" = $scriptFiles
    }
    "recent_work" = $todayWork
    "pending_tasks" = $pendingTasks
    "key_files" = $keyFiles
    "deployment_status" = $deploymentStatus
    "configurations" = $configurations
    "important_paths" = @{
        "project_root" = $projectRoot
        "v1_backend" = "aurum_harmony/master_codebase/Master_AurumHarmony_261125.py"
        "v1_frontend" = "aurum_harmony/frontend/flutter_app/"
        "v1_worker" = "worker/src/index.ts"
        "v2_repo" = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmony-v2"
        "v2_worker" = "AurumHarmony-v2/worker/src/index.ts"
        "v2_frontend" = "AurumHarmony-v2/frontend/flutter_app/"
        "v2_admin" = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmony-v2-admin"
        "scripts" = "scripts/"
        "documentation" = "_local/documentation/"
        "changelog" = "CHANGELOG.md"
        "readme" = "README.md"
        "version_file" = ".version"
    }
    "eod_flow" = @{
        "script" = "scripts/run-eod-flow.ps1"
        "steps" = @(
            "Update README & CHANGELOG",
            "Clean up/Organise file structure",
            "Check ML training status",
            "Generate EOD summary (this file)"
        )
    }
    "notes" = @(
        "Session Expired fix: 5-minute grace period in auth_service.dart (both v1 and v2)",
        "v2 project completely separated from v1 - new repo, new deployments, new DNS",
        "v2 Worker (aurum-api-v2) deployed and working at api-v2.saffronbolt.in",
        "v2 Frontend deployed and working at ah-v2.saffronbolt.in",
        "v2 Admin Panel ready - git initialized, needs GitHub push and Cloudflare Pages setup",
        "Version auto-increments on each README generation (patch version)",
        "All timestamps in IST (Indian Standard Time, UTC+5:30)",
        "Date format: DD/MM/YYYY",
        "EOD flow runs automatically: README generator, changelog updater, cleanup, ML check, summary",
        "Reference files for tomorrow: COMPLETE_IMPLEMENTATION_SUMMARY.md, MVP_COMPLETION_ASSESSMENT.md, IMPLEMENTATION_STATUS.md, PENDING_WORK_SUMMARY_2025-12-16.md, TESTING_CHECKLIST.md, REDESIGN_PLAN.md"
    )
}

# Convert to JSON
$jsonOutput = $summary | ConvertTo-Json -Depth 10

# Save to file
$localDir = Join-Path $projectRoot "_local"
$summariesDir = Join-Path $localDir "Summaries"
if (-not (Test-Path $summariesDir)) {
    New-Item -ItemType Directory -Path $summariesDir -Force | Out-Null
}
$summaryPath = Join-Path $summariesDir $fileName

Set-Content -Path $summaryPath -Value $jsonOutput -Encoding UTF8

Write-Host "✅ EOD Summary generated!" -ForegroundColor Green
Write-Host "   Location: $summaryPath" -ForegroundColor Gray
Write-Host "   Version: $version" -ForegroundColor Gray
Write-Host "   Timestamp: $timestamp" -ForegroundColor Gray

# Also display a brief summary
Write-Host "`n📋 Summary Preview:" -ForegroundColor Cyan
Write-Host "   Recent Work: $($todayWork.Count) items" -ForegroundColor Gray
Write-Host "   Pending Tasks: $($pendingTasks.Count) items" -ForegroundColor Gray
Write-Host "   Key Files: $($keyFiles.Count) documented" -ForegroundColor Gray
Write-Host ""

