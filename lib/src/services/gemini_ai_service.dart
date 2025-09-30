import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../models/flashcard.dart' as models;
import 'ai_backend.dart';

/// Direct Gemini AI service - no backend needed
class GeminiAIService implements AIBackend {
  GeminiAIService();

  // Stable model preference order (fast -> more capable). Avoid tentative future
  // model names that may not yet be enabled for a given key/account to reduce
  // probe failures. You can override with GEMINI_MODEL in .env.
  static const List<String> _defaultModelNames = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-flash-latest', // alias that maps to current recommended flash
    'gemini-pro',
  ];

  List<String> get _modelNames {
    final override = dotenv.env['GEMINI_MODEL']?.trim();
    final fallbacksRaw = dotenv.env['GEMINI_MODEL_FALLBACKS']?.trim();
    final fallbackList =
        (fallbacksRaw == null || fallbacksRaw.isEmpty)
            ? <String>[]
            : fallbacksRaw
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
    if (override != null && override.isNotEmpty) {
      return [override, ...fallbackList].toSet().toList();
    }
    // Merge defaults with provided fallbacks while preserving order
    final combined = [...fallbackList, ..._defaultModelNames];
    final ordered = <String>[];
    for (final m in combined) {
      if (!ordered.contains(m)) ordered.add(m);
    }
    return ordered;
  }

  GenerativeModel? _model; // selected working model
  String? _activeModelName; // track last successful model name
  String? get activeModelName => _activeModelName;

  String get _apiKey {
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) return envKey.trim();

    // Build-time define fallback
    const buildTime = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
    if (buildTime.isNotEmpty) return buildTime;

    // Temporary fallback for development (REMOVE IN PRODUCTION)
    const devKey = 'AIzaSyA6rafof_TPICMliKFzl9aSf9Mv32g2Ff4';
    if (kDebugMode && devKey.isNotEmpty) {
      if (kDebugMode)
        debugPrint(
          'Using hardcoded dev API key (INSECURE - remove in production)',
        );
      return devKey;
    }

    throw Exception(
      'Gemini API key missing. Set GEMINI_API_KEY in .env, --dart-define, or remove hardcode fallback.',
    );
  }

  Future<GenerativeModel> _getModel() async {
    if (_model != null) return _model!;

    final errors = <String>[];
    for (final name in _modelNames) {
      try {
        final candidate = GenerativeModel(
          model: name,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 768,
            responseMimeType: 'text/plain',
          ),
        );
        // Lightweight probe: some backends may reject empty or 'ping', so keep
        // it trivial but meaningful.
        final probe = await candidate.generateContent([
          Content.text('health check'),
        ]);
        if ((probe.text ?? '').isNotEmpty) {
          _model = candidate;
          _activeModelName = name;
          if (kDebugMode) debugPrint('Gemini model selected: $name');
          return candidate;
        }
        errors.add('$name returned empty response');
      } catch (e) {
        errors.add('$name: $e');
        if (kDebugMode) debugPrint('Model $name probe failed: $e');
      }
    }
    final details =
        errors.isEmpty ? 'No models attempted.' : errors.join(' | ');
    throw Exception('No Gemini model available. Details: $details');
  }

  @override
  Future<String> chat(
    String prompt, {
    List<AIMessage> history = const [],
  }) async {
    final model = await _getModel();
    // Fold history into ONE prompt to avoid role parsing bugs.
    final recent = history
        .take(8)
        .map((h) {
          final role = h.role == 'user' ? 'User' : 'Assistant';
          return '$role: ${_sanitize(h.content)}';
        })
        .join('\n');
    final system =
        'You are a concise, helpful academic study assistant. Use markdown for lists/code when beneficial.';
    final fullPrompt = [
      system,
      if (recent.isNotEmpty) recent,
      'User: ${_sanitize(prompt)}',
      'Assistant:',
    ].join('\n\n');
    try {
      final res = await model.generateContent([Content.text(fullPrompt)]);
      final text = res.text?.trim();
      if (text == null || text.isEmpty)
        return 'I\'m not sure how to answer that.';
      return text;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('NotInitializedError')) {
        throw Exception(
          'Gemini SDK not initialized. Ensure GEMINI_API_KEY is valid and internet connection is available. Raw: $msg',
        );
      }
      _model = null;
      try {
        final retryModel = await _getModel();
        final res = await retryModel.generateContent([
          Content.text(fullPrompt),
        ]);
        final retryText = res.text?.trim() ?? '';
        if (retryText.isEmpty) return 'I\'m not sure.';
        return retryText;
      } catch (inner) {
        throw Exception('Chat failed after retry: $e | retry error: $inner');
      }
    }
  }

  @override
  Future<String> summarize(String text, {int maxWords = 150}) async {
    final model = await _getModel();
    final clean = _sanitize(text).trim();
    if (clean.isEmpty) throw Exception('Text cannot be empty');
    final limited =
        clean.length > 6000 ? clean.substring(0, 6000) + '…' : clean;
    final primary =
        'Summarize the content for a student. Target ~$maxWords words. Output markdown:\n'
        '- Brief intro (1 sentence)\n'
        '- Bullet key points (use - )\n'
        '- Short concluding takeaway.\n'
        'Avoid repeating titles, avoid filler.\n\nCONTENT:\n$limited\n\nSUMMARY:';
    final fallback =
        'Provide a concise plain text summary (~$maxWords words):\n$limited\nSummary:';
    try {
      var res = await model.generateContent([Content.text(primary)]);
      var out = res.text?.trim() ?? '';
      if (out.isEmpty || out.toLowerCase().contains('unhandled format')) {
        res = await model.generateContent([Content.text(fallback)]);
        out = res.text?.trim() ?? '';
      }
      if (out.isEmpty) throw Exception('Empty summary');
      return out;
    } catch (e) {
      _model = null;
      final msg = e.toString();
      if (msg.contains('NotInitializedError')) {
        throw Exception(
          'Gemini SDK not initialized during summarize. Check GEMINI_API_KEY / network. Raw: $msg',
        );
      }
      throw Exception('Summarization failed: $e');
    }
  }

  @override
  Future<List<models.Flashcard>> generateFlashcards(
    String content, {
    int count = 5,
  }) async {
    final model = await _getModel();
    final clean = _sanitize(content);
    if (clean.length < 40) {
      throw Exception('Provide more content (min ~40 chars) for flashcards');
    }
    final limited =
        clean.length > 5500 ? clean.substring(0, 5500) + '…' : clean;
    final prompt =
        'Create up to $count high-quality study flashcards from the content. '
        'Return STRICT JSON array (no prose, no markdown fences). Schema: '
        '[{"q":"question","a":"answer"}, ...]. '
        'Questions should be concise; answers 1-3 sentences. Content:\n$limited\n\nJSON:';
    try {
      final r = await model.generateContent([Content.text(prompt)]);
      var raw = (r.text ?? '').trim();
      raw = _stripJsonFences(raw);
      List<dynamic> decoded = [];
      try {
        decoded = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        // Fallback: attempt to extract objects
        decoded = _fallbackJsonExtraction(raw);
      }
      final now = DateTime.now();
      final cards = <models.Flashcard>[];
      for (final item in decoded.take(count)) {
        if (item is Map) {
          final q = (item['q'] ?? item['question'] ?? '').toString().trim();
          final a = (item['a'] ?? item['answer'] ?? '').toString().trim();
          if (q.isNotEmpty && a.isNotEmpty) {
            cards.add(
              models.Flashcard(
                id:
                    now.microsecondsSinceEpoch.toString() +
                    cards.length.toString(),
                question: q,
                answer: a,
                createdAt: now,
                updatedAt: now,
              ),
            );
          }
        }
      }
      if (cards.isEmpty) {
        // Last resort: attempt legacy Q:/A: parsing
        raw = raw.replaceAll('Q:', 'Q:').replaceAll('A:', 'A:');
        return _parseFlashcards(raw, count);
      }
      return cards;
    } catch (e) {
      _model = null;
      final msg = e.toString();
      if (msg.contains('NotInitializedError')) {
        throw Exception(
          'Gemini SDK not initialized during flashcard generation. Check GEMINI_API_KEY / network. Raw: $msg',
        );
      }
      throw Exception('Flashcard generation failed: $e');
    }
  }

  List<models.Flashcard> _parseFlashcards(String text, int maxCount) {
    final flashcards = <models.Flashcard>[];
    // Normalize line endings & remove code fences / bullets
    text = text
        .replaceAll('```', '')
        .replaceAll('*', '')
        .replaceAll('- Q:', 'Q:')
        .replaceAll('- A:', 'A:');
    final lines = text.split('\n');

    String? currentQuestion;
    String? currentAnswer;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('Q:') || trimmed.startsWith('Question:')) {
        // Save previous flashcard if complete
        if (currentQuestion != null && currentAnswer != null) {
          final now = DateTime.now();
          flashcards.add(
            models.Flashcard(
              id: now.millisecondsSinceEpoch.toString(),
              question: currentQuestion,
              answer: currentAnswer,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        // Start new question
        currentQuestion = trimmed.replaceFirst(
          RegExp(r'^(Q:|Question:)\s*'),
          '',
        );
        currentAnswer = null;
      } else if (trimmed.startsWith('A:') || trimmed.startsWith('Answer:')) {
        // Start answer
        currentAnswer = trimmed.replaceFirst(RegExp(r'^(A:|Answer:)\s*'), '');
      } else if (currentAnswer != null && trimmed.isNotEmpty) {
        // Continue answer
        currentAnswer = '$currentAnswer $trimmed';
      } else if (currentQuestion != null &&
          trimmed.isNotEmpty &&
          currentAnswer == null) {
        // Continue question
        currentQuestion = '$currentQuestion $trimmed';
      }

      // Stop if we have enough flashcards
      if (flashcards.length >= maxCount) {
        break;
      }
    }

    // Add the last flashcard if complete
    if (currentQuestion != null &&
        currentAnswer != null &&
        flashcards.length < maxCount) {
      final now = DateTime.now();
      flashcards.add(
        models.Flashcard(
          id: now.millisecondsSinceEpoch.toString(),
          question: currentQuestion,
          answer: currentAnswer,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return flashcards.take(maxCount).toList();
  }

  // ---------------------------------------------------------------------------
  // Backward compatibility wrappers (legacy method names still used elsewhere)
  // ---------------------------------------------------------------------------
  Future<String> generateChatResponse(
    String message, {
    List<ChatMessage> context = const [],
  }) async {
    final history =
        context
            .map(
              (c) => AIMessage(
                role: c.role,
                content: c.content,
                timestamp: c.timestamp,
              ),
            )
            .toList();
    return chat(message, history: history);
  }

  Future<String> summarizeText(String text, {int maxLength = 150}) async {
    return summarize(text, maxWords: maxLength);
  }
}

/// Simple chat message model
class ChatMessage {
  // Legacy chat message (kept for existing providers/UI reuse)
  final String role;
  final String content;
  final DateTime timestamp;
  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

String _sanitize(String input) {
  return input
      .replaceAll(RegExp(r'```[a-zA-Z]*'), '```')
      .replaceAll('\r', '')
      .trim();
}

String _stripJsonFences(String s) {
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
  final m = fence.firstMatch(s);
  if (m != null) return m.group(1)!.trim();
  return s;
}

List<dynamic> _fallbackJsonExtraction(String raw) {
  final objects = RegExp(r'\{[^}]*\}');
  final matches = objects.allMatches(raw);
  final list = <dynamic>[];
  for (final m in matches) {
    try {
      list.add(jsonDecode(m.group(0)!));
    } catch (_) {}
  }
  return list;
}

/// Provider for Gemini AI service
final geminiAIServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

/// Provider for chat messages (local state)
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
      return ChatMessagesNotifier();
    });

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
  }
}
