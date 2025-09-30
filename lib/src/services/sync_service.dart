import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/firebase_service.dart';
import '../services/local_db_service.dart';

/// Sync service for handling offline-first data synchronization
class SyncService {
  final FirebaseService _firebaseService;
  final LocalDbService _localDbService;
  final Connectivity _connectivity;

  SyncService(this._firebaseService, this._localDbService, this._connectivity);

  /// Check if device has internet connectivity
  Future<bool> get hasConnectivity async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Sync all data types
  Future<void> syncAll() async {
    if (!await hasConnectivity) return;

    try {
      await Future.wait([syncCourses(), syncNotes(), syncFlashcards()]);
    } catch (e) {
      // Log error but don't throw to avoid breaking the app
      print('Sync error: $e');
    }
  }

  /// Sync courses with Firebase
  Future<void> syncCourses() async {
    if (!await hasConnectivity) return;

    try {
      // Get unsynced local courses and push to Firebase
      final unsyncedCourses = await _localDbService.getUnsyncedCourses();

      for (final course in unsyncedCourses) {
        try {
          await _firebaseService.saveCourse(course);
          await _localDbService.markCourseAsSynced(course.id);
        } catch (e) {
          // Log individual course sync error but continue with others
          print('Failed to sync course ${course.id}: $e');
        }
      }

      // TODO: Pull updates from Firebase and merge with local data
      // This would involve comparing timestamps and resolving conflicts
      // For now, we implement a simple push-only sync
    } catch (e) {
      throw Exception('Course sync failed: $e');
    }
  }

  /// Sync notes with Firebase
  Future<void> syncNotes() async {
    if (!await hasConnectivity) return;

    try {
      // Get unsynced local notes and push to Firebase
      final unsyncedNotes = await _localDbService.getUnsyncedNotes();

      for (final note in unsyncedNotes) {
        try {
          await _firebaseService.saveNote(note);
          await _localDbService.markNoteAsSynced(note.id);
        } catch (e) {
          // Log individual note sync error but continue with others
          print('Failed to sync note ${note.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Note sync failed: $e');
    }
  }

  /// Sync flashcards with Firebase
  Future<void> syncFlashcards() async {
    if (!await hasConnectivity) return;

    try {
      // Get unsynced local flashcards and push to Firebase
      final unsyncedFlashcards = await _localDbService.getUnsyncedFlashcards();

      for (final flashcard in unsyncedFlashcards) {
        try {
          await _firebaseService.saveFlashcard(flashcard);
          await _localDbService.markFlashcardAsSynced(flashcard.id);
        } catch (e) {
          // Log individual flashcard sync error but continue with others
          print('Failed to sync flashcard ${flashcard.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Flashcard sync failed: $e');
    }
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final hasConnection = await hasConnectivity;

      if (!hasConnection) {
        return SyncStatus(
          isConnected: false,
          lastSyncTime: null,
          pendingItems: await _getPendingItemsCount(),
          status: 'Offline',
        );
      }

      final pendingCount = await _getPendingItemsCount();

      return SyncStatus(
        isConnected: true,
        lastSyncTime: DateTime.now(), // TODO: Store actual last sync time
        pendingItems: pendingCount,
        status: pendingCount > 0 ? 'Syncing...' : 'Up to date',
      );
    } catch (e) {
      return SyncStatus(
        isConnected: false,
        lastSyncTime: null,
        pendingItems: 0,
        status: 'Error: $e',
      );
    }
  }

  /// Get count of pending sync items
  Future<int> _getPendingItemsCount() async {
    try {
      final courses = await _localDbService.getUnsyncedCourses();
      final notes = await _localDbService.getUnsyncedNotes();
      final flashcards = await _localDbService.getUnsyncedFlashcards();

      return courses.length + notes.length + flashcards.length;
    } catch (e) {
      return 0;
    }
  }

  /// Listen to connectivity changes and auto-sync
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Setup auto-sync when connectivity is restored
  void setupAutoSync() {
    connectivityStream.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Delay sync to allow connection to stabilize
        Future.delayed(const Duration(seconds: 2), () {
          syncAll();
        });
      }
    });
  }

  /// Force sync now (useful for manual sync button)
  Future<void> syncNow() async {
    await syncAll();
  }
}

/// Sync status model
class SyncStatus {
  final bool isConnected;
  final DateTime? lastSyncTime;
  final int pendingItems;
  final String status;

  const SyncStatus({
    required this.isConnected,
    required this.lastSyncTime,
    required this.pendingItems,
    required this.status,
  });

  @override
  String toString() {
    return 'SyncStatus(connected: $isConnected, pending: $pendingItems, status: $status)';
  }
}

/// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localDbService = ref.watch(localDbServiceProvider);
  final connectivity = Connectivity();

  final syncService = SyncService(
    firebaseService,
    localDbService,
    connectivity,
  );

  // Setup auto-sync
  syncService.setupAutoSync();

  return syncService;
});

/// Sync status provider
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getSyncStatus();
});
