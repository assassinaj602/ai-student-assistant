import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Main application widget that handles routing and authentication state
class AIStudentAssistantApp extends ConsumerWidget {
  const AIStudentAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state to determine which screen to show
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'AI Student Assistant',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          // If user is logged in, show home screen
          if (user != null) {
            return const HomeScreen();
          }
          // If no user, show login screen
          return const LoginScreen();
        },
        loading: () => const _LoadingScreen(),
        error: (error, stackTrace) => _ErrorScreen(error: error.toString()),
      ),
    );
  }
}

/// Loading screen shown during authentication state checks
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading AI Student Assistant...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication state encounters an error
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Loading App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app by rebuilding the widget tree
                  // In a real app, you might want to implement proper error recovery
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
