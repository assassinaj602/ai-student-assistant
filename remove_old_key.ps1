# WARNING: This rewrites Git history to remove the exposed API key
# Make sure you have a backup before running!

Write-Host "🔒 Removing exposed API key from Git history..." -ForegroundColor Yellow
Write-Host ""

# The old exposed key that needs to be removed
$oldKey = "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"
$placeholder = "REMOVED_EXPOSED_KEY"

Write-Host "Step 1: Using git filter-repo to rewrite history..." -ForegroundColor Cyan

# Check if git-filter-repo is installed
if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Write-Host "❌ git-filter-repo is not installed!" -ForegroundColor Red
    Write-Host "Install it with: pip install git-filter-repo" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use BFG Repo-Cleaner" -ForegroundColor Yellow
    Write-Host "Download from: https://rtyley.github.io/bfg-repo-cleaner/" -ForegroundColor Yellow
    exit 1
}

# Rewrite history to replace the key
git filter-repo --replace-text <(echo "$oldKey==>$placeholder") --force

Write-Host ""
Write-Host "✅ Step 1 complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Step 2: Force push to GitHub..." -ForegroundColor Cyan
Write-Host "⚠️  WARNING: This will rewrite remote history!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Type 'YES' to force push"

if ($confirm -eq "YES") {
    git push origin --force --all
    git push origin --force --tags
    Write-Host ""
    Write-Host "✅ Done! Old key removed from GitHub history!" -ForegroundColor Green
} else {
    Write-Host "❌ Cancelled. Push manually with: git push origin --force --all" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔐 IMPORTANT: Update GitHub Secret with new key:" -ForegroundColor Cyan
Write-Host "1. Go to: https://github.com/assassinaj602/ai-student-assistant/settings/secrets/actions" -ForegroundColor White
Write-Host "2. Edit OPENROUTER_API_KEY secret" -ForegroundColor White
Write-Host "3. Set new value: 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" -ForegroundColor White
