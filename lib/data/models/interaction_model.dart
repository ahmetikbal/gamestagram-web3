/// Types of user interactions with games
enum InteractionType { like, comment }

/// Represents a user interaction with a game (like or comment)
class InteractionModel {
  final String id;
  final String userId;
  final String username;
<<<<<<< HEAD
  final InteractionType type;
  final String? text; // For comments
=======
  final String content;
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
  final DateTime timestamp;
  final InteractionType type;

  InteractionModel({
    required this.id,
    required this.userId,
    required this.username,
<<<<<<< HEAD
    required this.type,
    this.text,
=======
    required this.content,
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
    required this.timestamp,
    required this.type,
  });
<<<<<<< HEAD

  // Factory constructor to create an InteractionModel from JSON
=======
  
  /// Creates an InteractionModel instance from JSON data
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
  factory InteractionModel.fromJson(Map<String, dynamic> json) {
    return InteractionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
<<<<<<< HEAD
=======
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
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
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }
}
