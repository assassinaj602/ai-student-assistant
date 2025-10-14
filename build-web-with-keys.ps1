# Load API keys from .env file and build Flutter web with them
Write-Host "Loading API keys from .env file..." -ForegroundColor Cyan

# Read .env file and set environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^OPENROUTER_API_KEY') {
        $parts = $_.Split('=', 2)
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        Set-Item -Path "env:$key" -Value $value
        Write-Host "  Loaded $key" -ForegroundColor Green
    }
}

# Verify keys are loaded
$key1 = $env:OPENROUTER_API_KEY_1
$key2 = $env:OPENROUTER_API_KEY_2
$key3 = $env:OPENROUTER_API_KEY_3
$key4 = $env:OPENROUTER_API_KEY_4

if (-not $key1) {
    Write-Host "Error: API keys not found in .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuilding Flutter web with API keys..." -ForegroundColor Cyan

# Build with dart-define for each key
flutter build web `
    --dart-define=OPENROUTER_API_KEY_1=$key1 `
    --dart-define=OPENROUTER_API_KEY_2=$key2 `
    --dart-define=OPENROUTER_API_KEY_3=$key3 `
    --dart-define=OPENROUTER_API_KEY_4=$key4

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild complete! Keys are now embedded in the web build." -ForegroundColor Green
    Write-Host "`nYou can now deploy with: firebase deploy --only hosting" -ForegroundColor Yellow
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
