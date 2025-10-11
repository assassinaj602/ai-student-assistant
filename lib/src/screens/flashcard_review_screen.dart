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
    final screenSize = MediaQuery.of(context).size;
    final isWebOrTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.generation.sourceTitle,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
              ? const Center(child: Text('No cards found for this generation'))
              : SafeArea(
                child: Column(
                  children: [
                    // Header section with card counter and show/hide button
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWebOrTablet ? 32 : 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Card ${_currentIndex + 1} of ${_cards.length}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                () =>
                                    setState(() => _showAnswer = !_showAnswer),
                            icon: Icon(
                              _showAnswer
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                            ),
                            label: Text(
                              _showAnswer ? 'Hide Answer' : 'Show Answer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWebOrTablet ? 24 : 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main card content area
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWebOrTablet ? 800 : double.infinity,
                        ),
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
                    ),

                    // Navigation controls
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWebOrTablet ? 32 : 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _currentIndex > 0 ? _prev : null,
                            icon: const Icon(Icons.chevron_left),
                            iconSize: 32,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _currentIndex > 0
                                      ? Colors.deepPurple.shade100
                                      : Colors.grey.shade200,
                              foregroundColor:
                                  _currentIndex > 0
                                      ? Colors.deepPurple
                                      : Colors.grey,
                            ),
                          ),
                          Text(
                            'Swipe or use arrows to navigate',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _currentIndex < _cards.length - 1
                                    ? _next
                                    : null,
                            icon: const Icon(Icons.chevron_right),
                            iconSize: 32,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _currentIndex < _cards.length - 1
                                      ? Colors.deepPurple.shade100
                                      : Colors.grey.shade200,
                              foregroundColor:
                                  _currentIndex < _cards.length - 1
                                      ? Colors.deepPurple
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCard(BuildContext context, models.Flashcard card) {
    final screenSize = MediaQuery.of(context).size;
    final isWebOrTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWebOrTablet ? 32 : 16,
        vertical: 8,
      ),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.deepPurple.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isWebOrTablet ? 32 : 24),
            child: Column(
              children: [
                // Question section - scrollable with flexible height
                Flexible(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: isWebOrTablet ? 120 : 80,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Colors.deepPurple.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Question',
                                style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SelectableText(
                              card.question,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: Colors.grey.shade800,
                                fontSize: isWebOrTablet ? 20 : 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.deepPurple.shade200,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Answer section - scrollable and expandable
                Flexible(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: isWebOrTablet ? 180 : 120,
                    ),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState:
                          _showAnswer
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      firstChild: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: isWebOrTablet ? 64 : 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap "Show Answer" to reveal the answer',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                  fontSize: isWebOrTablet ? 18 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      secondChild: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.green.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Answer',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: SelectableText(
                                    card.answer,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      fontSize: isWebOrTablet ? 17 : 16,
                                      color: Colors.grey.shade800,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
