import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import 'note_editor.dart';

/// Notes screen with Firestore integration
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get notes collection reference for current user
  CollectionReference get _notesCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes');
  }

  /// Create a new note
  Future<void> _createNote() async {
    final result = await Navigator.of(
      context,
    ).push<Note>(MaterialPageRoute(builder: (context) => const NoteEditor()));

    if (result != null) {
      try {
        await _notesCollection.add({
          'title': result.title,
          'body': result.body,
          'createdAt': Timestamp.fromDate(result.createdAt),
          'updatedAt': Timestamp.fromDate(result.updatedAt),
          'summary': result.summary,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating note: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Edit an existing note
  Future<void> _editNote(Note note) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (context) => NoteEditor(note: note)),
    );

    if (result != null) {
      try {
        await _notesCollection.doc(note.id).update({
          'title': result.title,
          'body': result.body,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'summary': result.summary,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating note: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Delete a note
  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: Text('Are you sure you want to delete "${note.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _notesCollection.doc(note.id).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _createNote,
            icon: const Icon(Icons.add),
            tooltip: 'Add Note',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // Notes list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _notesCollection
                      .orderBy('updatedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Filter notes based on search query
                final filteredDocs =
                    docs.where((doc) {
                      if (_searchQuery.isEmpty) return true;

                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          (data['title'] as String? ?? '').toLowerCase();
                      final body =
                          (data['body'] as String? ?? '').toLowerCase();

                      return title.contains(_searchQuery) ||
                          body.contains(_searchQuery);
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.note_add
                              : Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No notes found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tap the + button to create your first note'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final note = Note(
                      id: doc.id,
                      title: data['title'] as String? ?? '',
                      body: data['body'] as String? ?? '',
                      createdAt:
                          (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      updatedAt:
                          (data['updatedAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      summary: data['summary'] as String?,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.summary != null &&
                                note.summary!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 14,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI Summary',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 60,
                                      ),
                                      child: MarkdownBody(
                                        data: note.summary!,
                                        styleSheet: MarkdownStyleSheet(
                                          p: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                            height: 1.3,
                                          ),
                                          listBullet: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                            height: 1.3,
                                          ),
                                          strong: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.9),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          code: TextStyle(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant
                                                .withOpacity(0.3),
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                          blockSpacing: 4.0,
                                          listIndent: 16.0,
                                        ),
                                        shrinkWrap: true,
                                        selectable: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (note.body.isNotEmpty)
                              Text(
                                note.body,
                                maxLines: note.summary != null ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('Delete'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editNote(note);
                                break;
                              case 'delete':
                                _deleteNote(note);
                                break;
                            }
                          },
                        ),
                        onTap: () => _editNote(note),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
