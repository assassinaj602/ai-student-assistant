# 🚀 Firebase Deployment Setup

This guide will help you set up automatic deployment from GitHub to Firebase Hosting.

## ✅ Current Status
- ✅ Repository created: https://github.com/assassinaj602/ai-student-assistant
- ✅ Code uploaded to GitHub
- ✅ Firebase Hosting configured
- ✅ Manual deployment successful: https://ai-student-assistant-76e9e.web.app
- ⏳ **Next:** Set up automatic deployment via GitHub Actions

## 🔑 Setup Automatic Deployment

### Step 1: Create Firebase Service Account

1. **Go to Google Cloud Console:**
   ```
   https://console.cloud.google.com/iam-admin/serviceaccounts?project=ai-student-assistant-76e9e
   ```

2. **Click "CREATE SERVICE ACCOUNT"**

3. **Fill in Service Account Details:**
   - **Name:** `github-actions-firebase`
   - **Description:** `Service account for GitHub Actions Firebase deployment`
   - Click **"CREATE AND CONTINUE"**

4. **Grant Required Roles:**
   - **Firebase Hosting Admin** 
   - **Cloud Build Service Account**
   - Click **"CONTINUE"** then **"DONE"**

5. **Create JSON Key:**
   - Click on the newly created service account
   - Go to **"KEYS"** tab
   - Click **"ADD KEY"** → **"Create new key"**
   - Select **JSON** format
   - Click **"CREATE"** (file will download)

### Step 2: Add Secret to GitHub Repository

1. **Open the downloaded JSON file** and copy ALL the content

2. **Go to your GitHub repository secrets:**
   ```
   https://github.com/assassinaj602/ai-student-assistant/settings/secrets/actions
   ```

3. **Click "New repository secret"**

4. **Create the Firebase secret:**
   - **Name:** `FIREBASE_SERVICE_ACCOUNT_AI_STUDENT_ASSISTANT_76E9E`
   - **Value:** Paste the entire JSON content from the downloaded file
   - Click **"Add secret"**

5. **Create the Gemini API Key secret:**
   - Click **"New repository secret"** again
   - **Name:** `GEMINI_API_KEY`
   - **Value:** `AIzaSyA6rafof_TPICMliKFzl9aSf9Mv32g2Ff4`
   - Click **"Add secret"**

### Step 3: Test Automatic Deployment

1. **Make a small change to your code** (e.g., update README.md)

2. **Commit and push:**
   ```bash
   git add .
   git commit -m "Test automatic deployment"
   git push
   ```

3. **Check deployment progress:**
   - Go to: https://github.com/assassinaj602/ai-student-assistant/actions
   - You should see a workflow running
   - When complete, changes will be live at: https://ai-student-assistant-76e9e.web.app

## 🔄 How It Works

The GitHub Actions workflow (`.github/workflows/firebase-hosting-merge.yml`) will:

1. **Trigger** on every push to `main` branch
2. **Setup** Flutter environment
3. **Install** dependencies with `flutter pub get`
4. **Build** the web app with `flutter build web --release`
5. **Deploy** to Firebase Hosting using the service account

## 🌐 Your Live URLs

- **Production:** https://ai-student-assistant-76e9e.web.app
- **Firebase Console:** https://console.firebase.google.com/project/ai-student-assistant-76e9e
- **GitHub Repository:** https://github.com/assassinaj602/ai-student-assistant

## 🎯 Features

Your deployed app includes:
- 🔐 Firebase Authentication (Email/Password + Google Sign-in)
- 📚 Course and Timetable Management
- 📝 Note-taking with AI Summarization
- 🤖 AI Chat Assistant
- 🎯 AI-generated Flashcards
- 📱 Responsive web design
- 🔄 Offline-first with auto-sync

## 🔧 Local Development

To run locally:
```bash
flutter pub get
flutter run -d web-server --web-port 8080
```

To build for production:
```bash
flutter build web --release
```

To deploy manually:
```bash
firebase deploy --only hosting
```

---

**Need help?** Check the GitHub Actions logs or Firebase Console for debugging information.