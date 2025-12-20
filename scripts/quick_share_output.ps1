# Quick Share Terminal Output
# Automatically captures command output and prepares it for sharing
# Usage: .\scripts\quick_share_output.ps1 "git status"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Command
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputFile = "_local\logs\share_$timestamp.txt"

Write-Host "`n📋 Capturing output for sharing..." -ForegroundColor Cyan
Write-Host "   Command: $Command" -ForegroundColor Gray
Write-Host ""

# Capture command output
try {
    $output = Invoke-Expression $Command 2>&1
    $fullOutput = @"
=== Command Output ===
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Command: $Command
Working Directory: $(Get-Location)
================================

$($output | Out-String)
"@
    
    # Save to file
    $fullPath = Join-Path $projectRoot $outputFile
    $fullOutput | Out-File -FilePath $fullPath -Encoding UTF8
    
    Write-Host "✅ Output saved!" -ForegroundColor Green
    Write-Host "`n📄 File: $outputFile" -ForegroundColor Yellow
    Write-Host "`n💡 To share in chat, use:" -ForegroundColor Cyan
    Write-Host "   @file:$outputFile" -ForegroundColor White
    Write-Host "`nOr copy the file path above and paste it in chat." -ForegroundColor Gray
    
    # Try to open the file location
    try {
        $fileDir = Split-Path -Parent $fullPath
        explorer.exe $fileDir
    } catch {
        # Ignore if explorer fails
    }
    
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
    exit 1
}

