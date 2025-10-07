import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/flashcard_generation.dart';
import '../models/flashcard.dart' as models;

/// Review screen to re-attempt a FlashcardGeneration's cards by IDs
class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final FlashcardGeneration generation;
  const FlashcardReviewScreen({super.key, required this.generation});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen> {
  final PageController _pageController = PageController();
  List<models.Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final firebase = ref.read(firebaseServiceProvider);
      final cards = await firebase.getFlashcardsByIds(
        widget.generation.flashcardIds,
      );
      if (mounted) {
        setState(() {
          _cards = cards;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_currentIndex < _cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.generation.sourceTitle)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
              ? const Center(child: Text('No cards found for this generation'))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card ${_currentIndex + 1} of ${_cards.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed:
                              () => setState(() => _showAnswer = !_showAnswer),
                          icon: Icon(
                            _showAnswer
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          label: Text(
                            _showAnswer ? 'Hide Answer' : 'Show Answer',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged:
                          (i) => setState(() {
                            _currentIndex = i;
                            _showAnswer = false;
                          }),
                      itemCount: _cards.length,
                      itemBuilder:
                          (context, index) =>
                              _buildCard(context, _cards[index]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _prev,
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 32,
                        ),
                        IconButton(
                          onPressed: _next,
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCard(BuildContext context, models.Flashcard card) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.question,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState:
                    _showAnswer
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                firstChild: const SizedBox(),
                secondChild: Text(
                  card.answer,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
