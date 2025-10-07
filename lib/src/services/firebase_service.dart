import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../models/flashcard.dart';
import '../models/flashcard_generation.dart';

/// Firebase service for handling Firestore operations
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user ID
  String? get _userId => auth.FirebaseAuth.instance.currentUser?.uid;

  /// Save or update user in Firestore
  Future<void> saveUser(User user) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user from Firestore
  Future<User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return User.fromMap(doc.data()!, doc.id);
  }

  // COURSES

  /// Get user courses stream
  Stream<List<Course>> getUserCoursesStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('courses')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Course.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Add or update course
  Future<void> saveCourse(Course course) async {
    if (_userId == null) throw Exception('User not authenticated');

    final collection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('courses');

    if (course.id.isEmpty) {
      // Create new course
      await collection.add(course.toMap());
    } else {
      // Update existing course
      await collection
          .doc(course.id)
          .set(course.toMap(), SetOptions(merge: true));
    }
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('courses')
        .doc(courseId)
        .delete();
  }

  // NOTES

  /// Get user notes stream
  Stream<List<Note>> getUserNotesStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Note.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Add or update note
  /// Save note and return canonical ID (auto-generated if new)
  Future<String> saveNote(Note note) async {
    if (_userId == null) throw Exception('User not authenticated');

    final collection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes');

    if (note.id.isEmpty) {
      // Create new note
      final docRef = await collection.add(note.toMap());
      return docRef.id;
    } else {
      // Update existing note
      await collection.doc(note.id).set(note.toMap(), SetOptions(merge: true));
      return note.id;
    }
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  /// Get all notes as a future (for sync purposes)
  Future<List<Note>> getAllNotes() async {
    if (_userId == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('notes')
            .orderBy('updatedAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => Note.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Search notes by text content
  Future<List<Note>> searchNotes(String query) async {
    if (_userId == null) return [];

    // Note: Firestore doesn't support full-text search natively
    // In production, you'd use Algolia, Elasticsearch, or similar
    final snapshot =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('notes')
            .get();

    final notes =
        snapshot.docs.map((doc) => Note.fromMap(doc.data(), doc.id)).toList();

    // Simple client-side filtering
    return notes.where((note) {
      final searchTerm = query.toLowerCase();
      return note.title.toLowerCase().contains(searchTerm) ||
          note.body.toLowerCase().contains(searchTerm);
    }).toList();
  }

  // FLASHCARDS

  /// Get user flashcards stream
  Stream<List<Flashcard>> getUserFlashcardsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Add flashcard
  Future<void> saveFlashcard(Flashcard flashcard) async {
    if (_userId == null) throw Exception('User not authenticated');

    final collection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards');

    if (flashcard.id.isEmpty) {
      // Create new flashcard
      await collection.add(flashcard.toMap());
    } else {
      // Update existing flashcard
      await collection
          .doc(flashcard.id)
          .set(flashcard.toMap(), SetOptions(merge: true));
    }
  }

  /// Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();
  }

  /// Batch save flashcards (for AI generation)
  Future<void> saveFlashcards(List<Flashcard> flashcards) async {
    if (_userId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final collection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards');

    for (final flashcard in flashcards) {
      if (flashcard.id.isEmpty) {
        // Create new flashcard
        final docRef = collection.doc();
        batch.set(docRef, flashcard.toMap());
      } else {
        // Update existing flashcard
        batch.set(
          collection.doc(flashcard.id),
          flashcard.toMap(),
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  /// Batch save flashcards with history tracking
  Future<String> saveFlashcardsWithHistory({
    required List<Flashcard> flashcards,
    required String sourceText,
    required String sourceTitle,
    String? noteId,
    String generationMethod = 'text_input',
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final flashcardCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcards');

    final generationCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcard_generations');

    // Save flashcards and collect their IDs
    final List<String> flashcardIds = [];

    for (final flashcard in flashcards) {
      final docRef = flashcardCollection.doc();
      batch.set(docRef, flashcard.toMap());
      flashcardIds.add(docRef.id);
    }

    // Create generation history record
    final generation = FlashcardGeneration(
      id: '', // Will be set by Firestore
      sourceText: sourceText,
      sourceTitle: sourceTitle,
      flashcardCount: flashcards.length,
      createdAt: DateTime.now(),
      flashcardIds: flashcardIds,
      noteId: noteId,
      generationMethod: generationMethod,
    );

    final generationDocRef = generationCollection.doc();
    batch.set(generationDocRef, generation.toMap());

    await batch.commit();
    return generationDocRef.id;
  }

  // FLASHCARD GENERATION HISTORY

  /// Get user flashcard generation history stream
  Stream<List<FlashcardGeneration>> getFlashcardGenerationHistoryStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcard_generations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FlashcardGeneration.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get flashcard generation history (latest 50 records)
  Future<List<FlashcardGeneration>> getFlashcardGenerationHistory({
    int limit = 50,
  }) async {
    if (_userId == null) return [];

    final snapshot =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('flashcard_generations')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs
        .map((doc) => FlashcardGeneration.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Delete flashcard generation record
  Future<void> deleteFlashcardGeneration(String generationId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('flashcard_generations')
        .doc(generationId)
        .delete();
  }

  /// Fetch a list of flashcards by their IDs (for reviewing a generation)
  Future<List<Flashcard>> getFlashcardsByIds(List<String> ids) async {
    if (_userId == null) return [];
    if (ids.isEmpty) return [];

    // Firestore whereIn supports up to 10 items per query; chunk if needed
    const chunkSize = 10;
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      chunks.add(
        ids.sublist(i, i + chunkSize > ids.length ? ids.length : i + chunkSize),
      );
    }

    final results = <Flashcard>[];
    for (final chunk in chunks) {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('flashcards')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      results.addAll(
        snapshot.docs.map((d) => Flashcard.fromMap(d.data(), d.id)),
      );
    }

    // Preserve the original order of ids where possible
    final byId = {for (final f in results) f.id: f};
    return ids.map((id) => byId[id]).whereType<Flashcard>().toList();
  }

  // AI QUOTA MANAGEMENT

  /// Get user's AI usage for today
  Future<int> getAIUsageToday() async {
    if (_userId == null) return 0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('ai_usage')
              .doc('${startOfDay.year}-${startOfDay.month}-${startOfDay.day}')
              .get();

      return doc.exists ? (doc.data()?['count'] as int? ?? 0) : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Increment AI usage count
  Future<void> incrementAIUsage() async {
    if (_userId == null) throw Exception('User not authenticated');

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final docId = '${startOfDay.year}-${startOfDay.month}-${startOfDay.day}';

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('ai_usage')
        .doc(docId)
        .set({
          'count': FieldValue.increment(1),
          'date': startOfDay.millisecondsSinceEpoch,
          'lastUpdate': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
  }

  /// Get AI usage history
  Future<Map<String, int>> getAIUsageHistory({int days = 30}) async {
    if (_userId == null) return {};

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('ai_usage')
              .where(
                'date',
                isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
              )
              .where(
                'date',
                isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
              )
              .get();

      final usage = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.fromMillisecondsSinceEpoch(data['date'] as int);
        final key = '${date.year}-${date.month}-${date.day}';
        usage[key] = data['count'] as int? ?? 0;
      }

      return usage;
    } catch (e) {
      return {};
    }
  }

  // USER PROFILE MANAGEMENT

  /// Update user profile data in Firestore
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .set(profileData, SetOptions(merge: true));
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userId == null) throw Exception('User not authenticated');

    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Get user profile stream for real-time updates
  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (_userId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Delete all user data from Firestore
  Future<void> deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user document and all subcollections
    final userDocRef = _firestore.collection('users').doc(userId);

    // Delete courses
    final coursesSnapshot = await userDocRef.collection('courses').get();
    for (final doc in coursesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete notes
    final notesSnapshot = await userDocRef.collection('notes').get();
    for (final doc in notesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete flashcards
    final flashcardsSnapshot = await userDocRef.collection('flashcards').get();
    for (final doc in flashcardsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete flashcard generation history
    final historySnapshot =
        await userDocRef.collection('flashcard_generations').get();
    for (final doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete user document itself
    batch.delete(userDocRef);

    // Commit all deletions
    await batch.commit();
  }
}

/// Firebase service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
