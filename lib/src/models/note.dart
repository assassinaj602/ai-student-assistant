import 'dart:typed_data';
import 'dart:math' as Math;

/// Note model representing user notes with AI features
class Note {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? summary; // AI-generated summary
  final List<double>? embedding; // Vector embedding for semantic search
  final String? courseId; // Optional link to a course
  final String?
  contentHash; // Hash of body used for embedding refresh heuristic
  final String? embeddingModel; // Model name used to generate current embedding
  final int? embeddingDimension; // Dimension of embedding vector

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.summary,
    this.embedding,
    this.courseId,
    this.contentHash,
    this.embeddingModel,
    this.embeddingDimension,
  });

  /// Create Note from Firestore document data
  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      summary: map['summary'] as String?,
      embedding:
          map['embedding'] != null
              ? List<double>.from(map['embedding'] as List)
              : null,
      courseId: map['courseId'] as String?,
      contentHash: map['contentHash'] as String?,
      embeddingModel: map['embeddingModel'] as String?,
      embeddingDimension: map['embeddingDimension'] as int?,
    );
  }

  /// Convert Note to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'summary': summary,
      'embedding': embedding,
      'courseId': courseId,
      'contentHash': contentHash,
      'embeddingModel': embeddingModel,
      'embeddingDimension': embeddingDimension,
    };
  }

  /// Create Note from local database data
  factory Note.fromLocalMap(Map<String, dynamic> map) {
    List<double>? embeddingList;
    if (map['embedding'] != null) {
      final embeddingBlob = map['embedding'] as Uint8List;
      // Convert bytes back to double list
      // This is a simplified conversion - in production you'd use proper serialization
      final buffer = embeddingBlob.buffer;
      final doubles = buffer.asFloat64List();
      embeddingList = List<double>.from(doubles);
    }

    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      summary: map['summary'] as String?,
      embedding: embeddingList,
      courseId: map['courseId'] as String?,
      contentHash: map['contentHash'] as String?,
      embeddingModel: map['embeddingModel'] as String?,
      embeddingDimension: map['embeddingDimension'] as int?,
    );
  }

  /// Convert Note to local database data
  Map<String, dynamic> toLocalMap() {
    Uint8List? embeddingBlob;
    if (embedding != null) {
      // Convert double list to bytes
      // This is a simplified conversion - in production you'd use proper serialization
      final buffer = Float64List.fromList(embedding!).buffer;
      embeddingBlob = buffer.asUint8List();
    }

    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'summary': summary,
      'embedding': embeddingBlob,
      'courseId': courseId,
      'synced': 0, // Always mark as unsynced when creating local entries
      'contentHash': contentHash,
      'embeddingModel': embeddingModel,
      'embeddingDimension': embeddingDimension,
    };
  }

  /// Create a copy of Note with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? summary,
    List<double>? embedding,
    String? courseId,
    String? contentHash,
    String? embeddingModel,
    int? embeddingDimension,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary ?? this.summary,
      embedding: embedding ?? this.embedding,
      courseId: courseId ?? this.courseId,
      contentHash: contentHash ?? this.contentHash,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      embeddingDimension: embeddingDimension ?? this.embeddingDimension,
    );
  }

  /// Get word count for the note body
  int get wordCount {
    if (body.isEmpty) return 0;
    return body.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Get character count for the note body
  int get characterCount => body.length;

  /// Check if note has AI-generated content
  bool get hasAIContent => summary != null || embedding != null;

  /// Get preview text (first few words of body)
  String get preview {
    if (body.isEmpty) return 'No content';
    final words = body.split(RegExp(r'\s+'));
    if (words.length <= 20) return body;
    return '${words.take(20).join(' ')}...';
  }

  /// Calculate similarity score with another note using cosine similarity
  double? calculateSimilarity(Note other) {
    if (embedding == null || other.embedding == null) return null;
    if (embedding!.length != other.embedding!.length) return null;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embedding!.length; i++) {
      dotProduct += embedding![i] * other.embedding![i];
      normA += embedding![i] * embedding![i];
      normB += other.embedding![i] * other.embedding![i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Note(id: $id, title: $title, wordCount: $wordCount)';
  }
}
