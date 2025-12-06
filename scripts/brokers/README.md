# Broker Scripts

This folder contains PowerShell scripts for managing broker integrations.

## HDFC Sky Scripts

- `get_hdfc_request_token.ps1` - Get HDFC Sky request token via OAuth
- `get_fresh_hdfc_token.ps1` - Get fresh HDFC Sky token
- `setup_hdfc_sky.ps1` - Setup HDFC Sky credentials
- `update_hdfc_credentials.ps1` - Update HDFC Sky credentials
- `test_hdfc_*.ps1` - Various HDFC Sky testing scripts

## Kotak Neo Scripts

- `add_kotak_token.ps1` - Add Kotak Neo token to .env
- `add_kotak_token_simple.ps1` - Simplified version for easy pasting
- `add_kotak_token_direct.ps1` - Add Kotak Neo access token directly

## Usage

All scripts should be run from the project root directory. They will interact with the `.env` file to manage credentials.
