# Project Structure

This document outlines the organization and architecture of the AI Student Assistant Flutter application.

## 📁 Root Directory Structure

```
ai_student_assistant/
├── 📱 android/                 # Android-specific files
├── 🍎 ios/                     # iOS-specific files  
├── 🌐 web/                     # Web-specific files
├── 📚 lib/                     # Dart source code
├── 🧪 test/                    # Test files
├── 📸 assets/                  # Static assets
├── 📋 docs/                    # Additional documentation
├── 🔧 .github/                 # GitHub workflows and templates
├── 🔥 build/                   # Build outputs (auto-generated)
├── 📄 README.md                # Main project documentation
├── 📜 LICENSE                  # MIT license
├── 🔒 .env.template            # Environment variables template
├── ⚙️ pubspec.yaml             # Flutter dependencies
└── 🔥 firebase.json            # Firebase configuration
```

## 📚 Source Code Organization (`lib/`)

```
lib/
├── 🚀 main.dart               # Application entry point
├── 🎯 firebase_options.dart   # Firebase configuration
└── 📦 src/                    # Source code modules
    ├── 🏗️ models/             # Data models and entities
    ├── 🔄 providers/          # Riverpod state providers  
    ├── 🖥️ screens/            # UI screens and pages
    ├── 🔧 services/           # Business logic and APIs
    ├── 🧩 widgets/            # Reusable UI components
    └── 🎨 themes/             # App themes and styling
```

### 🏗️ Models (`lib/src/models/`)

Data structures and entity definitions:

```
models/
├── 👤 user.dart              # User account model
├── 📚 course.dart            # Course/subject model
├── 🎯 flashcard.dart         # Flashcard data model
├── 📝 note.dart              # Note/document model
├── 💬 chat_message.dart      # Chat message model
├── 📅 timetable_entry.dart   # Schedule entry model
└── 📊 attendance.dart        # Attendance record model
```

### 🔄 Providers (`lib/src/providers/`)

Riverpod state management providers:

```
providers/
├── 🔐 auth_providers.dart    # Authentication state
├── 💬 chat_providers.dart    # AI chat state management  
├── 🎯 flashcard_providers.dart # Flashcard state
├── 📚 course_providers.dart  # Course management state
├── 📝 note_providers.dart    # Notes state management
└── 📊 attendance_providers.dart # Attendance tracking
```

### 🖥️ Screens (`lib/src/screens/`)

Main application screens and pages:

```
screens/
├── 🏠 dashboard_screen.dart        # Main dashboard
├── 🔐 auth/                        # Authentication screens
│   ├── login_screen.dart
│   ├── register_screen.dart  
│   └── profile_screen.dart
├── 💬 chat/                        # AI chat interface
│   ├── chat_screen.dart
│   └── chat_history_screen.dart
├── 🎯 flashcards/                  # Flashcard management
│   ├── flashcard_list_screen.dart
│   ├── flashcard_review_screen.dart
│   └── flashcard_create_screen.dart
├── 📚 courses/                     # Course management
│   ├── course_list_screen.dart
│   ├── course_detail_screen.dart
│   └── timetable_screen.dart
├── 📝 notes/                       # Note-taking
│   ├── note_list_screen.dart
│   ├── note_editor_screen.dart
│   └── note_search_screen.dart
└── ⚙️ settings/                    # App settings
    ├── settings_screen.dart
    └── about_screen.dart
```

### 🔧 Services (`lib/src/services/`)

Business logic and external API integrations:

```
services/
├── 🔐 firebase_service.dart      # Firebase operations
├── 🤖 openrouter_ai_service.dart # AI chat service
├── 📱 local_storage_service.dart # SQLite operations
├── 🔔 notification_service.dart  # Local notifications
├── 📊 analytics_service.dart     # Usage analytics
├── 🔄 sync_service.dart          # Data synchronization
└── 🎯 ai_providers.dart          # AI model management
```

### 🧩 Widgets (`lib/src/widgets/`)

Reusable UI components:

```
widgets/
├── 🎯 flashcard_widget.dart      # Flashcard display component
├── 💬 chat_bubble.dart           # Chat message bubble
├── 📅 timetable_widget.dart      # Schedule display
├── 📝 note_preview.dart          # Note preview card
├── 🔄 loading_indicator.dart     # Loading animations
└── 🎨 themed_button.dart         # Custom styled buttons
```

## 🧪 Testing Structure (`test/`)

```
test/
├── 🔬 unit/                      # Unit tests
│   ├── models/                   # Model tests
│   ├── services/                 # Service logic tests  
│   └── providers/                # Provider tests
├── 🧩 widget/                    # Widget tests
│   ├── screens/                  # Screen widget tests
│   └── components/               # Component tests
├── 🔄 integration/               # Integration tests
│   ├── auth_flow_test.dart       # Authentication flow
│   ├── chat_flow_test.dart       # AI chat integration
│   └── flashcard_flow_test.dart  # Flashcard workflow
└── 🎭 mocks/                     # Mock data and services
    ├── mock_firebase.dart
    ├── mock_ai_service.dart
    └── test_data.dart
```

## 📸 Assets Structure (`assets/`)

```
assets/
├── 📷 screenshots/               # App screenshots for README
├── 🎨 images/                    # UI images and icons
├── 🔤 fonts/                     # Custom fonts
└── 📋 data/                      # Static data files
    ├── sample_courses.json
    └── default_flashcards.json
```

## 🔧 GitHub Configuration (`.github/`)

```
.github/
├── 📋 ISSUE_TEMPLATE/            # Issue templates
│   ├── bug_report.md
│   ├── feature_request.md
│   └── documentation.md
├── 📝 pull_request_template.md   # PR template
└── 🔄 workflows/                 # GitHub Actions (future)
    ├── ci.yml
    ├── deploy.yml
    └── release.yml
```

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Flutter dependencies and metadata |
| `firebase.json` | Firebase hosting and functions config |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Database indexes |
| `.env.template` | Environment variables template |
| `.gitignore` | Git ignore patterns |
| `analysis_options.yaml` | Dart analyzer configuration |

## 🏗️ Architecture Patterns

### State Management
- **Riverpod**: Primary state management solution
- **Provider Pattern**: For dependency injection
- **Repository Pattern**: For data access abstraction

### Code Organization
- **Feature-based**: Code organized by feature/domain
- **Layered Architecture**: Clear separation of concerns
- **Clean Architecture**: Domain, data, and presentation layers

### Design Patterns
- **Repository Pattern**: Data access abstraction
- **Factory Pattern**: Service initialization
- **Observer Pattern**: State change notifications
- **Singleton Pattern**: Service instances

## 📱 Platform-Specific Code

### Android (`android/`)
- Native Android configuration
- Gradle build files
- Android manifest
- Google Services configuration

### iOS (`ios/`)
- Xcode project configuration
- iOS-specific settings
- Info.plist configuration
- Podfile for dependencies

### Web (`web/`)
- HTML entry point
- Web-specific assets
- Progressive Web App configuration

## 🔄 Data Flow

```
UI (Screens/Widgets)
    ↕️
Providers (Riverpod)
    ↕️  
Services (Business Logic)
    ↕️
External APIs / Local Storage
```

## 🎯 Key Dependencies

| Category | Library | Purpose |
|----------|---------|---------|
| **State Management** | riverpod | Reactive state management |
| **Navigation** | go_router | Declarative routing |
| **HTTP** | dio | API communications |
| **Database** | sqflite | Local SQLite storage |
| **Authentication** | firebase_auth | User authentication |
| **Cloud Storage** | cloud_firestore | Real-time database |
| **Notifications** | flutter_local_notifications | Local notifications |

## 🔒 Security Considerations

- **API Keys**: Stored in environment variables
- **Authentication**: Firebase Auth with secure tokens
- **Data Validation**: Input sanitization and validation
- **Secure Storage**: Encrypted local storage for sensitive data

---

*This structure is designed for scalability, maintainability, and clear separation of concerns.*