# AurumHarmony: AI-Powered Algorithmic Trading Platform

> **Version**: 1.0.0 | **Last Updated**: 2025-12-20
> Production-ready AI trading platform with Flutter frontend, Flask backend, multi-broker integration, and live deployment infrastructure.

## 🚀 Production Status: LIVE & READY

### ✅ **Current Status**
- **Deployment**: Ready for production launch
- **Platforms**: GitHub, Cloudflare Pages, Firebase Hosting, Render.com
- **Domains**: admin-v2.saffronbolt.in, aurumharmony.saffronbolt.in, api.saffronbolt.in
- **Trading**: AI-powered predictions with multi-broker support

### 🎯 **Quick Launch (Development)**
\\\powershell
# Use the master launcher (recommended)
.\start-all.ps1

# Or start services individually:
.\scripts\start_backend_silent.ps1   # Flask backend (port 5000)
.\scripts\start_flutter_silent.ps1   # Flutter web app (port 58643)
\\\

### 🏭 **Production Deployment**
Follow the complete step-by-step guide:
- **Guide**: [DEPLOYMENT_STEP_BY_STEP.md](DEPLOYMENT_STEP_BY_STEP.md)
- **Package**: `aurumharmony-minimal-deploy.zip` (42KB)
- **Platforms**: GitHub → Cloudflare → Firebase → Render

### 🛠️ **Setup Requirements**
- Python 3.8+ with Flask
- Flutter SDK for web development
- Git for version control
- Broker API credentials (HDFC Sky, Kotak Neo)
- Cloud accounts (GitHub, Cloudflare, Firebase, Render)

## 📁 Project Structure

\\\
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
\\\

**Full structure**: See [FILE_STRUCTURE.md](FILE_STRUCTURE.md)

## 🎯 Production Features

### 🤖 **AI & Trading Engine**
- **LSTM Machine Learning**: Advanced volatility prediction models
- **Multi-Broker Integration**: HDFC Sky, Kotak Neo (live trading)
- **Smart Capital Management**: ₹40K per index with automatic scaling
- **Risk-Aware Trading**: Automatic trade rejection based on volatility
- **Real-time Market Data**: Live NIFTY50, BANKNIFTY, SENSEX feeds
- **Holiday & Calendar Management**: Intelligent trading day detection

### 🖥️ **Production Platform**
- **Cross-Platform Flutter App**: Responsive web/mobile/desktop interface
- **Flask REST API**: Production-ready backend with comprehensive endpoints
- **Multi-Cloud Deployment**: GitHub + Cloudflare + Firebase + Render
- **Custom Domain Setup**: Professional saffronbolt.in domains
- **SSL Security**: Automatic HTTPS certificates on all platforms
- **Admin Dashboard**: User management and oversight panel

### 🎨 **User Experience**
- **Saffron & Gold Theme**: Cultural Indian design with animations
- **Real-time Dashboard**: Live P&L, positions, market mood indicators
- **One-Click Trading**: Run predictions with automated execution
- **Paper Trading Mode**: Risk-free strategy testing
- **Mobile-First Design**: Optimized for all devices
- **Dark/Light Modes**: Adaptive theming with saffron variants

## 📊 Production Stats

- **Version**: 1.0.0 (Production Ready)
- **Python Files**: 200+ core files
- **Flutter Files**: 150+ UI components
- **Deployment Package**: 42KB (optimized)
- **Broker Integrations**: 2 active (HDFC Sky, Kotak Neo)
- **Cloud Platforms**: 4 (GitHub, Cloudflare, Firebase, Render)
- **Custom Domains**: 3 (admin-v2, aurumharmony, api)

## 🔧 Configuration

### Environment Variables
Create a \.env\ file in the project root:

\\\nv
# Broker Credentials
HDFC_SKY_API_KEY=your_key
HDFC_SKY_API_SECRET=your_secret
HDFC_SKY_TOKEN_ID=your_token_id

KOTAK_NEO_API_KEY=your_key
KOTAK_NEO_API_SECRET=your_secret
KOTAK_NEO_ACCESS_TOKEN=your_token

# Trading Mode
AURUM_TRADING_MODE=PAPER  # or LIVE

# Ngrok (for webhooks) - Note: Initially started with ngrok but later moved to custom domain saffronbolt.in
# NGROK_URL=https://your-url.ngrok-free.app
\\\

See \docs/setup/\ for detailed configuration guides.

## 📚 Documentation

- **Quick Start**: \docs/QUICK_START.md\
- **Broker Setup**: \docs/brokers/BROKER_SETUP_GUIDE.md\
- **API Endpoints**: \docs/brokers/BROKER_API_ENDPOINTS.md\
- **File Structure**: \FILE_STRUCTURE.md\
- **Changelog**: \CHANGELOG.md\

## 🚀 Production Deployment

### **Current Status**: Ready for Launch
AurumHarmony is fully configured for production deployment across multiple cloud platforms.

### **Deployment Package**
- **File**: `aurumharmony-minimal-deploy.zip` (42KB)
- **Contents**: Essential production files only
- **Ready for**: Manual GitHub upload

### **Target Platforms**
- **GitHub**: Source code repository
- **Cloudflare Pages**: Admin panel (`admin-v2.saffronbolt.in`)
- **Firebase Hosting**: Flutter web app (`aurumharmony.saffronbolt.in`)
- **Render.com**: Flask API backend (`api.saffronbolt.in`)

### **Step-by-Step Guide**
Complete beginner-friendly deployment instructions:
- **Guide**: [DEPLOYMENT_STEP_BY_STEP.md](DEPLOYMENT_STEP_BY_STEP.md)
- **Time**: ~45 minutes total
- **Difficulty**: Beginner-friendly with screenshots

### **Quick Deploy (Development)**
\\\powershell
# For local development testing
.\start-all.ps1
# Select option 3: Quick Deploy (GitHub + Cloudflare)

# Or direct deploy:
.\scripts\deploy_cloudflare.ps1
\\\

## 🔄 Updating Changelog

### Quick Update
\\\powershell
.\scripts\update-changelog.ps1
\\\

### Manual Update
Edit \CHANGELOG.md\ directly. The deploy script will automatically use the latest \[Unreleased]\ entry.

## 🧪 Testing

\\\powershell
# Test HDFC Sky credentials
python .\scripts\tests\test_hdfc_credentials.py

# Test Kotak Neo credentials
python .\config\get_kotak_token.py

# Test broker integrations
.\scripts\brokers\test_hdfc_paper_trading.py
.\scripts\brokers\test_hdfc_integration.py
\\\

## 🧹 GitHub v1 Repo Cleanup (Local‑Only Files)

> Target: Old GitHub repo v1 that accidentally contains local‑only or machine‑specific files (e.g. `.cursorrules`, `_local/`, SQLite DBs, backup venvs).

### Recommended Cleanup Flow (run inside the v1 repo)

1. **Take a safety backup first**
   - Clone or copy the v1 repo to a backup folder so you can revert if needed.
2. **Add local‑only patterns to `.gitignore` in v1**
   - Examples (adjust as needed for v1):
     - `.cursorrules`
     - `_local/`
     - `.cursor/`
     - `terminals/` or any local terminal state folders
     - `*.db`, `*.sqlite`, `*.sqlite3`
     - `.venv-backup-*` or other backup virtualenvs
3. **Stop tracking files that should now be ignored**
   - Option A (preferred): copy `scripts/fix_gitignore_tracking.ps1` from this repo into the root of the v1 repo and run:
     
     ```powershell
     cd path\to\aurumharmony-v1
     .\scripts\fix_gitignore_tracking.ps1
     ```
     
     This will list DBs, backup venvs, generated files, and `_local/` content that Git is currently tracking, then untrack them safely (files stay on disk, just leave Git).
   - Option B (manual for specific files like `.cursorrules`):
     
     ```powershell
     cd path\to\aurumharmony-v1
     git rm --cached .cursorrules
     # Repeat for any other specific local-only files
     ```
4. **Review and commit**
   - Check what changed:
     
     ```powershell
     git status
     ```
   - Commit the cleanup:
     
     ```powershell
     git commit -m "Cleanup local-only files (.cursorrules, _local, DBs, backup venvs)"
     git push
     ```

This keeps v1 clean for collaborators and CI, while your local machine can still keep `_local/`, databases, and Cursor-specific files untracked.

## 📝 Development

### Adding Changes
1. Make your code changes in Cursor
2. (Optional) Update changelog: \.\scripts\update-changelog.ps1\
3. **Auto-deploy**: If watcher is running, it will deploy automatically
4. **Manual deploy**: \.\start-all.ps1\ → Option 5, or \.\scripts\trigger_deploy.ps1\

### Auto-Update Features
- **README.md**: Auto-regenerated on every deploy with latest stats
- **CHANGELOG.md**: Auto-read for commit messages (add entries under \[Unreleased]\)
- **File Watcher**: Detects changes and triggers deployment automatically

### Code Structure
- **Backend**: \urum_harmony/master_codebase/Master_AurumHarmony_261125.py\
- **Frontend**: \urum_harmony/frontend/flutter_app/\
- **API Clients**: \pi/\
- **Engines**: \urum_harmony/engines/\

## 🤝 Contributing

All contributors must follow \
ules.md\ for:
- Development guidelines
- Coding standards
- Security protocols
- Compliance requirements

## 📄 License

[Add your license here]

## 🌐 Production URLs (After Deployment)

- **Admin Panel**: https://admin-v2.saffronbolt.in
- **Trading App**: https://aurumharmony.saffronbolt.in
- **API Backend**: https://aurum-api.onrender.com
- **GitHub Repo**: https://github.com/imvikverma/ah-v1-beta

---

**Version**: 1.0.0 | **Status**: Production Ready
**Last Updated**: 2025-12-20 | **Platform**: Multi-Cloud Production

For deployment guide, see [DEPLOYMENT_STEP_BY_STEP.md](DEPLOYMENT_STEP_BY_STEP.md)
For detailed changelog, see [CHANGELOG.md](CHANGELOG.md)
