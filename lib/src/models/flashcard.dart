/// Flashcard model for AI-generated study cards
class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String? noteId; // Optional link to source note
  final DateTime createdAt;
  final DateTime updatedAt;
  final int difficulty; // 1-5 scale
  final int timesReviewed;
  final DateTime? lastReviewed;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.noteId,
    required this.createdAt,
    required this.updatedAt,
    this.difficulty = 3,
    this.timesReviewed = 0,
    this.lastReviewed,
  });

  /// Create Flashcard from Firestore document data
  factory Flashcard.fromMap(Map<String, dynamic> map, String id) {
    return Flashcard(
      id: id,
      question: map['question'] as String,
      answer: map['answer'] as String,
      noteId: map['noteId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      difficulty: map['difficulty'] as int? ?? 3,
      timesReviewed: map['timesReviewed'] as int? ?? 0,
      lastReviewed:
          map['lastReviewed'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'] as int)
              : null,
    );
  }

  /// Convert Flashcard to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'noteId': noteId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'difficulty': difficulty,
      'timesReviewed': timesReviewed,
      'lastReviewed': lastReviewed?.millisecondsSinceEpoch,
    };
  }

  /// Create Flashcard from local database data
  factory Flashcard.fromLocalMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      noteId: map['noteId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      difficulty: map['difficulty'] as int? ?? 3,
      timesReviewed: map['timesReviewed'] as int? ?? 0,
      lastReviewed:
          map['lastReviewed'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewed'] as int)
              : null,
    );
  }

  /// Convert Flashcard to local database data
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'noteId': noteId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'difficulty': difficulty,
      'timesReviewed': timesReviewed,
      'lastReviewed': lastReviewed?.millisecondsSinceEpoch,
      'synced': 0, // Always mark as unsynced when creating local entries
    };
  }

  /// Create a copy of Flashcard with updated fields
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? noteId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? difficulty,
    int? timesReviewed,
    DateTime? lastReviewed,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      noteId: noteId ?? this.noteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      difficulty: difficulty ?? this.difficulty,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  /// Mark flashcard as reviewed with optional difficulty update
  Flashcard markAsReviewed({int? newDifficulty}) {
    return copyWith(
      timesReviewed: timesReviewed + 1,
      lastReviewed: DateTime.now(),
      difficulty: newDifficulty ?? difficulty,
      updatedAt: DateTime.now(),
    );
  }

  /// Get difficulty as human-readable string
  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Very Hard';
      default:
        return 'Medium';
    }
  }

  /// Check if flashcard is due for review based on spaced repetition
  bool get isDueForReview {
    if (lastReviewed == null) return true;

    // Simple spaced repetition algorithm
    final daysSinceReview = DateTime.now().difference(lastReviewed!).inDays;
    final reviewInterval = _calculateReviewInterval();

    return daysSinceReview >= reviewInterval;
  }

  /// Calculate review interval based on difficulty and review count
  int _calculateReviewInterval() {
    // Simple algorithm: easier cards have longer intervals
    final baseInterval = switch (difficulty) {
      1 => 7, // Very easy: 1 week
      2 => 5, // Easy: 5 days
      3 => 3, // Medium: 3 days
      4 => 2, // Hard: 2 days
      5 => 1, // Very hard: 1 day
      _ => 3,
    };

    // Increase interval based on successful reviews
    final multiplier = (timesReviewed / 5).floor() + 1;
    return baseInterval * multiplier;
  }

  /// Get preview of question (first 50 characters)
  String get questionPreview {
    if (question.length <= 50) return question;
    return '${question.substring(0, 47)}...';
  }

  /// Get preview of answer (first 50 characters)
  String get answerPreview {
    if (answer.length <= 50) return answer;
    return '${answer.substring(0, 47)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Flashcard(id: $id, question: $questionPreview, difficulty: $difficulty)';
  }
}
