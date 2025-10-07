import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_backend.dart';
import 'feature_flags_service.dart';
import 'openrouter_ai_service.dart';
import 'model_selection.dart';

/// Chooses which AI backend to expose based on feature flags.
final aiBackendProvider = Provider<AIBackend>((ref) {
  // Observe flags (reserved for future model selection)
  ref.watch(featureFlagsProvider);

  // If Auto is selected, use rotation, else direct service.
  final selected = ref.watch(selectedModelIdProvider);
  if (selected == kAutoModelId) {
    return ref.watch(rotatingAIBackendProvider);
  }
  return ref.watch(openRouterAIServiceProvider);
});
