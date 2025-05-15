import '../data/models/interaction_model.dart';
import '../data/models/user_model.dart'; // For userId

class SocialService {
  // Mock data stores
  final List<InteractionModel> _interactions = [];
  int _interactionIdCounter = 0;

  Future<bool> toggleLikeGame(String gameId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existingLikeIndex = _interactions.indexWhere((interaction) =>
        interaction.gameId == gameId &&
        interaction.userId == userId &&
        interaction.type == InteractionType.like);

    if (existingLikeIndex != -1) {
      _interactions.removeAt(existingLikeIndex);
      print('[SocialService] Game $gameId unliked by user $userId');
      return false; // Unliked
    } else {
      _interactions.add(InteractionModel(
        id: (_interactionIdCounter++).toString(),
        gameId: gameId,
        userId: userId,
        type: InteractionType.like,
        timestamp: DateTime.now(),
      ));
      print('[SocialService] Game $gameId liked by user $userId');
      return true; // Liked
    }
  }

  Future<InteractionModel?> addComment(String gameId, String userId, String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (text.isEmpty || text.length > 200) {
      print('[SocialService] Comment validation failed for game $gameId by user $userId');
      return null; // Or throw an error
    }
    final newComment = InteractionModel(
      id: (_interactionIdCounter++).toString(),
      gameId: gameId,
      userId: userId,
      type: InteractionType.comment,
      text: text,
      timestamp: DateTime.now(),
    );
    _interactions.add(newComment);
    print('[SocialService] Comment added to game $gameId by user $userId: "$text"');
    return newComment;
  }

  Future<List<InteractionModel>> getComments(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final gameComments = _interactions
        .where((i) => i.gameId == gameId && i.type == InteractionType.comment)
        .toList();
    // Sort by timestamp, newest first or oldest first as desired
    gameComments.sort((a, b) => b.timestamp.compareTo(a.timestamp)); 
    print('[SocialService] Fetched ${gameComments.length} comments for game $gameId');
    return gameComments;
  }

  int getLikeCount(String gameId) {
    // This is a simplified local count. In a real app, the backend would provide this.
    return _interactions.where((i) => i.gameId == gameId && i.type == InteractionType.like).length;
  }
}
 