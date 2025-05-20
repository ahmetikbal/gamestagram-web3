enum InteractionType { like, comment }

class InteractionModel {
  final String id; // Unique ID for the interaction
  final String gameId;
  final String userId;
  final InteractionType type;
  final String? text; // For comments
  final DateTime timestamp;

  InteractionModel({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.type,
    this.text,
    required this.timestamp,
  });
  
  // Factory constructor to create an InteractionModel from JSON
  factory InteractionModel.fromJson(Map<String, dynamic> json) {
    return InteractionModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      userId: json['userId'] as String,
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == 'InteractionType.${json['type']}',
        orElse: () => InteractionType.like,
      ),
      text: json['text'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Method to convert InteractionModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
