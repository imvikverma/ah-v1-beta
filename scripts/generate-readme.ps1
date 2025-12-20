# Dynamic README Generator
# Generates README.md from various project sources

# Get project root (script is in scripts/, so go up one level)
$scriptPath = $MyInvocation.MyCommand.Path
$scriptsDir = Split-Path -Parent $scriptPath
$root = Split-Path -Parent $scriptsDir
$readmePath = Join-Path $root "README.md"
$changelogPath = Join-Path $root "CHANGELOG.md"
$fileStructurePath = Join-Path $root "FILE_STRUCTURE.md"

Write-Host "`n=== Generating Dynamic README ===" -ForegroundColor Cyan

# Get latest version - auto-increment patch version on each EOD
$versionFile = Join-Path $root ".version"
$latestVersion = "1.0.0"
$latestDate = Get-Date -Format "yyyy-MM-dd"

# Try to read from .version file first
if (Test-Path $versionFile) {
    $versionContent = Get-Content $versionFile -Raw | ForEach-Object { $_.Trim() }
    if ($versionContent -match '^(\d+)\.(\d+)\.(\d+)$') {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        # Auto-increment patch version
        $patch++
        $latestVersion = "$major.$minor.$patch"
        # Write updated version back to file
        Set-Content -Path $versionFile -Value $latestVersion -NoNewline
    }
} else {
    # Create .version file if it doesn't exist
    Set-Content -Path $versionFile -Value "1.0.0" -NoNewline
}

# Also check changelog for date
if (Test-Path $changelogPath) {
    $changelog = Get-Content $changelogPath -Raw
    $dateMatch = [regex]::Match($changelog, '### Added - (\d{4}-\d{2}-\d{2})')
    if ($dateMatch.Success) {
        $latestDate = $dateMatch.Groups[1].Value
    }
}

# Get project stats
$flutterFiles = (Get-ChildItem -Path "$root\aurum_harmony\frontend\flutter_app" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$pythonFiles = (Get-ChildItem -Path $root -Recurse -Include *.py -ErrorAction SilentlyContinue | Measure-Object).Count
$scriptFiles = (Get-ChildItem -Path "$root\scripts" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue | Measure-Object).Count

# Generate README content
$readmeContent = @"
# AurumHarmony Trading System

> **Version**: $latestVersion | **Last Updated**: $latestDate  
> An AI-powered algorithmic trading platform with broker integrations, risk management, and blockchain settlement.

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Flutter SDK
- Git (for deployment)
- Broker API credentials (HDFC Sky, Kotak Neo)

### Quick Launch
\`\`\`powershell
# Use the master launcher (recommended)
.\start-all.ps1

# Or start services individually:
.\scripts\start_backend_silent.ps1   # Flask backend (port 5000)
.\scripts\start_flutter_silent.ps1   # Flutter web app (port 58643)
\`\`\`

### First Time Setup
1. **Environment Variables**: Create \`.env\` file with broker credentials
   - See \`docs/setup/\` for detailed guides
2. **Broker Integration**: 
   - HDFC Sky: \`.\scripts\brokers\setup_hdfc_sky.ps1\`
   - Kotak Neo: \`.\scripts\brokers\setup_kotak_credentials.ps1\`
3. **Git Configuration**: Ensure Git is configured for auto-deploy

## 📁 Project Structure

\`\`\`
AurumHarmonyTest/
├── api/                    # Broker API clients (HDFC Sky, Kotak Neo, Mangal Keshav)
├── aurum_harmony/          # Main application
│   ├── frontend/          # Flutter web application
│   ├── master_codebase/   # Flask backend API
│   ├── engines/           # Trading engines (AI, risk, compliance)
│   ├── blockchain/        # Hyperledger Fabric integration
│   └── app/               # Core application logic
├── config/                # Configuration scripts
├── scripts/               # Utility scripts
│   ├── brokers/          # Broker management
│   ├── tests/            # Test scripts
│   └── setup/            # Setup scripts
├── docs/                  # Documentation
└── zzz-quick-access/      # Quick launcher scripts
\`\`\`

**Full structure**: See [FILE_STRUCTURE.md](FILE_STRUCTURE.md)

## 🎯 Features

### Core Trading
- **AI-Powered Predictions**: Machine learning-based trade signals
- **Multi-Broker Support**: HDFC Sky, Kotak Neo, Mangal Keshav
- **Risk Management**: Automated risk checks and position limits
- **Backtesting**: Realistic and edge case testing engines

### Platform
- **Responsive Web UI**: Flutter-based frontend (mobile, tablet, desktop)
- **RESTful API**: Flask backend with comprehensive endpoints
- **Blockchain Integration**: Hyperledger Fabric for trade settlement
- **Real-time Updates**: WebSocket support for live data

### Developer Tools
- **Quick Access Launcher**: Master script for all services (\`start-all.ps1\`)
- **Automated Deployment**: Cloudflare Pages integration with auto-deploy
- **File Watcher**: Auto-deploy on file changes (watches Flutter frontend)
- **Dynamic Documentation**: Auto-generated README and changelog
- **Comprehensive Testing**: Test scripts for all integrations
- **Firefox Auto-Refresh**: Browser tool for hard refresh during development

## 📊 Project Stats

- **Python Files**: $pythonFiles
- **Flutter Files**: $flutterFiles
- **PowerShell Scripts**: $scriptFiles
- **Broker Integrations**: 3 (HDFC Sky, Kotak Neo, Mangal Keshav)

## 🔧 Configuration

### Environment Variables
Create a \`.env\` file in the project root:

\`\`\`env
# Broker Credentials
HDFC_SKY_API_KEY=your_key
HDFC_SKY_API_SECRET=your_secret
HDFC_SKY_TOKEN_ID=your_token_id

KOTAK_NEO_API_KEY=your_key
KOTAK_NEO_API_SECRET=your_secret
KOTAK_NEO_ACCESS_TOKEN=your_token

# Trading Mode
AURUM_TRADING_MODE=PAPER  # or LIVE

# Ngrok (for webhooks)
NGROK_URL=https://your-url.ngrok-free.app
\`\`\`

See \`docs/setup/\` for detailed configuration guides.

## 📚 Documentation

- **Quick Start**: \`docs/QUICK_START.md\`
- **Broker Setup**: \`docs/brokers/BROKER_SETUP_GUIDE.md\`
- **API Endpoints**: \`docs/brokers/BROKER_API_ENDPOINTS.md\`
- **File Structure**: \`FILE_STRUCTURE.md\`
- **Changelog**: \`CHANGELOG.md\`

## 🚢 Deployment

### Auto-Deploy (Recommended)
\`\`\`powershell
# Start file watcher - auto-deploys when you save files in Cursor
.\start-all.ps1
# Select option 6: Watch & Auto-Deploy

# Or run directly:
.\scripts\watch_and_deploy.ps1
\`\`\`

The watcher will:
- Monitor Flutter frontend files for changes
- Auto-deploy when files are saved (min 2 min between deploys)
- Regenerate README and update CHANGELOG automatically

### Manual Deployment
\`\`\`powershell
# Quick deploy trigger
.\scripts\trigger_deploy.ps1

# Full deploy with menu
.\start-all.ps1
# Select option 5: Deploy to Cloudflare Pages

# Or direct script
.\scripts\deploy_cloudflare.ps1
\`\`\`

The deploy script will:
1. Build Flutter web app
2. Regenerate README.md (auto-updates stats and version)
3. Read latest changelog entry for commit message
4. Commit and push to GitHub
5. Cloudflare automatically deploys (1-3 minutes)

## 🔄 Updating Changelog

### Quick Update
\`\`\`powershell
.\scripts\update-changelog.ps1
\`\`\`

### Manual Update
Edit \`CHANGELOG.md\` directly. The deploy script will automatically use the latest \`[Unreleased]\` entry.

## 🧪 Testing

\`\`\`powershell
# Test HDFC Sky credentials
python .\scripts\tests\test_hdfc_credentials.py

# Test Kotak Neo credentials
python .\config\get_kotak_token.py

# Test broker integrations
.\scripts\brokers\test_hdfc_paper_trading.py
.\scripts\brokers\test_hdfc_integration.py
\`\`\`

## 📝 Development

### Adding Changes
1. Make your code changes in Cursor
2. (Optional) Update changelog: \`.\scripts\update-changelog.ps1\`
3. **Auto-deploy**: If watcher is running, it will deploy automatically
4. **Manual deploy**: \`.\start-all.ps1\` → Option 5, or \`.\scripts\trigger_deploy.ps1\`

### Auto-Update Features
- **README.md**: Auto-regenerated on every deploy with latest stats
- **CHANGELOG.md**: Auto-read for commit messages (add entries under \`[Unreleased]\`)
- **File Watcher**: Detects changes and triggers deployment automatically

### Code Structure
- **Backend**: \`aurum_harmony/master_codebase/Master_AurumHarmony_261125.py\`
- **Frontend**: \`aurum_harmony/frontend/flutter_app/\`
- **API Clients**: \`api/\`
- **Engines**: \`aurum_harmony/engines/\`

## 🤝 Contributing

All contributors must follow \`rules.md\` for:
- Development guidelines
- Coding standards
- Security protocols
- Compliance requirements

## 📄 License

[Add your license here]

---

**Last Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Auto-generated by**: \`scripts/generate-readme.ps1\`

For detailed changelog, see [CHANGELOG.md](CHANGELOG.md)
"@

# Write README
Set-Content -Path $readmePath -Value $readmeContent

Write-Host "✅ README.md generated successfully!" -ForegroundColor Green
Write-Host "   Location: $readmePath" -ForegroundColor Gray
Write-Host "   Version: $latestVersion" -ForegroundColor Gray
Write-Host "   Stats: $pythonFiles Python files, $flutterFiles Flutter files" -ForegroundColor Gray

