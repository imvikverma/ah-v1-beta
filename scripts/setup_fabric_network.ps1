# Quick launcher for Fabric network setup
# Runs the setup script from fabric directory

Set-Location $PSScriptRoot\..\fabric
& ".\setup_fabric.ps1" -StartNetwork

