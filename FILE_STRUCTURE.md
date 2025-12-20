# AurumHarmony File Structure

This document describes the organized file structure of the AurumHarmony project.

## Root Directory

```
AurumHarmonyTest/
├── api/                    # Broker API client modules
│   ├── hdfc_sky.py
│   ├── kotak_neo.py
│   └── mangal_keshav.py
│
├── aurum_harmony/          # Main application package
│   ├── APIs_and_Integrations/
│   ├── app/
│   ├── blockchain/
│   ├── docs/
│   ├── engines/
│   ├── frontend/
│   ├── master_codebase/
│   └── trade_history/
│
├── config/                 # Configuration scripts
│   ├── app.py
│   ├── get_token.py
│   └── get_kotak_token.py
│
├── Code_Files/            # Legacy code files (dated versions)
│
├── docs/                   # Flutter web build output (deployed to Cloudflare)
│   └── (build artifacts)
│
├── documentation/          # Project documentation
│   ├── setup/             # Setup and installation guides
│   │   ├── COMPLETE_SETUP_CHECKLIST.md
│   │   ├── INSTALLATION_CHECKLIST.md
│   │   ├── SETUP_WHEN_YOU_RETURN.md
│   │   └── NGROK_SETUP_TODO.md
│   ├── deployment/        # Deployment guides
│   │   ├── CLOUDFLARE_SETUP_ACTION_PLAN.md
│   │   └── QUICK_SETUP_CLOUDFLARE.md
│   ├── reference/         # Reference documentation
│   │   ├── QUICK_REFERENCE.md
│   │   ├── DESIGN_FEATURES.md
│   │   ├── AurumHarmony_App_Design.md
│   │   └── Windows_Web_Design.md
│   ├── status/           # Project status and task tracking
│   │   ├── SETUP_STATUS.md
│   │   ├── COMPLETED_TASKS_SUMMARY.md
│   │   └── PENDING_TASKS_SUMMARY.md
│   └── README.md
│
├── .github/
│   └── workflows/        # GitHub Actions workflows
│       ├── deploy.yml                    # Cloudflare webhook deployment
│       ├── cloudflare-deploy.yml        # Full Cloudflare deployment
│       └── cloudflare-deploy-simple.yml # Simple Cloudflare deployment
│
├── engines/               # Engine modules (legacy location)
│
├── scripts/               # Utility scripts
│   ├── brokers/          # Broker management scripts
│   │   ├── get_hdfc_request_token.ps1
│   │   ├── add_kotak_token*.ps1
│   │   └── setup_hdfc_sky.ps1
│   ├── tests/            # Test scripts
│   │   ├── test_hdfc_*.py
│   │   └── test_hdfc_*.ps1
│   ├── setup/            # Setup scripts
│   │   └── setup_ngrok_authtoken.ps1
│   ├── start_backend.ps1
│   ├── start_ngrok.ps1
│   ├── start_flutter.ps1
│   └── deploy_cloudflare.ps1
│
├── templates/            # HTML templates
│
├── Old_Files/           # Archived old files
│
└── Other_Files/         # Miscellaneous files
```

## Key Directories

### `/api`
Broker API client modules for HDFC Sky, Kotak Neo, and Mangal Keshav.

### `/aurum_harmony`
Main application package containing:
- **engines/**: Trading engines (AI, risk management, compliance, etc.)
- **frontend/**: Flutter web application
- **master_codebase/**: Main Flask application
- **blockchain/**: Hyperledger Fabric integration

### `/docs`
Flutter web build output directory. This is where the built Flutter web app is placed for Cloudflare Pages deployment.

### `/documentation`
All project documentation organized by category:
- **setup/**: Setup guides, installation checklists, and configuration instructions
- **deployment/**: Deployment guides for Cloudflare, Kubernetes, and other platforms
- **reference/**: Quick references, design documents, and feature documentation
- **status/**: Project status summaries and task tracking

### `/.github/workflows`
GitHub Actions CI/CD workflows:
- **deploy.yml**: Cloudflare Pages webhook trigger (simple deployment)
- **cloudflare-deploy.yml**: Full Cloudflare deployment with build
- **cloudflare-deploy-simple.yml**: Simplified Cloudflare deployment

### `/scripts`
All utility scripts organized by purpose:
- **brokers/**: Scripts for managing broker integrations
- **tests/**: Test scripts for validation
- **setup/**: Initial setup scripts

## Quick Reference

### Running Scripts
```powershell
# Start backend
.\scripts\start_backend.ps1

# Start ngrok
.\scripts\start_ngrok.ps1

# Add Kotak token
.\scripts\brokers\add_kotak_token.ps1

# Test HDFC credentials
python .\scripts\tests\test_hdfc_credentials.py
```

### Documentation
- Quick Start: `QUICK_START.md` (root)
- Setup Guides: `documentation/setup/`
- Deployment Guides: `documentation/deployment/`
- Reference Docs: `documentation/reference/`
- Project Status: `documentation/status/`

## Notes

- All broker-related files are now in `docs/brokers/` and `scripts/brokers/`
- Test files are organized in `scripts/tests/`
- Setup guides are in `docs/setup/`
- Main application code remains in `aurum_harmony/`
