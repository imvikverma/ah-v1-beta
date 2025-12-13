# Start Minikube with Alternative Directory (No Admin Required)
# This uses a directory in the project folder instead of C:\Users\Dell\.minikube

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$minikubeDir = Join-Path $projectRoot "_local\minikube"

Write-Host "=== Starting Minikube with Alternative Directory ===" -ForegroundColor Cyan
Write-Host "Minikube data will be stored in: $minikubeDir" -ForegroundColor Yellow
Write-Host ""

# Create directory if it doesn't exist
if (-not (Test-Path $minikubeDir)) {
    Write-Host "Creating minikube directory..." -ForegroundColor Yellow
    New-Item -Path $minikubeDir -ItemType Directory -Force | Out-Null
    Write-Host "[OK] Directory created" -ForegroundColor Green
}

# Set environment variable to use alternative directory
$env:MINIKUBE_HOME = $minikubeDir

Write-Host "Starting minikube..." -ForegroundColor Yellow
Write-Host "Note: This may take a few minutes on first run" -ForegroundColor Gray
Write-Host ""

# Start minikube with the alternative directory
minikube start --profile aurumharmony

Write-Host ""
Write-Host "=== Minikube Started ===" -ForegroundColor Green
Write-Host "To use this minikube instance, always specify the profile:" -ForegroundColor Cyan
Write-Host "  minikube --profile aurumharmony <command>" -ForegroundColor White
Write-Host ""
Write-Host "Or set the profile as default:" -ForegroundColor Cyan
Write-Host "  minikube profile set aurumharmony" -ForegroundColor White
Write-Host ""

