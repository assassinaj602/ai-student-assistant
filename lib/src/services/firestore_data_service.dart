import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../models/flashcard.dart' as flashcard_model;
import 'ai_providers.dart';
import 'ai_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Removed legacy direct Gemini service instance to ensure single shared backend usage
  ProviderContainer? _container; // optional external injection

  FirestoreDataService({ProviderContainer? container}) : _container = container;

  AIBackend get _aiBackend {
    final container = _container;
    if (container == null) {
      throw Exception('AI backend not available (ProviderContainer missing).');
    }
    return container.read(aiBackendProvider);
  }

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // Collections paths
  String get _userNotesPath => 'users/$_userId/notes';
  String get _userFlashcardsPath => 'users/$_userId/flashcards';

  // ===========================================================================
  // NOTES OPERATIONS
  // ===========================================================================

  Future<List<Note>> getAllNotes() async {
    try {
      final snapshot =
          await _firestore
              .collection(_userNotesPath)
              .orderBy('updatedAt', descending: true)
              .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Note.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  Stream<List<Note>> watchNotes() {
    return _firestore
        .collection(_userNotesPath)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Note.fromMap(data, doc.id);
          }).toList();
        });
  }

  Future<Note?> getNoteById(String id) async {
    try {
      final doc = await _firestore.collection(_userNotesPath).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Note.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting note: $e');
      return null;
    }
  }

  Future<String> saveNote(Note note) async {
    try {
      final data = note.toMap();
      data.remove('id'); // Don't store ID in document data
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      data['userId'] = _userId;

      if (note.id.isEmpty) {
        // Create new note
        data['createdAt'] = Timestamp.fromDate(DateTime.now());
        final docRef = await _firestore.collection(_userNotesPath).add(data);
        return docRef.id;
      } else {
        // Update existing note
        await _firestore
            .collection(_userNotesPath)
            .doc(note.id)
            .set(data, SetOptions(merge: true));
        return note.id;
      }
    } catch (e) {
      print('Error saving note: $e');
      throw Exception('Failed to save note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      // Delete note
      await _firestore.collection(_userNotesPath).doc(id).delete();

      // Delete associated flashcards
      final flashcards =
          await _firestore
              .collection(_userFlashcardsPath)
              .where('noteId', isEqualTo: id)
              .get();

      final batch = _firestore.batch();
      for (final doc in flashcards.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    try {
      final notes = await getAllNotes();
      return notes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.body.toLowerCase().contains(query.toLowerCase()) ||
            note.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  Future<String> summarizeNote(String content) async {
    try {
      return await _aiBackend.summarize(content);
    } catch (e) {
      print('Error summarizing note: $e');
      throw Exception('Failed to summarize: $e');
    }
  }

  // ===========================================================================
  // FLASHCARDS OPERATIONS
  // ===========================================================================

  Future<List<flashcard_model.Flashcard>> getAllFlashcards() async {
    try {
      final snapshot =
          await _firestore
              .collection(_userFlashcardsPath)
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return flashcard_model.Flashcard.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting flashcards: $e');
      return [];
    }
  }

  Stream<List<flashcard_model.Flashcard>> watchFlashcards() {
    return _firestore
        .collection(_userFlashcardsPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return flashcard_model.Flashcard.fromMap(data, doc.id);
          }).toList();
        });
  }

  Future<List<flashcard_model.Flashcard>> getFlashcardsByNote(
    String noteId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_userFlashcardsPath)
              .where('noteId', isEqualTo: noteId)
              .orderBy('createdAt')
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return flashcard_model.Flashcard.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting flashcards by note: $e');
      return [];
    }
  }

  Future<List<flashcard_model.Flashcard>> generateFlashcardsFromNote(
    String noteId,
    String content, {
    int count = 10,
  }) async {
    try {
      // Generate flashcards using AI
      final generatedCards = await _aiBackend.generateFlashcards(
        content,
        count: count,
      );

      // Save to Firestore
      final batch = _firestore.batch();
      final flashcards = <flashcard_model.Flashcard>[];

      for (int i = 0; i < generatedCards.length; i++) {
        final card = generatedCards[i];
        final docRef = _firestore.collection(_userFlashcardsPath).doc();

        final flashcard = flashcard_model.Flashcard(
          id: docRef.id,
          noteId: noteId,
          question: card.question,
          answer: card.answer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final data = flashcard.toMap();
        data.remove('id');
        data['createdAt'] = Timestamp.fromDate(flashcard.createdAt);
        data['userId'] = _userId;

        batch.set(docRef, data);
        flashcards.add(flashcard);
      }

      await batch.commit();
      return flashcards;
    } catch (e) {
      print('Error generating flashcards: $e');
      throw Exception('Failed to generate flashcards: $e');
    }
  }

  Future<void> deleteFlashcard(String id) async {
    try {
      await _firestore.collection(_userFlashcardsPath).doc(id).delete();
    } catch (e) {
      print('Error deleting flashcard: $e');
      throw Exception('Failed to delete flashcard: $e');
    }
  }

  Future<void> updateFlashcard(flashcard_model.Flashcard flashcard) async {
    try {
      final data = flashcard.toMap();
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(_userFlashcardsPath)
          .doc(flashcard.id)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating flashcard: $e');
      throw Exception('Failed to update flashcard: $e');
    }
  }

  // ===========================================================================
  // BULK OPERATIONS
  // ===========================================================================

  Future<void> syncOfflineChanges() async {
    // This would handle offline sync if needed in the future
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      print('Error syncing offline changes: $e');
    }
  }

  Future<Map<String, int>> getUserStats() async {
    try {
      final notesCount =
          (await _firestore.collection(_userNotesPath).count().get()).count;
      final flashcardsCount =
          (await _firestore.collection(_userFlashcardsPath).count().get())
              .count;

      return {
        'notesCount': notesCount ?? 0,
        'flashcardsCount': flashcardsCount ?? 0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'notesCount': 0, 'flashcardsCount': 0};
    }
  }
}

/// Riverpod provider for FirestoreDataService ensuring it can resolve the unified AI backend
final firestoreDataServiceProvider = Provider<FirestoreDataService>((ref) {
  // Provide same container so _aiBackend can resolve aiBackendProvider correctly.
  return FirestoreDataService(container: ref.container);
});
