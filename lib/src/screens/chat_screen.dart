import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';
import '../providers/chat_attendance_providers.dart';
import '../services/ai_providers.dart';
import '../services/ai_backend.dart';

/// Chat screen for AI-powered conversations using direct Gemini integration
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  AIBackend? _backend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    final chatActions = ref.read(chatActionsProvider);
    await chatActions.initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final chatActions = ref.read(chatActionsProvider);

      // Send user message to Firebase
      await chatActions.sendMessage(text, true);

      // Get AI response
      _backend ??= ref.read(aiBackendProvider);
      final response = await _backend!.chat(text);

      // Send AI response to Firebase
      await chatActions.sendMessage(response, false);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Send error message to Firebase
      try {
        final chatActions = ref.read(chatActionsProvider);
        await chatActions.sendMessage('Error: ${e.toString()}', false);
      } catch (_) {
        // If we can't save to Firebase, at least show the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final conversationId = ref.read(currentConversationIdProvider);
    if (conversationId == null) return;

    try {
      final chatActions = ref.read(chatActionsProvider);
      await chatActions.createNewConversation();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final messagesAsync = ref.watch(conversationMessagesProvider);
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: messagesAsync.maybeWhen(
                  data: (messages) => messages.isNotEmpty ? _clearChat : null,
                  orElse: () => null,
                ),
                tooltip: 'Clear Chat',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messagesAsync = ref.watch(conversationMessagesProvider);

                return messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Start a conversation with AI!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && _isLoading) {
                          return const _TypingIndicator();
                        }
                        final message = messages[index];
                        return _MessageBubble(message: message);
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading messages',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  () =>
                                      ref.refresh(conversationMessagesProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.onSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    message.text.startsWith('Error:')
                        ? theme.colorScheme.errorContainer
                        : isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft:
                      isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                  bottomRight:
                      isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Markdown for AI responses, plain text for user messages
                  if (isUser)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 15,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color:
                              message.text.startsWith('Error:')
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSurface,
                          fontSize: 15,
                        ),
                        strong: TextStyle(
                          color:
                              message.text.startsWith('Error:')
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        code: TextStyle(
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      selectable: true,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color:
                          message.text.startsWith('Error:')
                              ? theme.colorScheme.onErrorContainer.withOpacity(
                                0.7,
                              )
                              : isUser
                              ? theme.colorScheme.onPrimary.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Typing indicator widget
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                16,
              ).copyWith(bottomLeft: const Radius.circular(4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _TypingDot(delay: 0),
                const SizedBox(width: 4),
                const _TypingDot(delay: 200),
                const SizedBox(width: 4),
                const _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual typing dot with animation
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) => Opacity(
            opacity: _animation.value,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
    );
  }
}
