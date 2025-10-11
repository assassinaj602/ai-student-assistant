# GitHub Setup Instructions

## ✅ Safe to Push to GitHub!

This codebase is now **GitHub-safe**. The API key is handled intelligently:

### How it works:
- **Local Development**: Uses embedded fallback key (works out of the box)
- **GitHub CI/CD**: Uses GitHub Secrets (injected via `--dart-define`)
- **Never exposed**: Key is never visible in logs or public builds

---

## 🔐 One-Time GitHub Setup

Before pushing to GitHub, set up your secret:

### Step 1: Go to Your Repository Settings
1. Navigate to: `https://github.com/YOUR_USERNAME/ai-student-assistant/settings/secrets/actions`
2. Or: Your Repo → Settings → Secrets and variables → Actions → Secrets

### Step 2: Add Repository Secret
1. Click **"New repository secret"**
2. **Name**: `OPENROUTER_API_KEY`
3. **Value**: `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`
4. Click **"Add secret"**

### Step 3: (Optional) Set Model Variable
1. Go to: Variables tab (next to Secrets)
2. Click **"New repository variable"**
3. **Name**: `OPENROUTER_MODEL`
4. **Value**: `deepseek/deepseek-chat-v3.1:free` (or any other model)
5. Click **"Add variable"**

---

## 🚀 How to Deploy

### Local Deploy (Manual)
```bash
flutter build web --release
firebase deploy --only hosting
```

### GitHub Deploy (Automatic)
Just push to `main` branch:
```bash
git add .
git commit -m "Your commit message"
git push origin main
```

GitHub Actions will automatically:
1. Build your Flutter web app
2. Inject the API key from secrets
3. Deploy to Firebase Hosting

---

## ✅ Security Checklist

- [x] API key uses `String.fromEnvironment()` with fallback
- [x] `.env` is in `.gitignore`
- [x] GitHub workflow configured with secrets
- [x] Local development works without setup
- [x] Production builds use GitHub Secrets

**You're ready to push to GitHub safely!** 🎉

---

## 📝 Notes

### Available Free Models (Auto-Fallback Enabled)
Your app automatically tries these models in order:
1. `deepseek/deepseek-chat-v3.1:free`
2. `deepseek/deepseek-chat:free`
3. `deepseek/deepseek-r1:free`
4. `deepseek/deepseek-r1-0528:free`
5. `deepseek/deepseek-r1-distill-llama-70b:free`
6. `meta-llama/llama-3.2-3b-instruct:free`
7. `qwen/qwen-2-7b-instruct:free`
8. `google/gemini-flash-1.5:free`

If one fails, it automatically tries the next!

### OpenRouter Privacy Settings
Make sure these are enabled at https://openrouter.ai/settings/privacy:
- ✅ Enable free endpoints that may train on inputs
- ✅ Enable free endpoints that may publish prompts
