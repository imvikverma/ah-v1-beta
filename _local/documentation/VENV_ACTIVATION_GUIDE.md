# How to Activate Venv in New Terminal

## Quick Method:
Run this in your terminal:
    .\activate_venv.ps1

## Manual Method:
    . .venv\Scripts\Activate.ps1

## If You Get Execution Policy Error:
Run as Administrator:
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

## Verify Activation:
    python --version
    echo $env:VIRTUAL_ENV

## Deactivate:
    deactivate
