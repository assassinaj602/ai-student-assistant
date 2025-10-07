import '../models/flashcard.dart' as models;

/// Unified AI message model used across backends
class AIMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  const AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// Abstract backend contract to allow swapping AI providers in future
abstract class AIBackend {
  /// Free-form chat with optional short history (most recent first or last depending on implementation)
  Future<String> chat(String prompt, {List<AIMessage> history = const []});

  /// Summarize arbitrary text (maxWords is a soft target)
  Future<String> summarize(String text, {int maxWords = 300});

  /// Generate flashcards from study content
  Future<List<models.Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
  });
}
