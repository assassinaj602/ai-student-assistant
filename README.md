# AI Student Assistant

A Flutter app with a Node.js backend proxy for AI-powered student assistance including timetable management, note-taking, chat, and flashcard generation.

## Features

- 🔐 Firebase Authentication (Email/Password + Google Sign-in)
- 📚 Course and Timetable Management
- 📝 Note-taking with AI Summarization
- 🤖 AI Chat Assistant (via Hugging Face)
- 🎯 AI-generated Flashcards
- 🔍 Semantic Search across Notes
- 📱 Offline-first with Auto-sync
- 🔔 Local Notifications for Classes
- 💾 SQLite for Local Storage

## Tech Stack

**Frontend (Flutter):**
- Riverpod for State Management
- Firebase Auth & Firestore
- SQLite for Offline Storage
- Dio for HTTP Requests

**Backend (Node.js):**
- Express.js Proxy Server
- Firebase Admin SDK
- Hugging Face Inference API
- Rate Limiting & Quota Management

## Setup Instructions

### 1. Clone Repository
```bash
git clone <repository-url>
cd ai_student_assistant
```

### 2. Configure Environment Variables
```bash
# Root directory (optional, only if you use dotenv in Flutter)
copy .env.example .env

# Backend directory
cd backend
copy .env.example .env
```

Fill in backend `.env` with:
- `FIREBASE_PROJECT_ID`: Your Firebase project ID
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
