/// Model for tracking flashcard generation history
class FlashcardGeneration {
  final String id;
  final String sourceText; // The text used to generate flashcards
  final String sourceTitle; // Title/description of the source
  final int flashcardCount; // Number of flashcards generated
  final DateTime createdAt;
  final List<String> flashcardIds; // IDs of generated flashcards
  final String? noteId; // Optional link to source note
  final String generationMethod; // 'text_input', 'note_content', etc.

  const FlashcardGeneration({
    required this.id,
    required this.sourceText,
    required this.sourceTitle,
    required this.flashcardCount,
    required this.createdAt,
    required this.flashcardIds,
    this.noteId,
    this.generationMethod = 'text_input',
  });

  /// Create FlashcardGeneration from Firestore document data
  factory FlashcardGeneration.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardGeneration(
      id: id,
      sourceText: map['sourceText'] as String,
      sourceTitle: map['sourceTitle'] as String,
      flashcardCount: map['flashcardCount'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      flashcardIds: List<String>.from(map['flashcardIds'] as List),
      noteId: map['noteId'] as String?,
      generationMethod: map['generationMethod'] as String? ?? 'text_input',
    );
  }

  /// Convert FlashcardGeneration to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'sourceText': sourceText,
      'sourceTitle': sourceTitle,
      'flashcardCount': flashcardCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'flashcardIds': flashcardIds,
      'noteId': noteId,
      'generationMethod': generationMethod,
    };
  }

  /// Create a copy of FlashcardGeneration with updated fields
  FlashcardGeneration copyWith({
    String? id,
    String? sourceText,
    String? sourceTitle,
    int? flashcardCount,
    DateTime? createdAt,
    List<String>? flashcardIds,
    String? noteId,
    String? generationMethod,
  }) {
    return FlashcardGeneration(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      flashcardCount: flashcardCount ?? this.flashcardCount,
      createdAt: createdAt ?? this.createdAt,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      noteId: noteId ?? this.noteId,
      generationMethod: generationMethod ?? this.generationMethod,
    );
  }

  /// Get preview of source text (first 100 characters)
  String get sourcePreview {
    if (sourceText.length <= 100) return sourceText;
    return '${sourceText.substring(0, 100)}...';
  }

  /// Check if generation was from a note
  bool get isFromNote => noteId != null;

  @override
  String toString() =>
      'FlashcardGeneration(id: $id, title: $sourceTitle, count: $flashcardCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardGeneration &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
