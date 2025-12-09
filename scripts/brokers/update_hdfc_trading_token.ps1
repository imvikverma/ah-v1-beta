# Update HDFC Sky Trading Account Token
# This updates the .env file with the trading account access token and device ID

$envFile = Join-Path $PSScriptRoot "..\..\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env file not found at: $envFile" -ForegroundColor Red
    exit 1
}

Write-Host "`n📝 Updating HDFC Sky Trading Account Token in .env`n" -ForegroundColor Cyan

# Read current .env
$envContent = Get-Content $envFile -Raw

# Update or add HDFC_SKY_ACCESS_TOKEN
$newToken = "eyJhbGciOiJIUzI1NiJ9.eyJkZXZpY2UiOiJ3ZWIiLCJjbGllbnRfaWQiOiJTMjIzOTMzMiIsImNsaWVudF90b2tlbiI6InQ4RTJPeitrKzJnQ3NXbnN3cWNKT21tM0dOVE5mWmtCcVdOdm5iT05hSXpsMlZVYWtqditwZWZFUmR0Q3JPcTdYVFN6bVZJRzk0dWNPcTRXQ2ZGSStJa0JBeVk5RWpVcmJKSVpyM1UyNi9jZktOenRkQVFGV00yQm0wRURxRDM3M2VMTUg5ajNiTitKcE5RYVRoeGRLOEg3emNHN0tuZEp0QUlwVHViMUNuTXBxZUQyY0NlNE5zWmQyMWxGN2ovVFZOYTVzVWt3L2lGTTJnbkt2ZHFQajZLN0R1NFZmMUZCVmJBbUE5ZkxXczg9IiwiZGV2aWNlX2lkIjoiODhjMWFlYzM5ZDQ1NGQ3Y2E3NDAxNjBmNDYxZTQyODUiLCJibGFja2xpc3Rfa2V5IjoiUzIyMzkzMzI6ZjZiZjA3ZjBjOTNhNDk5MzliOTVhOTBhMjc4OTllYzEiLCJleHAiOjE3NjUyOTc2MzgyMjMsImlhdCI6MTc2NTIxMTIzOH0.nKPUdhUupqDHoiFiIe9UagNE1DSyEvetsDjZakXfDY8"

if ($envContent -match "HDFC_SKY_ACCESS_TOKEN=") {
    $envContent = $envContent -replace "HDFC_SKY_ACCESS_TOKEN=.*", "HDFC_SKY_ACCESS_TOKEN=$newToken"
    Write-Host "✅ Updated HDFC_SKY_ACCESS_TOKEN" -ForegroundColor Green
} else {
    $envContent += "`nHDFC_SKY_ACCESS_TOKEN=$newToken"
    Write-Host "✅ Added HDFC_SKY_ACCESS_TOKEN" -ForegroundColor Green
}

# Update or add HDFC_SKY_DEVICE_ID
$deviceId = "88c1aec39d454d7ca740160f461e4285"

if ($envContent -match "HDFC_SKY_DEVICE_ID=") {
    $envContent = $envContent -replace "HDFC_SKY_DEVICE_ID=.*", "HDFC_SKY_DEVICE_ID=$deviceId"
    Write-Host "✅ Updated HDFC_SKY_DEVICE_ID" -ForegroundColor Green
} else {
    $envContent += "`nHDFC_SKY_DEVICE_ID=$deviceId"
    Write-Host "✅ Added HDFC_SKY_DEVICE_ID" -ForegroundColor Green
}

# Write back to .env
$envContent | Set-Content $envFile -NoNewline

Write-Host "`n✅ .env file updated successfully!`n" -ForegroundColor Green
Write-Host "Now using:" -ForegroundColor Cyan
Write-Host "  • Trading API: api.hdfcsky.com" -ForegroundColor White
Write-Host "  • Header: x-authorization-token" -ForegroundColor White
Write-Host "  • Device ID: $deviceId`n" -ForegroundColor White

