# Capture Terminal Output to File
# Use this when terminal selection/copy isn't working
# Usage: .\scripts\capture_terminal_output.ps1 -Command "your-command-here"

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [string]$OutputFile = "_local\logs\terminal_output_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt",
    
    [switch]$ShowInTerminal = $true
)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$fullOutputPath = Join-Path $projectRoot $OutputFile

Write-Host "`n=== Capturing Terminal Output ===" -ForegroundColor Cyan
Write-Host "Command: $Command" -ForegroundColor Yellow
Write-Host "Output file: $fullOutputPath" -ForegroundColor Gray
Write-Host ""

# Capture output
$output = @()
$output += "=== Terminal Output Capture ==="
$output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "Command: $Command"
$output += "Working Directory: $(Get-Location)"
$output += "================================`n"

try {
    if ($ShowInTerminal) {
        # Show output in terminal AND capture to file
        Invoke-Expression $Command 2>&1 | Tee-Object -FilePath $fullOutputPath -Append
    } else {
        # Capture silently
        $result = Invoke-Expression $Command 2>&1
        $output += $result | Out-String
        $output | Out-File -FilePath $fullOutputPath -Encoding UTF8
    }
    
    Write-Host "`n✅ Output saved to: $fullOutputPath" -ForegroundColor Green
    Write-Host "   You can now share this file in chat using: @file:$OutputFile" -ForegroundColor Yellow
    
    # Also copy path to clipboard if possible
    try {
        $fullOutputPath | Set-Clipboard -ErrorAction SilentlyContinue
        Write-Host "   (Path copied to clipboard)" -ForegroundColor Gray
    } catch {
        # Clipboard might not be available, that's okay
    }
    
} catch {
    Write-Host "`n❌ Error capturing output: $_" -ForegroundColor Red
    $output += "ERROR: $_"
    $output | Out-File -FilePath $fullOutputPath -Encoding UTF8
    exit 1
}

