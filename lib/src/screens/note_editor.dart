import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../services/ai_providers.dart';

class NoteEditor extends ConsumerStatefulWidget {
  final Note? note;
  final String? courseId;
  const NoteEditor({super.key, this.note, this.courseId});
  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _isGeneratingSummary = false;
  bool _isSaving = false;
  String? _generatedSummary;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _generatedSummary = widget.note?.summary;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_isSaving) return; // debounce
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }
    _isSaving = true;

    final note = Note(
      id: widget.note?.id ?? '',
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      summary: _generatedSummary ?? widget.note?.summary,
      embedding: widget.note?.embedding,
      courseId: widget.courseId ?? widget.note?.courseId,
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(note);
    }
    _isSaving = false;
  }

  Future<void> _generateSummary() async {
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to summarize')),
      );
      return;
    }

    setState(() => _isGeneratingSummary = true);

    try {
      final backend = ref.read(aiBackendProvider);
      final summary = await backend.summarize(_bodyController.text);

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('AI Summary'),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: MarkdownBody(
                      data: summary,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        strong: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        code: TextStyle(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selectable: true,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _generatedSummary = summary);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Summary saved! It will be visible in notes list.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Save as Summary'),
                  ),
                  PopupMenuButton<String>(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Add to Note'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'plain',
                            child: Row(
                              children: [
                                Icon(Icons.text_fields, size: 18),
                                SizedBox(width: 8),
                                Text('As Plain Text'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'markdown',
                            child: Row(
                              children: [
                                Icon(Icons.code, size: 18),
                                SizedBox(width: 8),
                                Text('As Markdown'),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (String choice) {
                      Navigator.of(context).pop();
                      final currentText = _bodyController.text;
                      final String summaryToAdd;
                      final String prefix;

                      if (choice == 'plain') {
                        summaryToAdd = _markdownToPlainText(summary);
                        prefix = '--- AI Summary ---\n';
                      } else {
                        summaryToAdd = summary;
                        prefix = '**AI Summary:**\n';
                      }

                      if (currentText.isNotEmpty) {
                        _bodyController.text =
                            currentText + '\n\n' + prefix + summaryToAdd + '\n';
                      } else {
                        _bodyController.text = prefix + summaryToAdd + '\n';
                      }

                      // Switch to preview mode if markdown was added
                      if (choice == 'markdown') {
                        setState(() {
                          _isPreviewMode = true;
                        });
                      }
                    },
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating summary: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
      }
    }
  }

  /// Convert markdown text to clean plain text
  String _markdownToPlainText(String markdown) {
    String plainText = markdown;

    // Remove markdown formatting while preserving content structure
    plainText =
        plainText
            .replaceAll(
              RegExp(r'\*\*(.*?)\*\*'),
              r'$1',
            ) // Bold: **text** -> text
            .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic: *text* -> text
            .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Code: `text` -> text
            .replaceAll(
              RegExp(r'^- ', multiLine: true),
              '• ',
            ) // Bullets: - -> •
            .replaceAll(
              RegExp(r'^  - ', multiLine: true),
              '  • ',
            ) // Nested bullets
            .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up extra whitespace
            .trim();

    return plainText;
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    final hasChanges =
        (_titleController.text.trim().isNotEmpty ||
            _bodyController.text.trim().isNotEmpty);

    if (!hasChanges) {
      return true; // Allow pop if no changes
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Changes?'),
            content: const Text(
              'Do you want to save your changes before leaving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Don't save
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Save
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (shouldSave == true) {
      _saveNote();
    }

    return true; // Always allow pop after handling
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Content',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Edit'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.preview, size: 18),
                        label: Text('Preview'),
                      ),
                    ],
                    selected: {_isPreviewMode},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _isPreviewMode = selection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    _isPreviewMode
                        ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          child:
                              _bodyController.text.trim().isEmpty
                                  ? Text(
                                    'No content to preview',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    child: MarkdownBody(
                                      data: _bodyController.text,
                                      styleSheet: MarkdownStyleSheet(
                                        p: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                        strong: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        code: TextStyle(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surfaceVariant,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      selectable: true,
                                    ),
                                  ),
                        )
                        : TextField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                        ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingSummary ? null : _generateSummary,
                      icon:
                          _isGeneratingSummary
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                _generatedSummary != null
                                    ? Icons.auto_awesome
                                    : Icons.auto_awesome_outlined,
                              ),
                      label: Text(
                        _isGeneratingSummary
                            ? 'Generating...'
                            : _generatedSummary != null
                            ? 'Update Summary'
                            : 'AI Summary',
                      ),
                      style:
                          _generatedSummary != null
                              ? OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                  width: 1.5,
                                ),
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
