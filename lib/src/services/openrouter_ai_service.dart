import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_backend.dart';
import 'model_selection.dart';
import '../models/flashcard.dart' as models;

/// OpenRouter-backed AI service (DeepSeek)
/// Loads API key from .env (OPENROUTER_API_KEY). Also supports --dart-define as a fallback.
class OpenRouterAIService implements AIBackend {
  final String model;
  final String? apiKeyOverride; // optional for testing

  static String _defaultModel() {
    const m = String.fromEnvironment('OPENROUTER_MODEL');
    return m.isNotEmpty ? m : 'deepseek/deepseek-chat-v3.1:free';
  }

  OpenRouterAIService({String? model, this.apiKeyOverride})
    : model = model ?? _defaultModel();

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  String get _apiKey {
    if (apiKeyOverride != null && apiKeyOverride!.isNotEmpty) {
      return apiKeyOverride!;
    }
    // Try .env via flutter_dotenv first, but guard if dotenv wasn't initialized
    try {
      final envKey = dotenv.maybeGet('OPENROUTER_API_KEY') ?? '';
      if (envKey.isNotEmpty) return envKey;
    } catch (_) {
      // ignore: dotenv not initialized or asset missing; fall through to dart-define
    }
    const k = String.fromEnvironment('OPENROUTER_API_KEY');
    if (k.isNotEmpty) return k;
    throw Exception(
      'OPENROUTER_API_KEY missing. Provide it in .env (for mobile/desktop) or as --dart-define OPENROUTER_API_KEY=... (especially for web).',
    );
  }

  Map<String, String> _headers() {
    final h = <String, String>{
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'AI Student Assistant',
    };
    try {
      h['HTTP-Referer'] =
          Uri.base.origin; // helps OpenRouter attribute web origin
    } catch (_) {}
    return h;
  }

  Future<String> _chatRaw(
    String prompt, {
    List<AIMessage> history = const [],
  }) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'You are a concise, helpful academic study assistant. Use markdown when useful.',
      },
    ];
    for (final m in history) {
      messages.add({'role': m.role, 'content': m.content});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
    });
    debugPrint('OpenRouter request: model=$model');
    // Note: Do NOT log the key; logging its length helps confirm it is present
    try {
      debugPrint('OpenRouter key length: ${_apiKey.length}');
    } catch (_) {}

    final r = await http
        .post(Uri.parse(_endpoint), headers: _headers(), body: body)
        .timeout(const Duration(minutes: 2));

    if (r.statusCode == 200) {
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final choices = (data['choices'] as List?) ?? const [];
      if (choices.isEmpty) return "I'm not sure.";
      final msg = choices.first['message'] as Map<String, dynamic>?;
      final content = (msg?['content'] ?? '').toString().trim();
      return content.isEmpty ? "I'm not sure." : content;
    }

    final err = 'HTTP ${r.statusCode}: ${r.body}';
    debugPrint('OpenRouter error: $err');
    if (r.statusCode == 401) {
      throw Exception(
        'Unauthorized (401). Check that your OpenRouter API key is valid and that your domain is allowed in the key settings (e.g., http://localhost:<port> for web dev).',
      );
    }
    throw Exception('OpenRouter chat failed: $err');
  }

  @override
  Future<String> chat(
    String prompt, {
    List<AIMessage> history = const [],
  }) async {
    return _chatRaw(prompt, history: history);
  }

  @override
  Future<String> summarize(String text, {int maxWords = 300}) async {
    final prompt =
        'Create a thorough, study-ready summary (~$maxWords words) with these sections:\n'
        '- Key Points (bulleted, concise)\n'
        '- Explanations (short paragraphs for tricky ideas)\n'
        '- Examples (if relevant)\n'
        '- Quick Quiz (3-5 short Q&A)\n\n'
        'Use clear Markdown with headings and bullets. Keep terminology accurate and student-friendly.\n\n'
        'Content to summarize:\n$text';
    return _chatRaw(prompt);
  }

  @override
  Future<List<models.Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
  }) async {
    final prompt =
        'Create $count high-quality flashcards that test understanding (mix basic + conceptual).\n'
        'Return STRICT JSON array: [{"q":"question","a":"answer"}, ...] and nothing else.\n'
        'Guidelines: questions should be specific; answers brief but precise; avoid duplicates.\n\n'
        'Content:\n$content\n\nJSON:';
    final raw = await _chatRaw(prompt);
    final text = raw.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(text);
    final jsonText = (m != null ? m.group(1)! : text).trim();

    List list;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) {
        throw Exception('Expected a JSON array of flashcards.');
      }
      list = decoded;
    } catch (e) {
      throw Exception('Failed to parse flashcards JSON: $e');
    }

    final now = DateTime.now();
    final cards = <models.Flashcard>[];
    for (final item in list.take(count)) {
      if (item is! Map) continue;
      final q = (item['q'] ?? item['question'] ?? '').toString().trim();
      final a = (item['a'] ?? item['answer'] ?? '').toString().trim();
      if (q.isEmpty || a.isEmpty) continue;
      cards.add(
        models.Flashcard(
          id: '${now.microsecondsSinceEpoch}_${cards.length}',
          question: q,
          answer: a,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (cards.isEmpty) {
      throw Exception('OpenRouter did not return valid flashcards JSON.');
    }
    return cards;
  }
}

// Riverpod provider for OpenRouter service
final openRouterAIServiceProvider = Provider<AIBackend>((ref) {
  // Use the resolved model (respects manual selection or default).
  final modelId = ref.watch(resolvedModelIdProvider);
  return OpenRouterAIService(model: modelId);
});

/// A wrapper that can perform simple rotation across the free model pool when in Auto mode.
final rotatingAIBackendProvider = Provider<AIBackend>((ref) {
  final selected = ref.watch(selectedModelIdProvider);
  if (selected != kAutoModelId) {
    return ref.watch(openRouterAIServiceProvider);
  }
  // Auto: create a thin wrapper that tries models sequentially on transient failures.
  final pool = kDeepSeekFreeModels.map((m) => m.id).toList(growable: false);
  return _RotatingOpenRouterBackend(pool: pool);
});

class _RotatingOpenRouterBackend implements AIBackend {
  final List<String> pool;
  _RotatingOpenRouterBackend({required this.pool});

  Future<T> _tryAll<T>(Future<T> Function(OpenRouterAIService svc) op) async {
    Exception? last;
    for (final id in pool) {
      try {
        final svc = OpenRouterAIService(model: id);
        return await op(svc);
      } catch (e) {
        last = e is Exception ? e : Exception(e.toString());
      }
    }
    throw last ?? Exception('All models failed. Try again later.');
  }

  @override
  Future<String> chat(String prompt, {List<AIMessage> history = const []}) {
    return _tryAll((svc) => svc.chat(prompt, history: history));
  }

  @override
  Future<String> summarize(String text, {int maxWords = 150}) {
    return _tryAll((svc) => svc.summarize(text, maxWords: maxWords));
  }

  @override
  Future<List<models.Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
  }) {
    return _tryAll((svc) => svc.generateFlashcards(content, count: count));
  }
}
