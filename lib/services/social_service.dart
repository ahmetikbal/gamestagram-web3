import '../data/models/interaction_model.dart';
import '../data/models/user_model.dart'; // For userId
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SocialService {
  // Mock data stores
  final List<InteractionModel> _interactions = [];
  int _interactionIdCounter = 0;
  
  // Maps userId to a list of saved game IDs
  final Map<String, List<String>> _savedGames = {};
  static const String _savedGamesKey = 'saved_games';
  bool _prefsLoaded = false;

  SocialService() {
    _loadSavedGamesFromPrefs();
  }

  Future<void> _loadSavedGamesFromPrefs() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedGamesJson = prefs.getString(_savedGamesKey);
      if (savedGamesJson != null) {
        final Map<String, dynamic> savedGamesMap = jsonDecode(savedGamesJson);
        
        savedGamesMap.forEach((userId, gameIds) {
          _savedGames[userId] = List<String>.from(gameIds);
        });
      }
      _prefsLoaded = true;
      print('[SocialService] Loaded saved games from SharedPreferences: $_savedGames');
    } catch (e) {
      print('[SocialService] Error loading saved games: $e');
      // Initialize with empty if error
      _prefsLoaded = true;
    }
  }

  Future<void> _saveSavedGamesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String savedGamesJson = jsonEncode(_savedGames);
      await prefs.setString(_savedGamesKey, savedGamesJson);
      print('[SocialService] Saved games data saved to SharedPreferences');
    } catch (e) {
      print('[SocialService] Error saving games data: $e');
    }
  }

  Future<void> _ensurePrefsLoaded() async {
    if (!_prefsLoaded) {
      await _loadSavedGamesFromPrefs();
    }
  }

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

  Future<bool> toggleSaveGame(String gameId, String userId) async {
    await _ensurePrefsLoaded();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Initialize the user's saved games list if it doesn't exist
    _savedGames.putIfAbsent(userId, () => []);
    
    final userSavedGames = _savedGames[userId]!;
    final isSaved = userSavedGames.contains(gameId);
    
    if (isSaved) {
      // Unsave the game
      userSavedGames.remove(gameId);
      print('[SocialService] Game $gameId unsaved by user $userId');
      await _saveSavedGamesToPrefs();
      return false; // Unsaved
    } else {
      // Save the game
      userSavedGames.add(gameId);
      print('[SocialService] Game $gameId saved by user $userId');
      await _saveSavedGamesToPrefs();
      return true; // Saved
    }
  }

  bool isGameSavedByUser(String gameId, String userId) {
    return _savedGames[userId]?.contains(gameId) ?? false;
  }

  List<String> getSavedGameIds(String userId) {
    return _savedGames[userId] ?? [];
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

  // Get the number of likes made by a user
  int getUserLikeCount(String userId) {
    return _interactions.where((i) => 
      i.userId == userId && i.type == InteractionType.like
    ).length;
  }
  
  // Get the number of comments made by a user
  int getUserCommentCount(String userId) {
    return _interactions.where((i) => 
      i.userId == userId && i.type == InteractionType.comment
    ).length;
  }
}
 