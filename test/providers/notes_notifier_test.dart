import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_student_assistant/src/providers/notes_provider.dart';
import 'package:ai_student_assistant/src/models/note.dart';
import 'package:ai_student_assistant/src/services/firestore_data_service.dart';

// Simplified fake FirestoreDataService for current architecture
class _FakeFirestoreDataService extends FirestoreDataService {
  final Map<String, Note> _notes = {};

  @override
  Future<String> saveNote(Note note) async {
    final id = note.id.isEmpty ? 'note-${_notes.length + 1}' : note.id;
    _notes[id] = note.copyWith(id: id);
    return id;
  }

  @override
  Stream<List<Note>> watchNotes() async* {
    yield _notes.values.toList();
  }

  List<Note> get allNotes => _notes.values.toList();
}

void main() {
  test('NotesNotifier creates a note and returns new id', () async {
    final fake = _FakeFirestoreDataService();
    final container = ProviderContainer(
      overrides: [firestoreDataServiceProvider.overrideWithValue(fake)],
    );

    final notifier = container.read(notesNotifierProvider.notifier);
    final id = await notifier.createNote(
      'Test Title',
      'Body content long enough.',
    );
    expect(id.isNotEmpty, true);
    expect(fake.allNotes.any((n) => n.id == id), true);
  });
}
