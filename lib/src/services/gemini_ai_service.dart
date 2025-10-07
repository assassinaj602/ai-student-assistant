import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_backend.dart';
import '../models/flashcard.dart' as models;

/// Gemini backend removed. This stub prevents accidental usage.
/// All AI calls should use OpenRouter via aiBackendProvider.
class GeminiAIService implements AIBackend {
  @override
  Future<String> chat(
    String prompt, {
    List<AIMessage> history = const [],
  }) async {
    throw UnimplementedError(
      'Gemini backend is disabled. Use OpenRouter instead.',
    );
  }

  @override
  Future<String> summarize(String text, {int maxWords = 150}) async {
    throw UnimplementedError(
      'Gemini backend is disabled. Use OpenRouter instead.',
    );
  }

  @override
  Future<List<models.Flashcard>> generateFlashcards(
    String content, {
    int count = 5,
  }) async {
    throw UnimplementedError(
      'Gemini backend is disabled. Use OpenRouter instead.',
    );
  }
}

final geminiAIServiceProvider = Provider<GeminiAIService>(
  (ref) => GeminiAIService(),
);
