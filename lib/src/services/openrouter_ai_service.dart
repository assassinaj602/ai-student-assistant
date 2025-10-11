import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_backend.dart';
import 'model_selection.dart';
import '../models/flashcard.dart' as models;

/// OpenRouter-backed AI service (DeepSeek)
/// API key is hardcoded directly in the service - no .env or --dart-define needed!
class OpenRouterAIService implements AIBackend {
  // Reuse a single HTTP client for connection keep-alive and efficiency
  static final http.Client _client = http.Client();

  final String model;
  final String? apiKeyOverride; // optional for testing

  // API Key rotation for multiple accounts (4 keys × 50 requests = 200 total per day)
  static int _currentKeyIndex = 0;
  static int _requestCount = 0;
  static final List<String> _apiKeys = [];

  static String _defaultModel() {
    const m = String.fromEnvironment('OPENROUTER_MODEL');
    // Default to auto-rotation for best reliability - will use all 10 models
    // Individual model fallback is handled by the rotating provider
    return m.isNotEmpty ? m : kDeepSeekFreeModels.first.id;
  }

  OpenRouterAIService({String? model, this.apiKeyOverride})
    : model = model ?? _defaultModel();

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // Load all available API keys
  static List<String> _loadApiKeys() {
    if (_apiKeys.isNotEmpty) return _apiKeys;

    final keys = <String>[];

    // Try numbered keys (check each one individually to avoid const issues)
    const key1 = String.fromEnvironment('OPENROUTER_API_KEY_1');
    const key2 = String.fromEnvironment('OPENROUTER_API_KEY_2');
    const key3 = String.fromEnvironment('OPENROUTER_API_KEY_3');
    const key4 = String.fromEnvironment('OPENROUTER_API_KEY_4');

    if (key1.isNotEmpty) {
      keys.add(key1);
      debugPrint('✅ Loaded API key 1');
    } else {
      try {
        final dotenvKey = dotenv.maybeGet('OPENROUTER_API_KEY_1') ?? '';
        if (dotenvKey.isNotEmpty) {
          keys.add(dotenvKey);
          debugPrint('✅ Loaded API key 1 from .env');
        }
      } catch (_) {}
    }

    if (key2.isNotEmpty) {
      keys.add(key2);
      debugPrint('✅ Loaded API key 2');
    } else {
      try {
        final dotenvKey = dotenv.maybeGet('OPENROUTER_API_KEY_2') ?? '';
        if (dotenvKey.isNotEmpty) {
          keys.add(dotenvKey);
          debugPrint('✅ Loaded API key 2 from .env');
        }
      } catch (_) {}
    }

    if (key3.isNotEmpty) {
      keys.add(key3);
      debugPrint('✅ Loaded API key 3');
    } else {
      try {
        final dotenvKey = dotenv.maybeGet('OPENROUTER_API_KEY_3') ?? '';
        if (dotenvKey.isNotEmpty) {
          keys.add(dotenvKey);
          debugPrint('✅ Loaded API key 3 from .env');
        }
      } catch (_) {}
    }

    if (key4.isNotEmpty) {
      keys.add(key4);
      debugPrint('✅ Loaded API key 4');
    } else {
      try {
        final dotenvKey = dotenv.maybeGet('OPENROUTER_API_KEY_4') ?? '';
        if (dotenvKey.isNotEmpty) {
          keys.add(dotenvKey);
          debugPrint('✅ Loaded API key 4 from .env');
        }
      } catch (_) {}
    }

    // Fallback to main key if no numbered keys found
    if (keys.isEmpty) {
      const mainKey = String.fromEnvironment('OPENROUTER_API_KEY');
      if (mainKey.isNotEmpty) {
        keys.add(mainKey);
        debugPrint('✅ Using main API key as fallback');
      } else {
        try {
          final dotenvMainKey = dotenv.maybeGet('OPENROUTER_API_KEY') ?? '';
          if (dotenvMainKey.isNotEmpty) {
            keys.add(dotenvMainKey);
            debugPrint('✅ Using main API key from .env as fallback');
          }
        } catch (_) {}
      }
    }

    _apiKeys.addAll(keys);
    debugPrint('🔑 Total API keys loaded: ${keys.length}');
    return keys;
  }

  String get _apiKey {
    if (apiKeyOverride != null && apiKeyOverride!.isNotEmpty) {
      return apiKeyOverride!;
    }

    // Load all available API keys
    final validKeys = _loadApiKeys();

    if (validKeys.isEmpty) {
      throw Exception(
        '🔐 No OPENROUTER API keys configured!\n\n'
        'For MULTIPLE KEYS (recommended):\n'
        '1. Add to .env file:\n'
        '   OPENROUTER_API_KEY_1=sk-or-v1-account1-key\n'
        '   OPENROUTER_API_KEY_2=sk-or-v1-account2-key\n'
        '   OPENROUTER_API_KEY_3=sk-or-v1-account3-key\n'
        '   OPENROUTER_API_KEY_4=sk-or-v1-account4-key\n\n'
        'For WEB builds:\n'
        '   --dart-define=OPENROUTER_API_KEY_1=key1\n'
        '   --dart-define=OPENROUTER_API_KEY_2=key2 etc.\n\n'
        'For SINGLE KEY (fallback):\n'
        '   OPENROUTER_API_KEY=your_main_key\n\n'
        'Get keys at: https://openrouter.ai/keys',
      );
    }

    // Rotate to next key every ~45 requests to stay under 50 limit per key
    if (_requestCount > 0 && _requestCount % 45 == 0) {
      _currentKeyIndex = (_currentKeyIndex + 1) % validKeys.length;
      debugPrint(
        '🔄 Auto-rotating to API key ${_currentKeyIndex + 1}/${validKeys.length}',
      );
    }

    final currentKey = validKeys[_currentKeyIndex];
    debugPrint(
      '🔑 Using API key ${_currentKeyIndex + 1}/${validKeys.length} (request #$_requestCount)',
    );
    return currentKey;
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
    int retryCount = 0,
    int keyRotationAttempt = 0,
  }) async {
    // Increment request count for key rotation tracking
    _requestCount++;

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
    debugPrint(
      'OpenRouter request: model=$model (attempt ${retryCount + 1}, key attempt ${keyRotationAttempt + 1})',
    );
    // Note: Do NOT log the key; logging its length helps confirm it is present
    try {
      debugPrint('OpenRouter key length: ${_apiKey.length}');
    } catch (_) {}

    try {
      final r = await _client
          .post(Uri.parse(_endpoint), headers: _headers(), body: body)
          .timeout(
            const Duration(seconds: 45),
            onTimeout:
                () => throw Exception('Request timeout after 45 seconds'),
          );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final choices = (data['choices'] as List?) ?? const [];
        if (choices.isEmpty) {
          throw Exception(
            'OpenRouter returned no choices. Response: ${r.body}',
          );
        }
        final msg = choices.first['message'] as Map<String, dynamic>?;
        final content = (msg?['content'] ?? '').toString().trim();
        if (content.isEmpty) {
          throw Exception(
            'OpenRouter returned empty content. Response: ${r.body}',
          );
        }
        return content;
      }

      final err = 'HTTP ${r.statusCode}: ${r.body}';
      debugPrint('OpenRouter error: $err');

      // Handle rate limits with API key rotation
      if (r.statusCode == 429) {
        final validKeys = _loadApiKeys();

        // Try rotating to next API key if we have multiple keys
        if (validKeys.length > 1 && keyRotationAttempt < validKeys.length - 1) {
          _currentKeyIndex = (_currentKeyIndex + 1) % validKeys.length;
          debugPrint(
            '🔄 Rate limited! Rotating to API key ${_currentKeyIndex + 1}/${validKeys.length}',
          );
          await Future.delayed(Duration(milliseconds: 1000)); // Brief delay
          return _chatRaw(
            prompt,
            history: history,
            retryCount: 0, // Reset retry count for new key
            keyRotationAttempt: keyRotationAttempt + 1,
          );
        }

        // If all keys exhausted or single key, do normal retry
        if (retryCount < 2) {
          final delayMs = 3000 * (retryCount + 1); // 3s, 6s
          debugPrint('⏳ All keys rate limited. Retrying after ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          return _chatRaw(
            prompt,
            history: history,
            retryCount: retryCount + 1,
            keyRotationAttempt: keyRotationAttempt,
          );
        }

        throw Exception(
          'Rate limited (429). All API keys have reached their limits. Please try again later.',
        );
      }

      // Handle other transient errors with retry (but don't rotate keys)
      if ((r.statusCode == 502 || r.statusCode == 503 || r.statusCode == 504) &&
          retryCount < 3) {
        final delayMs = 1000 * (retryCount + 1); // 1s, 2s, 3s for server errors
        debugPrint('⏳ Retrying after ${delayMs}ms due to server error...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _chatRaw(
          prompt,
          history: history,
          retryCount: retryCount + 1,
          keyRotationAttempt: keyRotationAttempt,
        );
      }

      if (r.statusCode == 404) {
        throw Exception(
          '❌ OpenRouter 404: Free model blocked!\n\n'
          'Go to https://openrouter.ai/settings/privacy and enable:\n'
          '✅ "Enable free endpoints that may train on inputs"\n'
          '✅ "Enable free endpoints that may publish prompts"\n\n'
          'Then refresh this page.',
        );
      }

      if (r.statusCode == 401) {
        throw Exception(
          'Unauthorized (401). Check that your OpenRouter API key is valid and that your domain is allowed in the key settings (e.g., http://localhost:<port> for web dev).',
        );
      }
      throw Exception('OpenRouter chat failed: $err');
    } on http.ClientException catch (e) {
      if (retryCount < 2) {
        final delayMs = 1000 * (retryCount + 1);
        debugPrint('⏳ Retrying after ${delayMs}ms due to network error...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _chatRaw(prompt, history: history, retryCount: retryCount + 1);
      }
      throw Exception('Network error: ${e.message}');
    }
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
    int attemptCount = 0;

    // Randomize model order to distribute load (avoid everyone hitting same model)
    final shuffledPool = List<String>.from(pool);
    shuffledPool.shuffle();

    for (final id in shuffledPool) {
      attemptCount++;
      try {
        debugPrint('🔄 Trying model $attemptCount/${pool.length}: $id');
        final svc = OpenRouterAIService(model: id);
        final result = await op(svc);
        debugPrint('✅ Success with model: $id');
        return result;
      } on http.ClientException catch (e) {
        // Network/connection errors - try next model immediately
        debugPrint('❌ Network error with $id: ${e.toString()}');
        last = Exception('Network error: ${e.message}');
        continue;
      } catch (e) {
        final errorStr = e.toString();
        debugPrint(
          '❌ Failed with $id: ${errorStr.length > 100 ? errorStr.substring(0, 100) : errorStr}...',
        );

        // Check if it's a 502/503/504 (server overload) - these are transient, try next model
        if (errorStr.contains('502') ||
            errorStr.contains('503') ||
            errorStr.contains('504')) {
          last = Exception('Server temporarily unavailable');
          // Add randomized delay to avoid thundering herd (300-800ms)
          final delayMs =
              300 + (attemptCount * 100) + (DateTime.now().millisecond % 200);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // Check if it's a 429 (rate limit) - add longer delay with jitter
        if (errorStr.contains('429')) {
          last = Exception('Rate limit exceeded');
          // Exponential backoff with jitter: 1-3s, 2-4s, 3-5s, etc.
          final baseDelay = 1000 * attemptCount;
          final jitter = DateTime.now().millisecond % 1000;
          await Future.delayed(Duration(milliseconds: baseDelay + jitter));
          continue;
        }

        // Check if it's 401 (auth) or 404 (model not available) - don't retry others
        if (errorStr.contains('401') || errorStr.contains('404')) {
          throw e is Exception ? e : Exception(e.toString());
        }

        last = e is Exception ? e : Exception(e.toString());

        // For other errors, add small delay to avoid rapid-fire requests
        if (attemptCount < shuffledPool.length) {
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    }

    // All models failed - provide user-friendly error message
    final errorMsg = last?.toString() ?? 'Unknown error';

    // Check if it's a configuration issue
    if (errorMsg.contains('401') || errorMsg.contains('OPENROUTER_API_KEY')) {
      throw Exception(
        '� API Configuration Issue\n\n'
        'Please check your OpenRouter API key settings and try again.',
      );
    }

    // Check if it's a network issue
    if (errorMsg.contains('Network error') || errorMsg.contains('timeout')) {
      throw Exception(
        '🌐 Connection Issue\n\n'
        'Please check your internet connection and try again.',
      );
    }

    // General availability issue
    throw Exception(
      '🤖 AI Service Temporarily Busy\n\n'
      'All AI models are experiencing high demand right now.\n'
      'Please try again in a moment - the system will automatically\n'
      'find an available model for you.',
    );
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
