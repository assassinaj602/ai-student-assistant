import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/firestore_data_service.dart';
import 'auth_provider.dart';

// Use the unified provider defined in firestore_data_service.dart

// Notes stream provider (real-time updates)
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        final dataService = ref.watch(firestoreDataServiceProvider);
        return dataService.watchNotes();
      }
      return Stream.value(<Note>[]);
    },
    loading: () => Stream.value(<Note>[]),
    error: (_, __) => Stream.value(<Note>[]),
  );
});

// Notes notifier for actions
final notesNotifierProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<void>>((ref) {
      final dataService = ref.watch(firestoreDataServiceProvider);
      return NotesNotifier(dataService);
    });

class NotesNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreDataService _dataService;

  NotesNotifier(this._dataService) : super(const AsyncValue.data(null));

  Future<String> createNote(
    String title,
    String content, {
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      final note = Note(
        id: '', // Will be assigned by Firestore
        title: title,
        body: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final noteId = await _dataService.saveNote(note);
      state = const AsyncValue.data(null);
      return noteId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _dataService.saveNote(updatedNote);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      await _dataService.deleteNote(noteId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    try {
      return await _dataService.searchNotes(query);
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  Future<String> summarizeNote(String content) async {
    try {
      return await _dataService.summarizeNote(content);
    } catch (e) {
      print('Summarization error: $e');
      rethrow;
    }
  }
}

// Search results provider
final noteSearchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<Note>>>((ref) {
      final dataService = ref.watch(firestoreDataServiceProvider);
      return SearchNotifier(dataService);
    });

class SearchNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final FirestoreDataService _dataService;

  SearchNotifier(this._dataService) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _dataService.searchNotes(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}
