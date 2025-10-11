import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preset free DeepSeek models available on OpenRouter.
class ModelOption {
  final String id; // e.g., 'deepseek/deepseek-chat-v3.1:free'
  final String label; // short label for UI
  const ModelOption(this.id, this.label);
}

// Pool of suggested free models to rotate between - prioritized by reliability
const List<ModelOption> kDeepSeekFreeModels = [
  ModelOption('deepseek/deepseek-chat-v3.1:free', 'DeepSeek Chat v3.1 (free)'),
  ModelOption('deepseek/deepseek-chat:free', 'DeepSeek Chat (free)'),
  ModelOption('deepseek/deepseek-r1:free', 'DeepSeek R1 (free, reasoning)'),
  ModelOption('deepseek/deepseek-r1-0528:free', 'DeepSeek R1 0528 (free)'),
  ModelOption(
    'deepseek/deepseek-r1-distill-llama-70b:free',
    'R1 Distill Llama 70B (free)',
  ),
  ModelOption('meta-llama/llama-3.2-3b-instruct:free', 'Llama 3.2 3B (free)'),
  ModelOption('qwen/qwen-2-7b-instruct:free', 'Qwen 2 7B (free)'),
  ModelOption('google/gemini-flash-1.5:free', 'Gemini Flash 1.5 (free)'),
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
    // Default to first option in pool (stable chat model) if no env override.
    return kDeepSeekFreeModels.first.id;
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
