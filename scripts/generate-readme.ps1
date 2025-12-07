# Dynamic README Generator
# Generates README.md from various project sources

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$readmePath = Join-Path $root "README.md"
$changelogPath = Join-Path $root "CHANGELOG.md"
$fileStructurePath = Join-Path $root "FILE_STRUCTURE.md"

Write-Host "`n=== Generating Dynamic README ===" -ForegroundColor Cyan

# Get latest version from changelog
$latestVersion = "1.0.0"
$latestDate = Get-Date -Format "yyyy-MM-dd"
if (Test-Path $changelogPath) {
    $changelog = Get-Content $changelogPath -Raw
    $versionMatch = [regex]::Match($changelog, '\[(\d+\.\d+\.\d+)\]\s*-\s*(\d{4}-\d{2}-\d{2})')
    if ($versionMatch.Success) {
        $latestVersion = $versionMatch.Groups[1].Value
        $latestDate = $versionMatch.Groups[2].Value
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
- ngrok (for webhook testing)
- Broker API credentials (HDFC Sky, Kotak Neo)

### Quick Launch
\`\`\`powershell
# Use the master launcher (recommended)
.\_local\development\zzz-quick-access\start-all.ps1

# Or start services individually:
.\scripts\start_backend.ps1      # Flask backend (port 5000)
.\scripts\start_ngrok.ps1        # Ngrok tunnel
.\scripts\start_flutter.ps1       # Flutter web app
\`\`\`

### First Time Setup
1. **Environment Variables**: Create \`.env\` file with broker credentials
   - See \`docs/setup/\` for detailed guides
2. **Ngrok Setup**: Run \`.\scripts\setup\setup_ngrok_authtoken.ps1\`
3. **Broker Integration**: 
   - HDFC Sky: \`.\scripts\brokers\get_hdfc_request_token.ps1\`
   - Kotak Neo: \`.\scripts\brokers\add_kotak_token.ps1\`

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
- **Quick Access Launcher**: Master script for all services
- **Automated Deployment**: Cloudflare Pages integration
- **Dynamic Documentation**: Auto-generated README and changelog
- **Comprehensive Testing**: Test scripts for all integrations

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

### Cloudflare Pages (Automatic)
\`\`\`powershell
# Deploy with changelog-based commit message
.\_local\development\zzz-quick-access\start-all.ps1
# Select option 6: Deploy to Cloudflare Pages
\`\`\`

The deploy script will:
1. Build Flutter web app
2. Read latest changelog entry
3. Commit and push to GitHub
4. Cloudflare automatically deploys

### Manual Deployment
\`\`\`powershell
.\scripts\deploy_cloudflare.ps1
\`\`\`

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

# Run diagnostic
.\_local\development\zzz-quick-access\diagnose.ps1
\`\`\`

## 📝 Development

### Adding Changes
1. Make your code changes
2. Update changelog: \`.\scripts\update-changelog.ps1\`
3. Deploy: \`.\start-all.ps1\` → Option 6

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

