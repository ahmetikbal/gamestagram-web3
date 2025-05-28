import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/interaction_model.dart';
import '../data/models/user_model.dart';

/// Service for managing social interactions like likes, saves, and comments
/// Uses SharedPreferences for local data persistence in this demo app
class SocialService {
<<<<<<< HEAD
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('Users');
  CollectionReference get _gamesCollection => _firestore.collection('Games');

  // GAME INTERACTIONS (LIKES)
  Future<bool> toggleLikeGame(String gameId, String userId) async {
    try {
      // Get user document reference
      final userRef = _usersCollection.doc(userId);
      final gameRef = _gamesCollection.doc(gameId);

      // Check if user already liked the game
      final userDoc = await userRef.get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final likedGames = List<String>.from(userData?['likedGames'] ?? []);

      // Transaction to ensure atomic updates
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get current game data
        final gameDoc = await transaction.get(gameRef);
        final gameData = gameDoc.data() as Map<String, dynamic>?;

        if (gameData == null) {
          // Initialize game document if it doesn't exist
          transaction.set(gameRef, {
            'likeCount': 0,
            'commentCount': 0,
            'playCount': 0,
          });
        }

        final bool isLiked = likedGames.contains(gameId);

        if (isLiked) {
          // Unlike: Remove gameId from user's likedGames and decrement game's likeCount
          transaction.update(userRef, {
            'likedGames': FieldValue.arrayRemove([gameId]),
            'likeCount': FieldValue.increment(-1),
          });

          transaction.update(gameRef, {'likeCount': FieldValue.increment(-1)});

          print('[SocialService] Game $gameId unliked by user $userId');
          return false;
        } else {
          // Like: Add gameId to user's likedGames and increment game's likeCount
          transaction.update(userRef, {
            'likedGames': FieldValue.arrayUnion([gameId]),
            'likeCount': FieldValue.increment(1),
          });

          transaction.update(gameRef, {'likeCount': FieldValue.increment(1)});

          print('[SocialService] Game $gameId liked by user $userId');
          return true;
        }
      });
    } catch (e) {
      print('[SocialService] Error toggling game like: $e');
      return false;
    }
  }

  Future<bool> isGameLikedByUser(String gameId, String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return false;

      final likedGames = List<String>.from(userData['likedGames'] ?? []);
      return likedGames.contains(gameId);
    } catch (e) {
      print('[SocialService] Error checking if game is liked: $e');
      return false;
    }
  }

  // SAVED GAMES
  Future<bool> toggleSaveGame(String gameId, String userId) async {
    try {
      // Get user document reference
      final userRef = _usersCollection.doc(userId);

      // Check if user already saved the game
      final userDoc = await userRef.get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final savedGames = List<String>.from(userData?['savedGames'] ?? []);

      final bool isSaved = savedGames.contains(gameId);

      if (isSaved) {
        // Unsave: Remove gameId from user's savedGames
        await userRef.update({
          'savedGames': FieldValue.arrayRemove([gameId]),
        });

        print('[SocialService] Game $gameId unsaved by user $userId');
        return false;
      } else {
        // Save: Add gameId to user's savedGames
        await userRef.update({
          'savedGames': FieldValue.arrayUnion([gameId]),
        });

        print('[SocialService] Game $gameId saved by user $userId');
        return true;
      }
    } catch (e) {
      print('[SocialService] Error toggling game save: $e');
      return false;
    }
  }

  Future<bool> isGameSavedByUser(String gameId, String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return false;

      final savedGames = List<String>.from(userData['savedGames'] ?? []);
      return savedGames.contains(gameId);
    } catch (e) {
      print('[SocialService] Error checking if game is saved: $e');
      return false;
    }
  }

  Future<List<String>> getSavedGameIds(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return [];

      return List<String>.from(userData['savedGames'] ?? []);
    } catch (e) {
      print('[SocialService] Error getting saved games: $e');
      return [];
    }
  }

  // COMMENTS
  Future<InteractionModel?> addComment(
    String gameId,
    String userId,
    String text,
  ) async {
    try {
      if (text.isEmpty || text.length > 200) {
        print(
          '[SocialService] Comment validation failed for game $gameId by user $userId',
        );
        return null;
      }

      // Get user data to include username
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      final username = userData['username'] as String;

      // Get references
      final gameRef = _gamesCollection.doc(gameId);
      final commentsRef = gameRef.collection('comments');

      // Create new comment document
      final timestamp = FieldValue.serverTimestamp();
      final commentRef = await commentsRef.add({
        'userId': userId,
        'username': username,
        'text': text,
        'timestamp': timestamp,
      });

      // Update user's comment count
      await _usersCollection.doc(userId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Update game's comment count
      await gameRef.update({'commentCount': FieldValue.increment(1)});

      // Get the created comment to return
      final commentDoc = await commentRef.get();
      final commentData = commentDoc.data() as Map<String, dynamic>;

      // Create and return InteractionModel
      return InteractionModel(
        id: commentRef.id,
        gameId: gameId,
        userId: userId,
        username: username,
        text: text,
        type: InteractionType.comment,
        timestamp:
            (commentData['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
    } catch (e) {
      print('[SocialService] Error adding comment: $e');
      return null;
    }
  }

  Future<List<InteractionModel>> getCommentsForGame(String gameId) async {
    try {
      final commentsSnapshot =
          await _gamesCollection
              .doc(gameId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      return commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return InteractionModel(
          id: doc.id,
          gameId: gameId,
          userId: data['userId'],
          username: data['username'],
          text: data['text'],
          type: InteractionType.comment,
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('[SocialService] Error getting comments for game: $e');
      return [];
    }
  }

  // GAME STATISTICS
  Future<void> incrementGamePlayCount(String gameId) async {
    try {
      await _gamesCollection.doc(gameId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('[SocialService] Error incrementing game play count: $e');
    }
  }

  Future<Map<String, dynamic>> getGameStats(String gameId) async {
    try {
      final gameDoc = await _gamesCollection.doc(gameId).get();
      final gameData = gameDoc.data() as Map<String, dynamic>?;

      if (gameData == null) {
        return {'likeCount': 0, 'commentCount': 0, 'playCount': 0};
      }

      return {
        'likeCount': gameData['likeCount'] ?? 0,
        'commentCount': gameData['commentCount'] ?? 0,
        'playCount': gameData['playCount'] ?? 0,
      };
    } catch (e) {
      print('[SocialService] Error getting game stats: $e');
      return {'likeCount': 0, 'commentCount': 0, 'playCount': 0};
    }
  }

  // USER STATISTICS
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        return {'likeCount': 0, 'commentCount': 0, 'savedGamesCount': 0};
      }

      final savedGames = List<String>.from(userData['savedGames'] ?? []);

      return {
        'likeCount': userData['likeCount'] ?? 0,
        'commentCount': userData['commentCount'] ?? 0,
        'savedGamesCount': savedGames.length,
      };
    } catch (e) {
      print('[SocialService] Error getting user stats: $e');
      return {'likeCount': 0, 'commentCount': 0, 'savedGamesCount': 0};
    }
  }

  // Get like count for a game
  Future<int> getLikeCount(String gameId) async {
    try {
      final gameDoc = await _gamesCollection.doc(gameId).get();
      final gameData = gameDoc.data() as Map<String, dynamic>?;
      if (gameData == null) return 0;

      return gameData['likeCount'] ?? 0;
    } catch (e) {
      print('[SocialService] Error getting like count for game $gameId: $e');
      return 0;
    }
  }

  // Get comments for a game (alias for getCommentsForGame to maintain compatibility)
  Future<List<InteractionModel>> getComments(String gameId) async {
    return getCommentsForGame(gameId);
  }

  // Get number of likes made by a user
  Future<int> getUserLikeCount(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return 0;

      return userData['likeCount'] ?? 0;
    } catch (e) {
      print('[SocialService] Error getting like count for user $userId: $e');
      return 0;
    }
  }

  // Get number of comments made by a user
  Future<int> getUserCommentCount(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return 0;

      return userData['commentCount'] ?? 0;
    } catch (e) {
      print('[SocialService] Error getting comment count for user $userId: $e');
      return 0;
    }
=======
  static const String _likesKey = 'game_likes';
  static const String _commentsKey = 'game_comments';
  static const String _savedGamesKey = 'saved_games';

  Map<String, Set<String>> _gameLikes = {};
  Map<String, List<InteractionModel>> _gameComments = {};
  Map<String, Set<String>> _userSavedGames = {};

  SocialService() {
    _loadDataFromPrefs();
  }

  /// Loads social interaction data from SharedPreferences
  Future<void> _loadDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load likes data
      final String? likesJsonString = prefs.getString(_likesKey);
      if (likesJsonString != null) {
        final Map<String, dynamic> likesData = jsonDecode(likesJsonString);
        _gameLikes = likesData.map((gameId, userIds) => 
          MapEntry(gameId, Set<String>.from(userIds as List)));
      }

      // Load comments data
      final String? commentsJsonString = prefs.getString(_commentsKey);
      if (commentsJsonString != null) {
        final Map<String, dynamic> commentsData = jsonDecode(commentsJsonString);
        _gameComments = commentsData.map((gameId, comments) => 
          MapEntry(gameId, (comments as List).map((c) => 
            InteractionModel.fromJson(c as Map<String, dynamic>)).toList()));
      }

      // Load saved games data
      final String? savedGamesJsonString = prefs.getString(_savedGamesKey);
      if (savedGamesJsonString != null) {
        final Map<String, dynamic> savedGamesData = jsonDecode(savedGamesJsonString);
        _userSavedGames = savedGamesData.map((userId, gameIds) => 
          MapEntry(userId, Set<String>.from(gameIds as List)));
      }
    } catch (e) {
      print('[SocialService] Error loading data from SharedPreferences: $e');
      _gameLikes = {};
      _gameComments = {};
      _userSavedGames = {};
    }
  }

  /// Persists social interaction data to SharedPreferences
  Future<void> _saveDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save likes data
      final likesData = _gameLikes.map((gameId, userIds) => 
        MapEntry(gameId, userIds.toList()));
      await prefs.setString(_likesKey, jsonEncode(likesData));
      
      // Save comments data
      final commentsData = _gameComments.map((gameId, comments) => 
        MapEntry(gameId, comments.map((c) => c.toJson()).toList()));
      await prefs.setString(_commentsKey, jsonEncode(commentsData));
      
      // Save saved games data
      final savedGamesData = _userSavedGames.map((userId, gameIds) => 
        MapEntry(userId, gameIds.toList()));
      await prefs.setString(_savedGamesKey, jsonEncode(savedGamesData));
    } catch (e) {
      print('[SocialService] Error saving data to SharedPreferences: $e');
    }
  }

  /// Toggles like status for a game by a user
  /// Returns the new like status (true if liked, false if unliked)
  Future<bool> toggleLikeGame(String gameId, String userId) async {
    _gameLikes.putIfAbsent(gameId, () => <String>{});
    
    bool isCurrentlyLiked = _gameLikes[gameId]!.contains(userId);
    
    if (isCurrentlyLiked) {
      _gameLikes[gameId]!.remove(userId);
      await _saveDataToPrefs();
      return false;
    } else {
      _gameLikes[gameId]!.add(userId);
      await _saveDataToPrefs();
      return true;
    }
  }

  /// Toggles save status for a game by a user
  /// Returns the new save status (true if saved, false if unsaved)
  Future<bool> toggleSaveGame(String gameId, String userId) async {
    _userSavedGames.putIfAbsent(userId, () => <String>{});
    
    bool isCurrentlySaved = _userSavedGames[userId]!.contains(gameId);
    
    if (isCurrentlySaved) {
      _userSavedGames[userId]!.remove(gameId);
      await _saveDataToPrefs();
      return false;
    } else {
      _userSavedGames[userId]!.add(gameId);
      await _saveDataToPrefs();
      return true;
    }
  }

  /// Adds a comment to a game
  /// Returns the created comment or null if user not found
  Future<InteractionModel?> addComment(String gameId, String userId, String content) async {
    // In a real app, you'd fetch user details from a user service
    UserModel? user = _getMockUser(userId);
    if (user == null) {
      return null;
    }

    final comment = InteractionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      username: user.username,
      content: content,
      timestamp: DateTime.now(),
      type: InteractionType.comment,
    );

    _gameComments.putIfAbsent(gameId, () => []);
    _gameComments[gameId]!.add(comment);
    
    await _saveDataToPrefs();
    return comment;
  }

  /// Retrieves all comments for a specific game
  /// Returns comments sorted by timestamp (newest first)
  Future<List<InteractionModel>> getComments(String gameId) async {
    final comments = _gameComments[gameId] ?? [];
    comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return comments;
  }

  /// Gets the total number of likes for a game
  int getLikeCount(String gameId) {
    return _gameLikes[gameId]?.length ?? 0;
  }

  /// Gets the total number of likes made by a user across all games
  int getUserLikeCount(String userId) {
    return _gameLikes.values.where((likes) => likes.contains(userId)).length;
  }

  /// Gets the total number of comments made by a user across all games
  int getUserCommentCount(String userId) {
    return _gameComments.values
        .expand((comments) => comments)
        .where((comment) => comment.userId == userId)
        .length;
  }

  /// Gets the set of game IDs saved by a specific user
  Set<String> getSavedGameIds(String userId) {
    return _userSavedGames[userId] ?? <String>{};
  }

  /// Checks if a game is liked by a specific user
  bool isGameLikedByUser(String gameId, String userId) {
    return _gameLikes[gameId]?.contains(userId) ?? false;
  }

  /// Checks if a game is saved by a specific user
  bool isGameSavedByUser(String gameId, String userId) {
    return _userSavedGames[userId]?.contains(gameId) ?? false;
  }

  /// Mock user lookup - in a real app, this would query a user service
  UserModel? _getMockUser(String userId) {
    // This is a simplified mock implementation
    return UserModel(id: userId, username: 'User$userId', email: 'user$userId@example.com');
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
  }
}
