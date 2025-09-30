/// A simple message model for chat functionality
class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Message copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}
