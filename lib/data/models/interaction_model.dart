/// Types of user interactions with games
enum InteractionType { like, comment }

/// Represents a user interaction with a game (like or comment)
class InteractionModel {
  final String id;
  final String userId;
  final String username;
  final String? text; // For comments (backwards compatibility)
  final String? content; // New field for content
  final DateTime timestamp;
  final InteractionType type;

  InteractionModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.type,
    this.text,
    this.content,
    required this.timestamp,
  });

  /// Creates an InteractionModel instance from JSON data
  factory InteractionModel.fromJson(Map<String, dynamic> json) {
    return InteractionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      text: json['text'] as String?,
      content: json['content'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == 'InteractionType.${json['type']}',
        orElse: () => InteractionType.comment,
      ),
    );
  }

  /// Converts InteractionModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'text': text,
      'content': content ?? text, // Use content if available, fallback to text
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  /// Get the actual content text (either content or text field)
  String get actualContent => content ?? text ?? '';
}
