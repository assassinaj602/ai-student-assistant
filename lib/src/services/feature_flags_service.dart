import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple feature flags (extend as needed). Stored optionally at: users/{uid}/config/flags
class FeatureFlags {
  final bool enablePreviewModel;
  final bool enableExperimentalFlashcards;

  const FeatureFlags({
    this.enablePreviewModel = false,
    this.enableExperimentalFlashcards = false,
  });

  FeatureFlags copyWith({
    bool? enablePreviewModel,
    bool? enableExperimentalFlashcards,
  }) => FeatureFlags(
    enablePreviewModel: enablePreviewModel ?? this.enablePreviewModel,
    enableExperimentalFlashcards:
        enableExperimentalFlashcards ?? this.enableExperimentalFlashcards,
  );

  static FeatureFlags fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FeatureFlags();
    return FeatureFlags(
      enablePreviewModel: map['enablePreviewModel'] == true,
      enableExperimentalFlashcards: map['enableExperimentalFlashcards'] == true,
    );
  }
}

class FeatureFlagsService {
  Future<FeatureFlags> load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const FeatureFlags();
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('config')
              .doc('flags')
              .get();
      return FeatureFlags.fromMap(doc.data());
    } catch (_) {
      // Fail soft with defaults
      return const FeatureFlags();
    }
  }
}

final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  return FeatureFlagsService().load();
});
