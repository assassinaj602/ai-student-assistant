import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/flashcard_generation.dart';
import '../models/flashcard.dart';

/// Selected flashcard generation ID
final currentGenerationIdProvider = StateProvider<String?>((ref) => null);

/// Stream of user's flashcard generations (most recent first)
final userGenerationsProvider = StreamProvider<List<FlashcardGeneration>>((
  ref,
) {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getFlashcardGenerationHistoryStream();
});

/// Currently selected generation object (derived from stream + selection)
final selectedGenerationProvider = Provider<FlashcardGeneration?>((ref) {
  final gens = ref
      .watch(userGenerationsProvider)
      .maybeWhen(data: (d) => d, orElse: () => <FlashcardGeneration>[]);
  final id = ref.watch(currentGenerationIdProvider);
  if (id == null) return null;
  if (gens.isEmpty) return null;
  final found = gens.where((g) => g.id == id);
  return found.isNotEmpty ? found.first : gens.first;
});

/// Flashcards of the selected generation
final selectedGenerationCardsProvider = FutureProvider<List<Flashcard>>((
  ref,
) async {
  final gen = ref.watch(selectedGenerationProvider);
  if (gen == null) return [];
  final firebase = ref.read(firebaseServiceProvider);
  return firebase.getFlashcardsByIds(gen.flashcardIds);
});
