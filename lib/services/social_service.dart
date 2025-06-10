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

  // COMPREHENSIVE PREFETCH CACHING SYSTEM
  static final Map<String, int> _likeCacheMap = {};
  static final Map<String, int> _commentCountCacheMap = {};
  static final Map<String, List<InteractionModel>> _commentCacheMap = {};
  static final Map<String, bool> _userLikeCacheMap = {};
  static final Map<String, bool> _userSaveCacheMap = {};
  static final Map<String, Map<String, int>> _userStatsCacheMap = {};
  static bool _isPrefetchComplete = false;
  
  /// PREFETCH ALL SOCIAL DATA AT STARTUP (PERFORMANCE CRITICAL)
  /// This eliminates ALL network requests during scrolling
  Future<void> prefetchAllSocialData(List<String> gameIds, String? currentUserId) async {
    if (_isPrefetchComplete && gameIds.length <= _likeCacheMap.length) {
      AppLogger.debug('Social data already prefetched for ${_likeCacheMap.length} games', 'SocialService');
      return;
    }
    
    AppLogger.info('Prefetching ALL social data for ${gameIds.length} games...', 'SocialService');
    final startTime = DateTime.now();
    
    try {
      // Batch all network requests to minimize Firebase calls
      await Future.wait([
        _prefetchLikeCounts(gameIds),
        _prefetchCommentCounts(gameIds),
        _prefetchAllComments(gameIds),
        if (currentUserId != null) _prefetchUserInteractions(gameIds, currentUserId),
        if (currentUserId != null) _prefetchUserStats(currentUserId),
      ]);
      
      _isPrefetchComplete = true;
      final duration = DateTime.now().difference(startTime);
      AppLogger.info('✅ ALL social data prefetched in ${duration.inMilliseconds}ms', 'SocialService');
      AppLogger.info('Cached: ${_likeCacheMap.length} likes, ${_commentCountCacheMap.length} comment counts, ${_commentCacheMap.length} comment threads', 'SocialService');
    } catch (e) {
      AppLogger.error('Error prefetching social data: $e', 'SocialService');
    }
  }
  
  /// Prefetch like counts for all games in one batch
  Future<void> _prefetchLikeCounts(List<String> gameIds) async {
    try {
      final batch = gameIds.take(500).toList(); // Firestore limit
      final futures = batch.map((gameId) async {
        try {
          final gameDoc = await _gamesCollection.doc(gameId).get();
          final gameData = gameDoc.data() as Map<String, dynamic>?;
          _likeCacheMap[gameId] = gameData?['likeCount'] ?? 0;
        } catch (e) {
          _likeCacheMap[gameId] = 0; // Default on error
        }
      });
      
      await Future.wait(futures);
      AppLogger.debug('Prefetched like counts for ${batch.length} games', 'SocialService');
    } catch (e) {
      AppLogger.error('Error prefetching like counts: $e', 'SocialService');
    }
  }
  
  /// Prefetch comment counts for all games in one batch
  Future<void> _prefetchCommentCounts(List<String> gameIds) async {
    try {
      final batch = gameIds.take(500).toList();
      final futures = batch.map((gameId) async {
        try {
          final gameDoc = await _gamesCollection.doc(gameId).get();
          final gameData = gameDoc.data() as Map<String, dynamic>?;
          _commentCountCacheMap[gameId] = gameData?['commentCount'] ?? 0;
        } catch (e) {
          _commentCountCacheMap[gameId] = 0;
        }
      });
      
      await Future.wait(futures);
      AppLogger.debug('Prefetched comment counts for ${batch.length} games', 'SocialService');
    } catch (e) {
      AppLogger.error('Error prefetching comment counts: $e', 'SocialService');
    }
  }
  
  /// Prefetch ALL comments for ALL games upfront
  Future<void> _prefetchAllComments(List<String> gameIds) async {
    try {
      // Process in smaller batches to avoid overwhelming Firestore
      const batchSize = 50;
      for (int i = 0; i < gameIds.length; i += batchSize) {
        final batch = gameIds.skip(i).take(batchSize).toList();
        
        final futures = batch.map((gameId) async {
          try {
            final gameRef = _gamesCollection.doc(gameId);
            final commentsRef = gameRef.collection('comments');
            
            final querySnapshot = await commentsRef
                .orderBy('timestamp', descending: true)
                .limit(50) // Get more comments per game
                .get();
            
            final comments = querySnapshot.docs.map((doc) {
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
            }).toList();
            
            _commentCacheMap[gameId] = comments;
          } catch (e) {
            _commentCacheMap[gameId] = []; // Empty list on error
          }
        });
        
        await Future.wait(futures);
        
        // Small delay between batches to prevent rate limiting
        if (i + batchSize < gameIds.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      AppLogger.debug('Prefetched comments for ${gameIds.length} games', 'SocialService');
    } catch (e) {
      AppLogger.error('Error prefetching comments: $e', 'SocialService');
    }
  }
  
  /// Prefetch user interaction states (likes, saves)
  Future<void> _prefetchUserInteractions(List<String> gameIds, String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData != null) {
        final likedGames = List<String>.from(userData['likedGames'] ?? []);
        final savedGames = List<String>.from(userData['savedGames'] ?? []);
        
        // Cache all game interaction states
        for (final gameId in gameIds) {
          _userLikeCacheMap['${userId}_$gameId'] = likedGames.contains(gameId);
          _userSaveCacheMap['${userId}_$gameId'] = savedGames.contains(gameId);
        }
      }
      
      AppLogger.debug('Prefetched user interactions for ${gameIds.length} games', 'SocialService');
    } catch (e) {
      AppLogger.error('Error prefetching user interactions: $e', 'SocialService');
    }
  }
  
  /// Prefetch user statistics
  Future<void> _prefetchUserStats(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData != null) {
        _userStatsCacheMap[userId] = {
          'likeCount': userData['likeCount'] ?? 0,
          'commentCount': userData['commentCount'] ?? 0,
        };
      }
      
      AppLogger.debug('Prefetched user stats for $userId', 'SocialService');
    } catch (e) {
      _userStatsCacheMap[userId] = {'likeCount': 0, 'commentCount': 0};
      AppLogger.error('Error prefetching user stats: $e', 'SocialService');
    }
  }

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

  // INSTANT ACCESS METHODS (NO NETWORK CALLS)
  
  /// Get like count instantly from cache (ZERO latency)
  int getLikeCountInstant(String gameId) {
    return _likeCacheMap[gameId] ?? 0;
  }
  
  /// Get comment count instantly from cache (ZERO latency)
  int getCommentCountInstant(String gameId) {
    return _commentCountCacheMap[gameId] ?? 0;
  }
  
  /// Get comments instantly from cache (ZERO latency)
  List<InteractionModel> getCommentsInstant(String gameId) {
    return _commentCacheMap[gameId] ?? [];
  }
  
  /// Check if game is liked by user instantly (ZERO latency)
  bool isGameLikedByUserInstant(String gameId, String userId) {
    return _userLikeCacheMap['${userId}_$gameId'] ?? false;
  }
  
  /// Check if game is saved by user instantly (ZERO latency)
  bool isGameSavedByUserInstant(String gameId, String userId) {
    return _userSaveCacheMap['${userId}_$gameId'] ?? false;
  }
  
  /// Get user like count instantly (ZERO latency)
  int getUserLikeCountInstant(String userId) {
    return _userStatsCacheMap[userId]?['likeCount'] ?? 0;
  }
  
  /// Get user comment count instantly (ZERO latency)
  int getUserCommentCountInstant(String userId) {
    return _userStatsCacheMap[userId]?['commentCount'] ?? 0;
  }
}
