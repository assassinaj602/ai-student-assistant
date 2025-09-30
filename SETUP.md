# 🚀 AI Student Assistant Setup Guide

This guide will help you set up and run the complete AI Student Assistant application, including both the Flutter frontend and Node.js backend.

## 📋 Prerequisites

### Required Software
- **Flutter SDK** 3.7.2 or higher
- **Dart SDK** (included with Flutter)
- **Node.js** 18.0.0 or higher
- **npm** 9.0.0 or higher
- **Git** for version control

### Required Accounts
- **Firebase** account (free tier available)
- **Hugging Face** account with API access (free tier available)

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `ai-student-assistant`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Firestore Database

1. In Firebase Console, click "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (you can secure it later)
4. Select a location close to your users
5. Click "Done"

### 3. Enable Authentication

1. In Firebase Console, click "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password"
5. Enable "Google" (optional)

### 4. Get Firebase Configuration

#### For Flutter App:
1. Click "Project settings" (gear icon)
2. Scroll down to "Your apps"
3. Click Android icon to add Android app
4. Enter package name: `com.example.ai_student_assistant`
5. Download `google-services.json`
6. Place it in `android/app/` directory

#### For iOS (if needed):
1. Click iOS icon to add iOS app
2. Enter bundle ID: `com.example.aiStudentAssistant`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

#### For Backend:
1. Go to "Project settings" > "Service accounts"
2. Click "Generate new private key"
3. Save the JSON file as `firebase-service-account-key.json`
4. Place it in `backend/config/` directory
5. Note your Project ID from the settings page

## 🤖 Hugging Face Setup

### 1. Create Account
1. Go to [Hugging Face](https://huggingface.co/)
2. Sign up for a free account

### 2. Get API Token
1. Go to [Settings > Access Tokens](https://huggingface.co/settings/tokens)
2. Click "New token"
3. Enter name: "ai-student-assistant"
4. Select "Read" permission
5. Click "Generate"
6. Copy the token (you'll need it for backend configuration)

## 🛠️ Backend Setup

### 1. Navigate to Backend Directory
```bash
cd ai_student_assistant/backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit with your actual values
# Windows:
notepad .env
# Mac/Linux:
nano .env
```

### 4. Update Environment Variables
```bash
# Required - Get from Firebase project settings
FIREBASE_PROJECT_ID=your-firebase-project-id

# Required - Path to your Firebase service account key
FIREBASE_SERVICE_ACCOUNT_KEY=./config/firebase-service-account-key.json

# Required - Get from Hugging Face settings
HUGGING_FACE_API_KEY=your-hugging-face-api-key

# Optional - Adjust as needed
PORT=3000
NODE_ENV=development
DAILY_CHAT_LIMIT=50
DAILY_SUMMARIZE_LIMIT=20
DAILY_EMBEDDINGS_LIMIT=30
DAILY_FLASHCARDS_LIMIT=15
```

### 5. Create Config Directory
```bash
mkdir -p config
# Place your firebase-service-account-key.json in this directory
```

### 6. Start Backend Server
```bash
# Development mode (with auto-restart)
npm run dev

# Or production mode
npm start
```

### 7. Verify Backend is Running
Open browser to `http://localhost:3000/health` - you should see:
```json
{
  "status": "ok",
  "checks": {
    "server": "ok",
    "firebase": "ok",
    ...
  }
}
```

## 📱 Flutter App Setup

### 1. Navigate to App Directory
```bash
cd ai_student_assistant
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase for Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (follow prompts)
flutterfire configure --project=your-firebase-project-id
```

### 4. Create Environment Configuration
Create `lib/.env` file:
```bash
# API Configuration
API_BASE_URL=http://localhost:3000
DEBUG=true
```

### 5. Run the App
```bash
# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Or run in debug mode
flutter run --debug
```

## 🧪 Testing the Complete System

### 1. Test Backend APIs

#### Health Check:
```bash
curl http://localhost:3000/health
```

#### Test Authentication (replace with actual Firebase token):
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer <firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, AI!"}'
```

### 2. Test Flutter App

1. **Login**: Create account or login with email/password
2. **Timetable**: Add a test course
3. **Notes**: Create a note and try AI summary
4. **Chat**: Send a message to AI
5. **Flashcards**: Generate flashcards from text

## 🐛 Troubleshooting

### Common Backend Issues

#### 1. Firebase Connection Error
```bash
Error: Firebase Admin SDK not initialized
```
**Solution**: Check `FIREBASE_PROJECT_ID` and service account key file path

#### 2. Hugging Face API Error
```bash
Error: Hugging Face API not configured
```
**Solution**: Verify `HUGGING_FACE_API_KEY` is correct and has permissions

#### 3. CORS Error
```bash
Access to fetch has been blocked by CORS policy
```
**Solution**: Update `CORS_ORIGINS` in `.env` to include your Flutter app URL

### Common Flutter Issues

#### 1. Firebase Not Configured
```bash
Error: No Firebase App '[DEFAULT]' has been created
```
**Solution**: Run `flutterfire configure` and ensure `google-services.json` is in correct location

#### 2. API Connection Error
```bash
Error: Failed to connect to backend
```
**Solution**: Ensure backend is running on `http://localhost:3000` and update `API_BASE_URL`

#### 3. Package Dependencies Error
```bash
Error: Package dependencies not met
```
**Solution**: Run `flutter clean` then `flutter pub get`

## 🚀 Production Deployment

### Backend Deployment Options

#### 1. Using Docker
```bash
cd backend
docker build -t ai-student-assistant-backend .
docker run -p 3000:3000 ai-student-assistant-backend
```

#### 2. Using Cloud Services
- **Google Cloud Run**: Automatic scaling, pay-per-use
- **AWS App Runner**: Easy container deployment
- **Heroku**: Simple git-based deployment
- **Railway**: Modern cloud platform

### Flutter App Deployment

#### Android:
```bash
flutter build apk --release
# APK will be in build/app/outputs/flutter-apk/
```

#### iOS:
```bash
flutter build ios --release
# Then use Xcode to upload to App Store
```

## 📊 Monitoring and Maintenance

### 1. Monitor Backend Health
- Set up uptime monitoring for `/health` endpoint
- Monitor logs in `backend/logs/` directory
- Track API quota usage via `/api/quota` endpoint

### 2. Monitor App Performance
- Use Firebase Crashlytics for crash reporting
- Monitor user engagement with Firebase Analytics
- Track API usage patterns

### 3. Update Dependencies
```bash
# Backend
cd backend
npm audit fix
npm update

# Flutter
cd ai_student_assistant
flutter pub upgrade
```

## 🔒 Security Considerations

### Production Checklist
- [ ] Change Firebase Firestore rules to production mode
- [ ] Use environment-specific Firebase projects
- [ ] Secure API keys and service account files
- [ ] Enable HTTPS for backend deployment
- [ ] Set up proper CORS origins for production
- [ ] Configure rate limiting for production load
- [ ] Set up monitoring and alerting
- [ ] Regular security updates for dependencies

## 🆘 Getting Help

If you encounter issues:

1. **Check Logs**: Look in `backend/logs/` for error details
2. **Verify Configuration**: Double-check all environment variables
3. **Test Connections**: Use curl to test backend endpoints
4. **Firebase Console**: Check for errors in Firebase console
5. **GitHub Issues**: Create an issue if you find a bug

## 🎉 Success!

If everything is working correctly, you should now have:

- ✅ Backend server running on `http://localhost:3000`
- ✅ Flutter app connected to backend
- ✅ Firebase authentication working
- ✅ AI features responding (chat, summary, flashcards)
- ✅ Offline functionality in the app
- ✅ Real-time sync between devices

Congratulations! Your AI Student Assistant is now ready to help with studying! 🎓