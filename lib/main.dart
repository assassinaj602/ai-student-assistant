import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
    debugPrint('Environment loaded successfully');
  } catch (e) {
    debugPrint('Environment file not found or error loading: $e');
  }
  if (kIsWeb && !envLoaded) {
    debugPrint(
      'Web build: .env asset missing. Ensure .env listed under flutter: assets: in pubspec.yaml (DEV ONLY).',
    );
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Web: ensure auth persistence is set to LOCAL to avoid popup/session issues
    if (kIsWeb) {
      await auth.FirebaseAuth.instance.setPersistence(auth.Persistence.LOCAL);
      debugPrint('Firebase Auth web persistence set to LOCAL');
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // TODO: Show error to user about Firebase configuration
  }

  // Initialize notifications
  try {
    await NotificationService.initialize();
    debugPrint('Notifications initialized successfully');
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // Run the app with Riverpod provider scope
  runApp(const ProviderScope(child: AIStudentAssistantApp()));
}
