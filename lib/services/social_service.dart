import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/interaction_model.dart';
import '../data/models/user_model.dart';

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
  }
}
