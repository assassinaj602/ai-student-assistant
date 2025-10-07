import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../services/firebase_service.dart';

/// Auth provider state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Auth provider notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _firebaseService;
  final GoogleSignIn _googleSignIn;

  AuthNotifier(this._firebaseService, this._googleSignIn)
    : super(const AuthState()) {
    _init();
  }

  /// Initialize auth state listener
  void _init() {
    print('Initializing auth state listener...');

    auth.FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      print('Auth state changed: ${firebaseUser?.email ?? 'null'}');
      if (firebaseUser != null) {
        print('User signed in, handling user data...');
        _handleUserSignedIn(firebaseUser);
      } else {
        print('No user, setting empty auth state');
        state = const AuthState();
      }
    });

    // Set initial state to not loading
    Timer(const Duration(milliseconds: 100), () {
      if (state.isLoading && state.user == null) {
        print('Setting initial non-loading state');
        state = const AuthState();
      }
    });
  }

  /// Handle user signed in event
  Future<void> _handleUserSignedIn(auth.User firebaseUser) async {
    try {
      print('Handling signed in user: ${firebaseUser.email}');

      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Set user immediately to prevent infinite loading
      print('Setting auth state with user immediately');
      state = AuthState(user: user);

      // Save to Firestore in background (don't block UI)
      _firebaseService
          .saveUser(user)
          .timeout(const Duration(seconds: 5))
          .catchError((e) {
            print(
              'Background Firestore save failed: $e (UI continues normally)',
            );
          });
    } catch (e) {
      print('Error creating user object: $e');
      // Still set a basic user to prevent infinite loading
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      state = AuthState(user: user);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // State will be updated by auth state listener
    } on auth.FirebaseAuthException catch (e) {
      print('Email sign-in error: code=${e.code}, message=${e.message}');
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Create user with email and password
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Requested UX: after sign-up, return user to Sign In screen instead of auto-login
      // Firebase automatically signs in the newly created user; we sign out immediately.
      await auth.FirebaseAuth.instance.signOut();
      // Optionally revoke GoogleSignIn too (noop for email/password)
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Stop loading; UI will remain on login screen via authState stream (null user)
      state = state.copyWith(isLoading: false);
    } on auth.FirebaseAuthException catch (e) {
      print('Email sign-up error: code=${e.code}, message=${e.message}');
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      print('Starting Google sign-in...');
      state = state.copyWith(isLoading: true, error: null);

      if (kIsWeb) {
        // For web, use Firebase Auth directly - avoid google_sign_in_web issues
        print('Using Firebase Auth popup for web');
        final provider = auth.GoogleAuthProvider();
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});

        final result = await auth.FirebaseAuth.instance.signInWithPopup(
          provider,
        );
        print('Firebase popup sign-in successful: ${result.user?.email}');
      } else {
        // For mobile, use google_sign_in
        print('Using GoogleSignIn plugin for mobile');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('User cancelled Google sign-in');
          state = state.copyWith(isLoading: false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await auth.FirebaseAuth.instance.signInWithCredential(credential);
      }

      print('Google sign-in complete, waiting for auth state change...');
    } catch (e) {
      print('Google sign-in error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        auth.FirebaseAuth.instance.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      state = state.copyWith(error: 'Sign out failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }
  }

  /// Get user-friendly error message from FirebaseAuthException
  String _getAuthErrorMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'operation-not-supported-in-this-environment':
        return 'Sign-in is not supported in this environment. If you are on Web, ensure you are running from an allowed domain (e.g., localhost) and not from a file URL.';
      case 'unauthorized-domain':
        return 'This domain is not authorized for OAuth operations. Add it to Firebase Authentication > Settings > Authorized domains (e.g., localhost).';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        final msg = e.message ?? 'An authentication error occurred.';
        // Include code to aid web debugging
        return '$msg (code: ${e.code})';
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete all user data from Firestore first
      await _firebaseService.deleteUserData(user.uid);

      // Delete Firebase Auth account
      await user.delete();

      // Clear local state
      state = const AuthState();
    } on auth.FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e));
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: $e',
      );
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final googleSignIn = GoogleSignIn();
  return AuthNotifier(firebaseService, googleSignIn);
});

/// Auth state provider for easier access to current user
final authStateProvider = StreamProvider<auth.User?>((ref) {
  return auth.FirebaseAuth.instance.authStateChanges();
});

/// Current user provider
final currentUserProvider = Provider<auth.User?>((ref) {
  return auth.FirebaseAuth.instance.currentUser;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
