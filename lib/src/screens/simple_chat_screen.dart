import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_providers.dart';
import '../services/ai_backend.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// Removed offline fallback: we surface friendly errors instead of dummy data
import '../providers/simple_chat_local_provider.dart';

class SimpleChatScreen extends ConsumerStatefulWidget {
  const SimpleChatScreen({super.key});

  @override
  ConsumerState<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends ConsumerState<SimpleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);
    _messageController.clear();
    _scrollToBottom();

    setState(() => _isLoading = true);

    try {
      // Get AI response via unified backend
      final backend = ref.read(aiBackendProvider);
      final history =
          ref
              .read(chatMessagesProvider)
              .map(
                (m) => AIMessage(
                  role: m.role,
                  content: m.content,
                  timestamp: m.timestamp,
                ),
              )
              .toList();
      final response = await backend.chat(message, history: history);
      final aiMessage = ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(aiMessage);
      _scrollToBottom();
    } catch (e) {
      // On quota/rate-limit errors, provide local fallback instead of raw error
      final msg = e.toString();
      final isQuota =
          msg.contains('quota') ||
          msg.contains('429') ||
          msg.contains('Too Many Requests') ||
          msg.contains('rate limit') ||
          msg.contains('billing') ||
          msg.contains('250');
      final content =
          isQuota
              ? 'Daily AI quota limit reached. Please try again later. (Resets at midnight UTC)'
              : 'Sorry, I encountered an error: ${e.toString()}';

      final errorMessage = ChatMessage(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
      _scrollToBottom();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearMessages();
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child:
                messages.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ask me about your studies, homework, or anything else!',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUser = message.role == 'user';

                        return Align(
                          alignment:
                              isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isUser)
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                    ),
                                  )
                                else
                                  MarkdownBody(
                                    data: message.content,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        fontSize: 15,
                                      ),
                                      strong: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (isUser
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant)
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('AI is thinking...'),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color:
                        _isLoading
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
