import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

/// Service for managing AI chat messages with Firebase
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Collection references
  CollectionReference get _conversationsCollection =>
      _firestore.collection('chat_conversations');

  CollectionReference _messagesCollection(String conversationId) => _firestore
      .collection('chat_conversations')
      .doc(conversationId)
      .collection('messages');

  /// Create a new conversation
  Future<String> createConversation({String? title}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final conversation = ChatConversation(
      id: '',
      title: title ?? 'AI Chat ${DateTime.now().toString().substring(0, 16)}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      messageCount: 0,
    );

    final docRef = await _conversationsCollection.add(conversation.toMap());
    return docRef.id;
  }

  /// Get user's conversations
  Stream<List<ChatConversation>> getUserConversations() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _conversationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ChatConversation.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get messages from a conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _messagesCollection(conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ChatMessage.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  /// Add a message to a conversation
  Future<void> addMessage({
    required String conversationId,
    required String text,
    required bool isUser,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final message = ChatMessage(
      id: '',
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      userId: userId,
      conversationId: conversationId,
    );

    // Add message
    await _messagesCollection(conversationId).add(message.toMap());

    // Update conversation's last updated time and message count
    await _conversationsCollection.doc(conversationId).update({
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'messageCount': FieldValue.increment(1),
    });
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages first
    final messagesSnapshot = await _messagesCollection(conversationId).get();
    final batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the conversation
    batch.delete(_conversationsCollection.doc(conversationId));

    await batch.commit();
  }

  /// Get or create default conversation for user
  Future<String> getOrCreateDefaultConversation() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Try to get existing conversation
    final existingConversations =
        await _conversationsCollection
            .where('userId', isEqualTo: userId)
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .get();

    if (existingConversations.docs.isNotEmpty) {
      return existingConversations.docs.first.id;
    }

    // Create new conversation if none exists
    return await createConversation(title: 'AI Assistant Chat');
  }

  /// Clear all conversations for current user (useful for testing)
  Future<void> clearAllConversations() async {
    final userId = currentUserId;
    if (userId == null) return;

    final conversations =
        await _conversationsCollection.where('userId', isEqualTo: userId).get();

    for (var doc in conversations.docs) {
      await deleteConversation(doc.id);
    }
  }
}
