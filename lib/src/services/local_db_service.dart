import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../models/flashcard.dart';

/// Local database service for offline storage using SQLite
class LocalDbService {
  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_student_assistant.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add embedding metadata columns + contentHash
          await db.execute('ALTER TABLE notes ADD COLUMN contentHash TEXT');
          await db.execute('ALTER TABLE notes ADD COLUMN embeddingModel TEXT');
          await db.execute(
            'ALTER TABLE notes ADD COLUMN embeddingDimension INTEGER',
          );
        }
      },
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        days TEXT NOT NULL,
        times TEXT NOT NULL,
        location TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        notificationsEnabled INTEGER DEFAULT 1,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        summary TEXT,
        embedding BLOB,
        courseId TEXT,
        contentHash TEXT,
        embeddingModel TEXT,
        embeddingDimension INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        noteId TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        difficulty INTEGER DEFAULT 3,
        timesReviewed INTEGER DEFAULT 0,
        lastReviewed INTEGER,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        date INTEGER NOT NULL,
        status INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // COURSES

  /// Get all courses
  Future<List<Course>> getCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'name');
    return maps.map((map) => Course.fromLocalMap(map)).toList();
  }

  /// Save course
  Future<void> saveCourse(Course course) async {
    final db = await database;
    await db.insert(
      'courses',
      course.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    final db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }

  /// Get unsynced courses
  Future<List<Course>> getUnsyncedCourses() async {
    final db = await database;
    final maps = await db.query('courses', where: 'synced = ?', whereArgs: [0]);
    return maps.map((map) => Course.fromLocalMap(map)).toList();
  }

  /// Mark course as synced
  Future<void> markCourseAsSynced(String courseId) async {
    final db = await database;
    await db.update(
      'courses',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  // NOTES

  /// Get all notes
  Future<List<Note>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'updatedAt DESC');
    return maps.map((map) => Note.fromLocalMap(map)).toList();
  }

  /// Save note
  Future<void> saveNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR body LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Note.fromLocalMap(map)).toList();
  }

  /// Get unsynced notes
  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final maps = await db.query('notes', where: 'synced = ?', whereArgs: [0]);
    return maps.map((map) => Note.fromLocalMap(map)).toList();
  }

  /// Get all notes (alias for getNotes)
  Future<List<Note>> getAllNotes() async {
    return await getNotes();
  }

  /// Get notes for a specific course
  Future<List<Note>> getNotesForCourse(String courseId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Note.fromLocalMap(map)).toList();
  }

  /// Mark note as synced
  Future<void> markNoteAsSynced(String noteId) async {
    final db = await database;
    await db.update(
      'notes',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  // FLASHCARDS

  /// Get all flashcards
  Future<List<Flashcard>> getFlashcards() async {
    final db = await database;
    final maps = await db.query('flashcards', orderBy: 'createdAt DESC');
    return maps.map((map) => Flashcard.fromLocalMap(map)).toList();
  }

  /// Save flashcard
  Future<void> saveFlashcard(Flashcard flashcard) async {
    final db = await database;
    await db.insert(
      'flashcards',
      flashcard.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    final db = await database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [flashcardId]);
  }

  /// Get flashcards due for review
  Future<List<Flashcard>> getDueFlashcards() async {
    final db = await database;
    final maps = await db.query('flashcards');
    final flashcards = maps.map((map) => Flashcard.fromLocalMap(map)).toList();
    return flashcards.where((card) => card.isDueForReview).toList();
  }

  /// Get unsynced flashcards
  Future<List<Flashcard>> getUnsyncedFlashcards() async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps.map((map) => Flashcard.fromLocalMap(map)).toList();
  }

  /// Mark flashcard as synced
  Future<void> markFlashcardAsSynced(String flashcardId) async {
    final db = await database;
    await db.update(
      'flashcards',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [flashcardId],
    );
  }

  // ATTENDANCE

  /// Save attendance record
  Future<void> saveAttendance({
    required String courseId,
    required DateTime date,
    required bool isPresent,
  }) async {
    final db = await database;
    final id = '${courseId}_${date.millisecondsSinceEpoch}';

    await db.insert('attendance', {
      'id': id,
      'courseId': courseId,
      'date': date.millisecondsSinceEpoch,
      'status': isPresent ? 1 : 0,
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get attendance for course
  Future<List<Map<String, dynamic>>> getAttendanceForCourse(
    String courseId,
  ) async {
    final db = await database;
    return await db.query(
      'attendance',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'date DESC',
    );
  }

  /// Calculate attendance rate for course
  Future<double> getAttendanceRate(String courseId) async {
    final records = await getAttendanceForCourse(courseId);
    if (records.isEmpty) return 0.0;

    final presentCount =
        records.where((record) => record['status'] == 1).length;
    return presentCount / records.length;
  }

  // UTILITY

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('courses');
    await db.delete('notes');
    await db.delete('flashcards');
    await db.delete('attendance');
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final courseCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM courses'),
        ) ??
        0;

    final noteCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM notes'),
        ) ??
        0;

    final flashcardCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM flashcards'),
        ) ??
        0;

    final attendanceCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM attendance'),
        ) ??
        0;

    return {
      'courses': courseCount,
      'notes': noteCount,
      'flashcards': flashcardCount,
      'attendance': attendanceCount,
    };
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// Local database service provider
final localDbServiceProvider = Provider<LocalDbService>((ref) {
  return LocalDbService();
});
