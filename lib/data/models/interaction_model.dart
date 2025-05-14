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
}
