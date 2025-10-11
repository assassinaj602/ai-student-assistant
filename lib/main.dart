import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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

  debugPrint('Starting AI Student Assistant...');
  debugPrint('API key is hardcoded - no .env or --dart-define needed!');

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
