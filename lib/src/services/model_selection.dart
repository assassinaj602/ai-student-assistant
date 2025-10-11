import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preset free DeepSeek models available on OpenRouter.
class ModelOption {
  final String id; // e.g., 'deepseek/deepseek-chat-v3.1:free'
  final String label; // short label for UI
  const ModelOption(this.id, this.label);
}

// Pool of latest free models - prioritized by low demand and reliability
const List<ModelOption> kDeepSeekFreeModels = [
  // Try smaller, less popular models first (lower demand = higher success rate)
  ModelOption('meta-llama/llama-3.2-3b-instruct:free', 'LLaMA 3.2 3B (free)'),
  ModelOption('qwen/qwen3-8b:free', 'Qwen 3 8B (free)'),
  ModelOption('z-ai/glm-4.5-air:free', 'GLM 4.5 Air (free)'),
  ModelOption('gpt-oss-20b:free', 'GPT-OSS 20B (free)'),
  ModelOption('moonshotai/kimi-k2:free', 'Kimi K2 (free)'),

  // Medium demand models
  ModelOption(
    'shisa-ai/shisa-v2-llama3.3-70b:free',
    'Shisa V2 LLaMA 3.3 70B (free)',
  ),
  ModelOption('deepseek/deepseek-r1:free', 'DeepSeek R1 (free, reasoning)'),

  // High demand models (try last)
  ModelOption('deepseek/deepseek-chat-v3-0324:free', 'DeepSeek V3 Chat (free)'),
  ModelOption('meta-llama/llama-3.1-405b:free', 'LLaMA 3.1 405B (free)'),
  ModelOption('meta-llama/llama-4-scout:free', 'LLaMA 4 Scout (free)'),
];

/// Special value representing automatic rotation across the pool.
const String kAutoModelId = 'auto';

class ModelSelection extends StateNotifier<String> {
  static const _prefsKey = 'selected_model_id';

  ModelSelection() : super(_initial()) {
    // Load saved selection asynchronously; fall back to default if absent.
    _loadSaved();
  }

  static String _initial() {
    const env = String.fromEnvironment('OPENROUTER_MODEL');
    if (env.isNotEmpty) return env;
    // Default to auto-rotation for best reliability and user experience
    return kAutoModelId;
  }

  void setModel(String id) {
    state = id;
    _save(id);
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty && saved != state) {
        state = saved;
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _save(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id);
    } catch (_) {
      // ignore
    }
  }
}

/// Holds the currently selected model id. Defaults from --dart-define OPENROUTER_MODEL
final selectedModelIdProvider = StateNotifierProvider<ModelSelection, String>(
  (ref) => ModelSelection(),
);

/// Returns the full list of available options including an 'Auto' choice.
final availableModelOptionsProvider = Provider<List<ModelOption>>((ref) {
  return const [
    ModelOption(kAutoModelId, 'Auto (rotate free DeepSeek)'),
    ...kDeepSeekFreeModels,
  ];
});

/// Resolves the concrete model id to use for requests.
/// If 'auto' is selected, this picks the first from the pool as the primary.
final resolvedModelIdProvider = Provider<String>((ref) {
  final id = ref.watch(selectedModelIdProvider);
  if (id == kAutoModelId) return kDeepSeekFreeModels.first.id;
  return id;
});
