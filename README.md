# 🎓 AI Student Assistant

A comprehensive Flutter application for AI-powered student assistance including timetable management, note-taking, intelligent chat, and flashcard generation with Firebase integration.

## ✨ Features

- 🔐 **Authentication**: Firebase Email/Password + Google Sign-in
- 📚 **Course Management**: Organized timetable and course tracking  
- 📝 **Smart Notes**: AI-powered note summarization and organization
- 🤖 **AI Chat**: Intelligent assistant with multi-model support (200 requests/day)
- 🎯 **Flashcards**: AI-generated study cards from your content
- 🔍 **Semantic Search**: Find information across all your notes
- 📱 **Offline-First**: Works without internet, syncs when connected
- 🔔 **Notifications**: Smart reminders for classes and study sessions
- 💾 **Local Storage**: SQLite for reliable offline functionality
- 🌐 **Cross-Platform**: Web, Android, and iOS support

## 🚀 Tech Stack

**Frontend (Flutter 3.24+):**
- Riverpod for State Management
- Firebase Auth & Firestore
- SQLite for Offline Storage
- OpenRouter AI API Integration

**Backend (Firebase):**
- Firebase Hosting (Web App)
- Firestore Database
- Firebase Authentication
- Cloud Storage

## 📋 Prerequisites

- Flutter SDK 3.24 or higher
- Firebase CLI
- Git
- 4 Free OpenRouter API accounts (for 200 daily requests)

## 🛠️ Setup Instructions

### 1. Clone Repository
```bash
git clone https://github.com/assassinaj602/ai-student-assistant.git
cd ai-student-assistant
```

### 2. Environment Configuration
```bash
# Copy the environment template
cp .env.template .env
```

### 3. Get Your API Keys
1. Visit [OpenRouter.ai](https://openrouter.ai/)
2. Create **4 different accounts** (use different emails)
3. Get a free API key from each account (50 requests/day each)
4. Copy all 4 keys to your `.env` file:

```bash
OPENROUTER_API_KEY_1=sk-or-v1-your-first-key-here
OPENROUTER_API_KEY_2=sk-or-v1-your-second-key-here
OPENROUTER_API_KEY_3=sk-or-v1-your-third-key-here
OPENROUTER_API_KEY_4=sk-or-v1-your-fourth-key-here
```

### 4. Firebase Configuration
- `FIREBASE_SERVICE_ACCOUNT_KEY`: Path to Firebase Admin JSON (e.g., ./config/firebase-service-account-key.json)
- `HUGGING_FACE_API_KEY`: Your Hugging Face API token
- `CORS_ORIGINS`: Comma-separated origins for your Flutter web dev URL(s), e.g., `http://localhost:5000`
- Optional daily limits: `DAILY_CHAT_LIMIT`, `DAILY_SUMMARIZE_LIMIT`, `DAILY_EMBEDDINGS_LIMIT`, `DAILY_FLASHCARDS_LIMIT`

### 3. Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication (Email/Password + Google)
3. Enable Firestore Database
4. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

### 4. Install FlutterFire CLI and Configure
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. Install Dependencies

**Flutter:**
```bash
flutter pub get
```

**Backend:**
```bash
cd backend
npm install
```

### 6. Run the Application

**Start Backend Server:**
```bash
cd backend
npm run dev # or: npm start
# Server runs on http://localhost:3000
```

**Run Flutter App:**
```bash
# Web (Chrome)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Android emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical device (replace with your LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

Notes:
- If you omit `API_BASE_URL`, the app will pick a platform-aware default (web/desktop: http://localhost:3000, Android emulator: http://10.0.2.2:3000).
- For Flutter web, ensure `CORS_ORIGINS` in backend `.env` includes your dev URL (e.g., http://localhost:5000).

## Environment Configuration

### Required API Keys
- **Hugging Face API Key**: Get from https://huggingface.co/settings/tokens
- **Firebase Service Account**: Firebase Console → Project Settings → Service Accounts → Generate new private key

### Default AI Models
- Chat: `microsoft/DialoGPT-medium`
- Summarization: `facebook/bart-large-cnn`
- Embeddings: `sentence-transformers/all-MiniLM-L6-v2`

## API Usage Limits
- Free tier: 20 AI calls per user per day
- Configurable via `AI_DAILY_QUOTA` environment variable

## Project Structure
```
ai_student_assistant/
├── lib/                     # Flutter source code
│   ├── main.dart           # App entry point
│   └── src/
│       ├── app.dart        # Main app widget
│       ├── theme.dart      # App theme configuration
│       ├── screens/        # UI screens
│       ├── providers/      # Riverpod providers
│       ├── services/       # Business logic services
│       └── models/         # Data models
├── backend/                # Node.js backend
│   ├── src/server.js       # Express server
│   ├── routes/             # API routes
│   └── middleware/         # Auth middleware
├── test/                   # Flutter tests
└── .github/workflows/      # CI/CD configuration
```

## Development

### Running Tests
```bash
flutter test
flutter test test/widget_test.dart
```

### Code Analysis
```bash
flutter analyze
```

### Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Troubleshooting

1. **Firebase Configuration Issues**: Ensure `flutterfire configure` was run successfully
2. **Backend Connection**: Check that proxy server is running on the expected port and `API_BASE_URL` matches
3. **API Rate Limits**: Monitor daily quota usage in app settings
4. **Offline Sync**: Check internet connectivity and Firebase rules

5. **Web CORS**: If you see CORS errors in the browser, update `CORS_ORIGINS` in `backend/.env` to include your dev origin, e.g., `http://localhost:5000`
6. **Authorized Domains (Web Auth)**: In Firebase Console → Authentication → Settings → Authorized domains, add `localhost` and `127.0.0.1` (and custom dev ports if prompted)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## License

MIT License - see LICENSE file for details
