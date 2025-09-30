import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_providers.dart';
import '../models/flashcard.dart' as models;
import '../services/firebase_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'flashcard_history_screen.dart';

/// Flashcards screen for AI-generated study cards
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final PageController _pageController = PageController();
  final List<models.Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Generate flashcards from text
  Future<void> _generateFlashcards() async {
    final textController = TextEditingController();
    final titleController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Generate Flashcards'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title/Topic',
                        hintText: 'e.g., Biology Chapter 5, Math Formulas...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText: 'Enter text to generate flashcards from...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop({
                      'title': titleController.text.trim(),
                      'text': textController.text.trim(),
                    }),
                child: const Text('Generate'),
              ),
            ],
          ),
    );

    if (result == null) return;
    final text = result['text'] ?? '';
    final title = result['title'] ?? '';

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to generate flashcards'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final backend = ref.read(aiBackendProvider);
      final flashcards = await backend.generateFlashcards(text);

      // Persist generated flashcards with history tracking
      final firebase = ref.read(firebaseServiceProvider);
      await firebase.saveFlashcardsWithHistory(
        flashcards:
            flashcards
                .map(
                  (c) => models.Flashcard(
                    id: '',
                    question: c.question,
                    answer: c.answer,
                    noteId: null,
                    createdAt: c.createdAt,
                    updatedAt: c.updatedAt,
                    difficulty: 3,
                    timesReviewed: 0,
                    lastReviewed: null,
                  ),
                )
                .toList(),
        sourceText: text,
        sourceTitle: title.isNotEmpty ? title : 'Generated Flashcards',
        generationMethod: 'text_input',
      );

      if (mounted) {
        setState(() {
          _flashcards.clear();
          _flashcards.addAll(flashcards);
          _currentIndex = 0;
          _showAnswer = false;
          _isLoading = false;
        });

        // Show success message with history saved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${flashcards.length} flashcards and saved to history!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating flashcards: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Navigate to next card
  void _nextCard() {
    if (_currentIndex < _flashcards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to previous card
  void _previousCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Toggle answer visibility
  void _toggleAnswer() {
    setState(() => _showAnswer = !_showAnswer);
  }

  /// Show flashcard generation history
  void _showGenerationHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FlashcardHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showGenerationHistory,
            tooltip: 'Generation History',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateFlashcards,
            tooltip: 'Generate Flashcards',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _flashcards.isEmpty
              ? _buildEmptyState()
              : _buildFlashcardView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No flashcards yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate flashcards from your notes or study material',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateFlashcards,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Flashcards'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showGenerationHistory,
            icon: const Icon(Icons.history),
            label: const Text('View History'),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: Provide factual paragraphs (definitions, lists, key concepts) for best results.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of ${_flashcards.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'shuffle':
                          _shuffleCards();
                          break;
                        case 'reset':
                          _resetProgress();
                          break;
                        case 'clear':
                          _clearCards();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'shuffle',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shuffle),
                                SizedBox(width: 8),
                                Flexible(child: Text('Shuffle')),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restart_alt),
                                SizedBox(width: 8),
                                Flexible(child: Text('Reset Progress')),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'clear',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Flexible(child: Text('Clear Cards')),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _flashcards.length,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.outline.withOpacity(0.2),
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showAnswer = false;
              });
            },
            itemCount: _flashcards.length,
            itemBuilder:
                (context, index) => _buildFlashcard(_flashcards[index]),
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentIndex > 0 ? _previousCard : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 32,
              ),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _toggleAnswer,
                  icon: Icon(
                    _showAnswer ? Icons.visibility_off : Icons.visibility,
                  ),
                  label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                ),
              ),
              IconButton(
                onPressed:
                    _currentIndex < _flashcards.length - 1 ? _nextCard : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 32,
              ),
            ],
          ),
        ),

        // History link
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextButton.icon(
            onPressed: _showGenerationHistory,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('View Generation History'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard(models.Flashcard flashcard) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: _toggleAnswer,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAnswer ? Icons.lightbulb : Icons.help_outline,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),

                Text(
                  _showAnswer ? 'Answer' : 'Question',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState:
                          _showAnswer
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      firstChild: MarkdownBody(
                        data: flashcard.question,
                        shrinkWrap: true,
                      ),
                      secondChild: MarkdownBody(
                        data: flashcard.answer,
                        shrinkWrap: true,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Tap to ${_showAnswer ? 'hide' : 'reveal'} answer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shuffleCards() {
    setState(() {
      _flashcards.shuffle();
      _currentIndex = 0;
      _showAnswer = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _resetProgress() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _clearCards() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Flashcards'),
            content: const Text(
              'Are you sure you want to clear all flashcards?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _flashcards.clear();
                    _currentIndex = 0;
                    _showAnswer = false;
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
