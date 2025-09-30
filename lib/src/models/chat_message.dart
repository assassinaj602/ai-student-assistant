/// Chat message model for AI conversations stored in Firebase
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? userId;
  final String? conversationId;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.userId,
    this.conversationId,
  });

  /// Create ChatMessage from Firestore document data
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      text: map['text'] as String,
      isUser: map['isUser'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      userId: map['userId'] as String?,
      conversationId: map['conversationId'] as String?,
    );
  }

  /// Convert ChatMessage to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
      'conversationId': conversationId,
    };
  }

  /// Create a copy of ChatMessage with updated fields
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? userId,
    String? conversationId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// Chat conversation model for organizing messages
class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final int messageCount;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.messageCount = 0,
  });

  /// Create ChatConversation from Firestore document data
  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      userId: map['userId'] as String,
      messageCount: map['messageCount'] as int? ?? 0,
    );
  }

  /// Convert ChatConversation to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'userId': userId,
      'messageCount': messageCount,
    };
  }

  /// Create a copy of ChatConversation with updated fields
  ChatConversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? messageCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
