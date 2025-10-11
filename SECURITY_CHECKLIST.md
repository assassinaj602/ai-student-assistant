# 🔒 Security Checklist for GitHub Upload

## ✅ Before Committing to GitHub

### API Keys Protection
- [x] `.env` file is in `.gitignore` 
- [x] `.env.template` created with placeholder values
- [x] No hardcoded API keys in source code
- [ ] **VERIFY**: Check that .env is not staged for commit

### Files to Double-Check
```bash
# Run these commands to verify no secrets are being committed:

# 1. Check git status (ensure .env is NOT listed)
git status

# 2. Search for any API keys in staged files
git diff --cached | grep -i "sk-or-v1"

# 3. Check for any sensitive data
git diff --cached | grep -E "(api[_-]?key|secret|password|token)"
```

### Environment Setup for Others
- [x] `.env.template` provides clear instructions
- [x] README.md explains API key setup
- [x] Setup guide includes 4-key configuration
- [x] Documentation explains free tier limitations

### Build Configuration
When building for production, API keys are passed via `--dart-define`:
```bash
flutter build web --release \
  --dart-define=OPENROUTER_API_KEY_1=$OPENROUTER_API_KEY_1 \
  --dart-define=OPENROUTER_API_KEY_2=$OPENROUTER_API_KEY_2 \
  --dart-define=OPENROUTER_API_KEY_3=$OPENROUTER_API_KEY_3 \
  --dart-define=OPENROUTER_API_KEY_4=$OPENROUTER_API_KEY_4
```

## 🚨 NEVER COMMIT
- [ ] `.env` file with actual API keys
- [ ] `google-services.json` (if contains sensitive data)
- [ ] Build artifacts with embedded keys
- [ ] Firebase private keys or service accounts

## ✅ SAFE TO COMMIT
- [x] `.env.template` with placeholders
- [x] Source code using environment variables
- [x] Firebase config (public keys only)
- [x] Documentation and setup guides

## 🔍 Quick Security Check
Run before every commit:
```bash
# Check if .env is accidentally staged
git ls-files | grep "\.env$"
# This should return nothing (empty output)

# If it returns .env, remove it:
git rm --cached .env
```