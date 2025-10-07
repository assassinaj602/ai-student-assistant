import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_providers.dart';
import '../models/flashcard.dart' as models;
import '../services/firebase_service.dart';
import '../providers/flashcards_providers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'flashcard_history_screen.dart';

/// Flashcards screen for AI-generated study cards
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  late PageController _pageController;
  final List<models.Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _lastGenerationId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

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
      final flashcards = await backend.generateFlashcards(text, count: 10);

      // Persist generated flashcards with history tracking
      final firebase = ref.read(firebaseServiceProvider);
      final generationId = await firebase.saveFlashcardsWithHistory(
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
        // Select the newly created generation in the sidebar
        ref.read(currentGenerationIdProvider.notifier).state = generationId;
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
        final msg = e.toString();
        final isQuota =
            msg.contains('quota') ||
            msg.contains('429') ||
            msg.contains('Too Many Requests') ||
            msg.contains('rate limit') ||
            msg.contains('billing') ||
            msg.contains('250');
        final friendly =
            isQuota
                ? 'Daily AI quota limit reached. Please try again later.'
                : 'Error generating flashcards: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendly),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Navigate to next card
  void _nextCard() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navigate to previous card
  void _previousCard() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    // If the selected generation changed, reset to the first card
    final currentGenId = ref.watch(currentGenerationIdProvider);
    if (currentGenId != _lastGenerationId) {
      _lastGenerationId = currentGenId;
      final oldController = _pageController;
      _pageController = PageController(initialPage: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        oldController.dispose();
        setState(() {
          _currentIndex = 0;
          _showAnswer = false;
        });
      });
    }
    final isWide = MediaQuery.of(context).size.width >= 840;
    final sidebar = _FlashcardsSidebar(
      onNewGeneration: _generateFlashcards,
      onSelect: (id) {
        ref.read(currentGenerationIdProvider.notifier).state = id;
        if (!isWide) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      },
      onDelete: (id) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete generation'),
                content: const Text('This will remove this generation record.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        );
        if (confirmed == true) {
          await ref.read(firebaseServiceProvider).deleteFlashcardGeneration(id);
          if (ref.read(currentGenerationIdProvider) == id) {
            ref.read(currentGenerationIdProvider.notifier).state = null;
          }
        }
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Flashcards'),
        leading:
            isWide
                ? null
                : IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New generation',
            onPressed: _generateFlashcards,
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 320,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: SafeArea(child: sidebar),
              ),
            ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(selectedGenerationCardsProvider);
                return selected.when(
                  data: (cards) {
                    // If a generation is selected, play its cards; otherwise show current session state
                    final usingSelected =
                        ref.read(currentGenerationIdProvider) != null;
                    final list = usingSelected ? cards : _flashcards;
                    if (_isLoading)
                      return const Center(child: CircularProgressIndicator());
                    if (list.isEmpty) return _buildEmptyState();
                    return _buildFlashcardViewWith(list);
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                );
              },
            ),
          ),
        ],
      ),
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

  Widget _buildFlashcardViewWith(List<models.Flashcard> source) {
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
                    'Card ${_currentIndex + 1} of ${source.length}',
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
                value: source.isEmpty ? 0 : (_currentIndex + 1) / source.length,
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
            key: ValueKey('${_lastGenerationId ?? 'session'}:${source.length}'),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showAnswer = false;
              });
            },
            itemCount: source.length,
            itemBuilder: (context, index) => _buildFlashcard(source[index]),
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
                onPressed: _currentIndex < source.length - 1 ? _nextCard : null,
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
        elevation: 6,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: _toggleAnswer,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(28),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 300),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _showAnswer
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAnswer
                            ? Icons.lightbulb_outlined
                            : Icons.quiz_outlined,
                        size: 20,
                        color:
                            _showAnswer
                                ? Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showAnswer ? 'Answer' : 'Question',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              _showAnswer
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState:
                          _showAnswer
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      firstChild: Container(
                        width: double.infinity,
                        child: MarkdownBody(
                          data: flashcard.question,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            h1: Theme.of(context).textTheme.headlineSmall,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            code: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      secondChild: Container(
                        width: double.infinity,
                        child: MarkdownBody(
                          data: flashcard.answer,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            h1: Theme.of(context).textTheme.headlineSmall,
                            h2: Theme.of(context).textTheme.titleLarge,
                            h3: Theme.of(context).textTheme.titleMedium,
                            code: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tap to ${_showAnswer ? 'hide' : 'reveal'} answer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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

/// Sidebar for Flashcards: recent generations list with actions
class _FlashcardsSidebar extends ConsumerWidget {
  final VoidCallback onNewGeneration;
  final void Function(String id) onSelect;
  final Future<void> Function(String id) onDelete;

  const _FlashcardsSidebar({
    required this.onNewGeneration,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gensAsync = ref.watch(userGenerationsProvider);
    final currentId = ref.watch(currentGenerationIdProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNewGeneration,
                  icon: const Icon(Icons.add),
                  label: const Text('New generation'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: gensAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No generations yet'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final g = items[index];
                  final selected = g.id == currentId;
                  return ListTile(
                    selected: selected,
                    leading: CircleAvatar(
                      child: Text(g.flashcardCount.toString()),
                    ),
                    title: Text(
                      g.sourceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${g.flashcardCount} cards',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => onSelect(g.id),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await onDelete(g.id);
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
