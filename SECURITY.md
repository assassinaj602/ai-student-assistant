# 🔐 SECURITY GUIDE - NEVER EXPOSE YOUR API KEY!

## ⚠️ CRITICAL: How API Keys Work in This Project

### ✅ SAFE Setup (Current):
- **Source Code**: NO hardcoded keys (safe to push to GitHub)
- **Local Dev**: Uses `.env` file (gitignored, never pushed)
- **GitHub CI**: Uses GitHub Secrets (encrypted, never exposed)
- **Deployed Site**: Built with secrets, no key in code

---

## 📋 Setup Instructions

### 1️⃣ Local Development (Native: Android/iOS/Desktop)

Your `.env` file is already configured:
```bash
# .env (already in .gitignore - NEVER commit this file!)
OPENROUTER_API_KEY=your_actual_key_here
```

**Run normally:**
```bash
flutter run
```

The app automatically loads `.env` on native platforms.

---

### 2️⃣ Web Development (Local Testing)

Web builds DON'T read `.env`. Use `--dart-define`:

```bash
flutter run -d chrome --dart-define=OPENROUTER_API_KEY=your_actual_key_here
```

**Or create a VS Code launch configuration** (already done in `.vscode/launch.json`)

---

### 3️⃣ GitHub Repository Setup

**BEFORE pushing to GitHub, set this secret (ONE TIME ONLY):**

1. Go to: https://github.com/assassinaj602/ai-student-assistant/settings/secrets/actions

2. Click **"New repository secret"**

3. Add:
   - **Name**: `OPENROUTER_API_KEY`
   - **Value**: `your_actual_openrouter_api_key`

4. Click **"Add secret"**

**That's it!** Your GitHub Actions workflow will automatically inject this during builds.

---

## 🚫 What NOT To Do

### ❌ NEVER do this:

```dart
// ❌ BAD - Hardcoded in source code
static const String apiKey = 'sk-or-v1-...';

// ❌ BAD - Committed to git
const String API_KEY = 'sk-or-v1-...';

// ❌ BAD - In any tracked file
final key = 'sk-or-v1-...';
```

### ✅ ALWAYS do this:

```dart
// ✅ GOOD - From environment
const key = String.fromEnvironment('OPENROUTER_API_KEY');

// ✅ GOOD - From .env file
final key = dotenv.get('OPENROUTER_API_KEY');

// ✅ GOOD - From GitHub Secrets via --dart-define
# GitHub Actions automatically injects via workflow
```

---

## 📝 Safe Workflow

### Local Development:
```bash
# 1. Edit code
# 2. Test locally (native)
flutter run

# 3. Test web
flutter run -d chrome --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
```

### GitHub Push (Automated Deploy):
```bash
# 1. Make sure GitHub Secret is set (one-time)
# 2. Commit your changes
git add .
git commit -m "Your changes"

# 3. Push to GitHub
git push origin main

# 4. GitHub Actions automatically:
#    - Builds with your secret
#    - Deploys to Firebase Hosting
#    - Your API key stays safe!
```

---

## 🔍 How to Check if You're Safe

### Before committing:

```bash
# Check what you're about to commit
git diff

# Search for any API keys in tracked files (should return nothing!)
git grep "sk-or-v1-"
```

**If the second command returns ANY actual keys** (not just docs/comments), **DO NOT COMMIT!**

---

## 🆘 If Your Key Gets Exposed

1. **Immediately**: Go to https://openrouter.ai/keys
2. **Delete** the exposed key
3. **Generate** a new key
4. **Update** your `.env` file with the new key
5. **Update** GitHub Secret with the new key
6. **Never** hardcode keys in source files again!

---

## ✅ Security Checklist

Before pushing to GitHub:

- [ ] `.env` file is in `.gitignore` ✅ (already done)
- [ ] No hardcoded keys in any `.dart` files ✅ (already done)
- [ ] GitHub Secret `OPENROUTER_API_KEY` is set ⚠️ (you need to do this)
- [ ] Test: `git grep "sk-or-v1-"` returns nothing ✅
- [ ] Workflow file uses `${{ secrets.OPENROUTER_API_KEY }}` ✅ (already done)

---

## 📚 Files That Are Safe

✅ These files are gitignored (NEVER pushed):
- `.env`
- `.env.local`
- `.env.*.local`
- `build/`

✅ These files reference secrets safely:
- `.github/workflows/*.yml` - Uses `${{ secrets.OPENROUTER_API_KEY }}`
- `lib/src/services/openrouter_ai_service.dart` - Uses `String.fromEnvironment()` and `dotenv.get()`
- `lib/main.dart` - Loads `.env` for native, skips for web

---

## 🎯 Summary

**Your API key is NOW safe because:**
1. ✅ NOT hardcoded in source code
2. ✅ Stored in `.env` (gitignored)
3. ✅ GitHub uses encrypted secrets
4. ✅ Deployed site built with secrets, not exposed

**You can safely push to GitHub now!** 🎉
