import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_backend.dart';
import 'feature_flags_service.dart';
import 'openrouter_ai_service.dart';

/// Chooses which AI backend to expose based on feature flags.
/// ALWAYS uses rotating fallback for maximum reliability!
final aiBackendProvider = Provider<AIBackend>((ref) {
  // Observe flags (reserved for future model selection)
  ref.watch(featureFlagsProvider);

  // ALWAYS use rotation to ensure automatic fallback when models fail
  // This prevents 502 errors from breaking the app
  return ref.watch(rotatingAIBackendProvider);
});
