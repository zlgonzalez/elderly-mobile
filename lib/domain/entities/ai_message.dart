enum MessageSender {
  user,
  assistant,
  system,
}

class AiMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final String? contextScreen;

  const AiMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.contextScreen,
  });

  AiMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    String? contextScreen,
  }) {
    return AiMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      contextScreen: contextScreen ?? this.contextScreen,
    );
  }
}
