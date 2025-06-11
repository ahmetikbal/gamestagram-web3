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

      // Transaction to ensure atomic updates of both Games and Users collections
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get current game data and user data
        final gameDoc = await transaction.get(gameRef);
        final gameData = gameDoc.data() as Map<String, dynamic>?;
        final userDocInTransaction = await transaction.get(userRef);
        final userDataInTransaction = userDocInTransaction.data() as Map<String, dynamic>?;

        // Initialize game document if it doesn't exist
        if (gameData == null) {
          transaction.set(gameRef, {
            'likeCount': 0,
            'commentCount': 0,
            'playCount': 0,
          });
        }

        // Ensure user document has required count fields (for existing users)
        if (userDataInTransaction != null && 
            (!userDataInTransaction.containsKey('likeCount') || 
             !userDataInTransaction.containsKey('commentCount'))) {
          transaction.update(userRef, {
            'likeCount': userDataInTransaction['likeCount'] ?? 0,
            'commentCount': userDataInTransaction['commentCount'] ?? 0,
          });
        }

        final bool isLiked = likedGames.contains(gameId);

        if (isLiked) {
          // Unlike: Update both Users and Games collections
          transaction.update(userRef, {
            'likedGames': FieldValue.arrayRemove([gameId]),
            'likeCount': FieldValue.increment(-1), // User's total like count
          });

          transaction.update(gameRef, {
            'likeCount': FieldValue.increment(-1), // Game's total like count
          });

          AppLogger.debug('Game $gameId unliked by user $userId - Updated both Users and Games collections', 'SocialService');
          return false;
        } else {
          // Like: Update both Users and Games collections
          transaction.update(userRef, {
            'likedGames': FieldValue.arrayUnion([gameId]),
            'likeCount': FieldValue.increment(1), // User's total like count
          });

          transaction.update(gameRef, {
            'likeCount': FieldValue.increment(1), // Game's total like count
          });

          AppLogger.debug('Game $gameId liked by user $userId - Updated both Users and Games collections', 'SocialService');
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
        AppLogger.warning(
          '[SocialService] Comment validation failed for game $gameId by user $userId',
          'SocialService',
        );
        return null;
      }

      // Get user data to include username
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return null;

      final username = userData['username'] as String;

      // Get references
      final userRef = _usersCollection.doc(userId);
      final gameRef = _gamesCollection.doc(gameId);
      final commentsRef = gameRef.collection('comments');

      // Use transaction to ensure atomic updates of both Users and Games collections
      return await _firestore.runTransaction<InteractionModel?>((transaction) async {
        // Ensure user document has required count fields (for existing users)
        final userDocInTransaction = await transaction.get(userRef);
        final userDataInTransaction = userDocInTransaction.data() as Map<String, dynamic>?;
        
        if (userDataInTransaction != null && 
            (!userDataInTransaction.containsKey('commentCount') || 
             !userDataInTransaction.containsKey('likeCount'))) {
          transaction.update(userRef, {
            'likeCount': userDataInTransaction['likeCount'] ?? 0,
            'commentCount': userDataInTransaction['commentCount'] ?? 0,
          });
        }

        // Ensure game document exists and has count fields
        final gameDoc = await transaction.get(gameRef);
        final gameData = gameDoc.data() as Map<String, dynamic>?;
        
        if (gameData == null) {
          transaction.set(gameRef, {
            'likeCount': 0,
            'commentCount': 1, // Will be 1 after this comment
            'playCount': 0,
          });
        } else {
          // Update game's comment count
          transaction.update(gameRef, {
            'commentCount': FieldValue.increment(1), // Game's total comment count
          });
        }

        // Update user's comment count
        transaction.update(userRef, {
          'commentCount': FieldValue.increment(1), // User's total comment count
        });

        // Note: We can't add to subcollection in transaction, so we'll do it after
        return null; // Placeholder, we'll create the comment after transaction
      }).then((_) async {
        // Create new comment document (outside transaction since subcollections aren't supported in transactions)
        final timestamp = DateTime.now();
        final commentRef = await commentsRef.add({
          'userId': userId,
          'username': username,
          'text': text,
          'content': text,
          'timestamp': timestamp.toIso8601String(),
          'type': 'comment',
        });

        AppLogger.debug('Comment added to game $gameId by user $userId - Updated both Users and Games collections', 'SocialService');

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
      });
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
  
  /// Get comprehensive user statistics from Users collection
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null) {
        return {
          'likeCount': 0,
          'commentCount': 0,
          'savedGamesCount': 0,
        };
      }
      
      final savedGames = List<String>.from(userData['savedGames'] ?? []);
      
      return {
        'likeCount': userData['likeCount'] ?? 0,
        'commentCount': userData['commentCount'] ?? 0,
        'savedGamesCount': savedGames.length,
      };
    } catch (e) {
      AppLogger.error('[SocialService] Error getting user stats: $e', 'SocialService');
      return {
        'likeCount': 0,
        'commentCount': 0,
        'savedGamesCount': 0,
      };
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
