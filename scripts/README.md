# Scripts Directory

This directory contains all utility scripts for AurumHarmony.

## Structure

- **brokers/** - Broker integration scripts (HDFC Sky, Kotak Neo)
- **tests/** - Test scripts for API validation
- **setup/** - Setup and configuration scripts

## Main Scripts

- `start_backend.ps1` - Start the Flask backend server
- `start_ngrok.ps1` - Start ngrok tunnel
- `start_flutter.ps1` - Start Flutter development server
- `deploy_cloudflare.ps1` - Deploy to Cloudflare Pages

## Usage

All scripts should be run from the project root directory.

```powershell
# Start backend
.\scripts\start_backend.ps1

# Start ngrok
.\scripts\start_ngrok.ps1
```
