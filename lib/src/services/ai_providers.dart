import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_backend.dart';
import 'gemini_ai_service.dart';
import 'feature_flags_service.dart';

/// Chooses which AI backend to expose based on feature flags.
final aiBackendProvider = Provider<AIBackend>((ref) {
  // Currently only Gemini. In future, inspect flags to swap.
  ref.watch(
    featureFlagsProvider,
  ); // Currently unused; placeholder for future backend switching.
  return ref.watch(geminiAIServiceProvider);
});
