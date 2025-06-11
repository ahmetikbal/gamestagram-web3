import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/interaction_model.dart';
import '../../utils/logger.dart';

/// Service for managing social interactions like likes, saves, and comments
/// Uses Firebase Firestore for persistence with local caching
class SocialService {
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

          AppLogger.debug('Game $gameId unliked by user $userId', 'SocialService');
          return false;
        } else {
          // Like: Add gameId to user's likedGames and increment game's likeCount
          transaction.update(userRef, {
            'likedGames': FieldValue.arrayUnion([gameId]),
            'likeCount': FieldValue.increment(1),
          });

          transaction.update(gameRef, {'likeCount': FieldValue.increment(1)});

          AppLogger.debug('Game $gameId liked by user $userId', 'SocialService');
          return true;
        }
      });
    } catch (e) {
      AppLogger.error('[SocialService] Error toggling game like: $e', 'SocialService');
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
      AppLogger.error('[SocialService] Error checking if game is liked: $e', 'SocialService');
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

        AppLogger.debug('Game $gameId unsaved by user $userId', 'SocialService');
        return false;
      } else {
        // Save: Add gameId to user's savedGames
        await userRef.update({
          'savedGames': FieldValue.arrayUnion([gameId]),
        });

        AppLogger.debug('Game $gameId saved by user $userId', 'SocialService');
        return true;
      }
    } catch (e) {
      AppLogger.error('[SocialService] Error toggling game save: $e', 'SocialService');
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
      AppLogger.error('[SocialService] Error checking if game is saved: $e', 'SocialService');
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
      AppLogger.error('[SocialService] Error getting saved games: $e', 'SocialService');
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
      final timestamp = DateTime.now();
      final commentRef = await commentsRef.add({
        'userId': userId,
        'username': username,
        'text': text,
        'content': text,
        'timestamp': timestamp.toIso8601String(),
        'type': 'comment',
      });

      // Update user's comment count
      await _usersCollection.doc(userId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Update game's comment count
      await gameRef.update({'commentCount': FieldValue.increment(1)});

      // Create and return InteractionModel
      return InteractionModel(
        id: commentRef.id,
        userId: userId,
        username: username,
        text: text,
        content: text,
        timestamp: timestamp,
        type: InteractionType.comment,
      );
    } catch (e) {
      AppLogger.error('[SocialService] Error adding comment: $e', 'SocialService');
      return null;
    }
  }

  // Get comments for a game
  Future<List<InteractionModel>> getComments(String gameId, {int limit = 20}) async {
    try {
      final gameRef = _gamesCollection.doc(gameId);
      final commentsRef = gameRef.collection('comments');

      final querySnapshot = await commentsRef
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return InteractionModel(
              id: doc.id,
              userId: data['userId'] ?? '',
              username: data['username'] ?? '',
              text: data['text'],
              content: data['content'],
              timestamp: data['timestamp'] is String 
                  ? DateTime.parse(data['timestamp'])
                  : (data['timestamp'] as Timestamp).toDate(),
              type: InteractionType.comment,
            );
          })
          .toList();
    } catch (e) {
      AppLogger.error('[SocialService] Error getting comments: $e', 'SocialService');
      return [];
    }
  }

  // Get like count for a game
  Future<int> getLikeCount(String gameId) async {
    try {
      final gameDoc = await _gamesCollection.doc(gameId).get();
      final gameData = gameDoc.data() as Map<String, dynamic>?;
      return gameData?['likeCount'] ?? 0;
    } catch (e) {
      AppLogger.error('[SocialService] Error getting like count: $e', 'SocialService');
      return 0;
    }
  }

  // Get comment count for a game
  Future<int> getCommentCount(String gameId) async {
    try {
      final gameDoc = await _gamesCollection.doc(gameId).get();
      final gameData = gameDoc.data() as Map<String, dynamic>?;
      return gameData?['commentCount'] ?? 0;
    } catch (e) {
      AppLogger.error('[SocialService] Error getting comment count: $e', 'SocialService');
      return 0;
    }
  }

  // Fast comment count (for instant UI feedback) 
  int getCommentCountFast(String gameId) {
    // For now, return 0 - in a real implementation this would use cached data
    return 0;
  }

  // Get cached comments (for instant UI feedback)
  List<InteractionModel> getCachedComments(String gameId) {
    // For now, return empty list - in a real implementation this would use cached data
    return [];
  }

  // Fast comment retrieval (for instant UI feedback)
  List<InteractionModel> getCommentsFast(String gameId) {
    // For now, return empty list - in a real implementation this would use cached data
    return [];
  }

  // Add comment with fast response (optimistic updates)
  Future<InteractionModel?> addCommentFast(String gameId, String userId, String text) async {
    // For now, just use the regular addComment method
    return await addComment(gameId, userId, text);
  }

  // Get user like count across all games
  Future<int> getUserLikeCount(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['likeCount'] ?? 0;
    } catch (e) {
      AppLogger.error('[SocialService] Error getting user like count: $e', 'SocialService');
      return 0;
    }
  }

  // Get user comment count across all games
  Future<int> getUserCommentCount(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['commentCount'] ?? 0;
    } catch (e) {
      AppLogger.error('[SocialService] Error getting user comment count: $e', 'SocialService');
      return 0;
    }
  }

  // Synchronous versions for immediate UI updates (using cached data)
  int getUserLikeCountSync(String userId) {
    // For now, return 0 - would use cached data in real implementation
    return 0;
  }

  int getUserCommentCountSync(String userId) {
    // For now, return 0 - would use cached data in real implementation  
    return 0;
  }

  // Preload comments for better performance
  Future<void> preloadComments(List<String> gameIds) async {
    // For now, do nothing - would implement background comment loading
    AppLogger.debug('Preloading comments for ${gameIds.length} games', 'SocialService');
  }
}
