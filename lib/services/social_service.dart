import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/interaction_model.dart';
import '../data/models/user_model.dart';

/// Service for managing social interactions like likes, saves, and comments
/// Uses SharedPreferences for local data persistence with optimized caching
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
  
  // Comment caching for better performance
  static const int _commentsPerPage = 20;
  final Map<String, List<InteractionModel>> _commentsCache = {};
  final Map<String, bool> _commentsFullyLoaded = {};
  final Map<String, int> _commentCounts = {}; // Cache comment counts

  // In-memory comment storage for instant access
  final Map<String, List<InteractionModel>> _memoryComments = {};
  final Map<String, int> _memoryCounts = {};
  bool _persistenceEnabled = true;

  SocialService() {
    _loadDataFromPrefs();
    _initializeMemoryFromStorage();
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

  /// Clears comment caches for memory management
  void clearCommentCache({String? gameId}) {
    if (gameId != null) {
      _commentsCache.remove(gameId);
      _commentsFullyLoaded.remove(gameId);
      _commentCounts.remove(gameId);
    } else {
      _commentsCache.clear();
      _commentsFullyLoaded.clear();
      _commentCounts.clear();
    }
  }

  /// Persists social interaction data to SharedPreferences with optimized caching
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

  /// Adds a comment with instant in-memory storage and background persistence
  Future<InteractionModel?> addCommentFast(String gameId, String userId, String content) async {
    // Create comment immediately without any async operations
    final comment = InteractionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
      userId: userId,
      username: 'User $userId', // Fast mock username
      content: content,
      timestamp: DateTime.now(),
      type: InteractionType.comment,
    );

    // Store in memory immediately for instant access
    _memoryComments.putIfAbsent(gameId, () => []);
    _memoryComments[gameId]!.insert(0, comment);
    _memoryCounts[gameId] = (_memoryCounts[gameId] ?? 0) + 1;
    
    // Update cache immediately for instant UI feedback
    _commentsCache[gameId] = List.from(_memoryComments[gameId]!);
    _commentCounts[gameId] = _memoryCounts[gameId]!;
    
    // Background persistence (fire and forget) - optimized
    if (_persistenceEnabled) {
      _addCommentToPersistentStorageOptimized(gameId, comment);
    }
    
    return comment;
  }
  
  /// Ultra-optimized background persistence
  void _addCommentToPersistentStorageOptimized(String gameId, InteractionModel comment) {
    // Use a more efficient background operation
    Future(() async {
      try {
        _gameComments.putIfAbsent(gameId, () => []);
        _gameComments[gameId]!.insert(0, comment);
        
        // Batch save operations to reduce I/O
        _scheduleBatchSave();
      } catch (e) {
        print('[SocialService] Background persistence error: $e');
      }
    });
  }
  
  bool _saveScheduled = false;
  
  /// Batch save operations for better performance
  void _scheduleBatchSave() {
    if (_saveScheduled) return;
    
    _saveScheduled = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_saveScheduled) {
        await _saveDataToPrefs();
        _saveScheduled = false;
      }
    });
  }
  
  /// Fast comment retrieval from memory
  List<InteractionModel> getCommentsFast(String gameId) {
    return _memoryComments[gameId] ?? [];
  }
  
  /// Fast comment count from memory
  int getCommentCountFast(String gameId) {
    return _memoryCounts[gameId] ?? 0;
  }
  
  /// Retrieves comments for a game with caching and pagination
  /// Returns cached comments immediately if available
  Future<List<InteractionModel>> getComments(String gameId, {int page = 0, bool forceRefresh = false}) async {
    // Return cached comments immediately if available and not forcing refresh
    if (!forceRefresh && _commentsCache.containsKey(gameId) && page == 0) {
      return _commentsCache[gameId]!;
    }
    
    // Load from storage if not in cache or refreshing
    final allComments = _gameComments[gameId] ?? [];
    allComments.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    
    // Cache the full list for instant access
    _commentsCache[gameId] = allComments;
    _commentsFullyLoaded[gameId] = true;
    _commentCounts[gameId] = allComments.length;
    
    // Return paginated results
    final startIndex = page * _commentsPerPage;
    final endIndex = (startIndex + _commentsPerPage).clamp(0, allComments.length);
    
    if (startIndex >= allComments.length) {
      return [];
    }
    
    return allComments.sublist(startIndex, endIndex);
  }

  /// Fast method to get cached comments without storage access
  /// Useful for immediate UI updates
  List<InteractionModel> getCachedComments(String gameId) {
    return _commentsCache[gameId] ?? [];
  }
  
  /// Fast method to get comment count from cache
  int getCommentCount(String gameId) {
    return _commentCounts[gameId] ?? _gameComments[gameId]?.length ?? 0;
  }
  
  /// Pre-loads comments for multiple games in background
  /// Improves performance when scrolling through games
  Future<void> preloadComments(List<String> gameIds) async {
    final futures = gameIds.map((gameId) async {
      if (!_commentsCache.containsKey(gameId)) {
        await getComments(gameId);
      }
    });
    
    // Execute preloading concurrently but don't wait for all to complete
    Future.wait(futures).catchError((e) {
      print('[SocialService] Error preloading comments: $e');
      return <Null>[];
    });
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

  /// Initialize in-memory storage from persistent data in background
  void _initializeMemoryFromStorage() {
    Future.microtask(() {
      try {
        // Copy comments to memory for fast access
        for (final entry in _gameComments.entries) {
          _memoryComments[entry.key] = List.from(entry.value);
          _memoryCounts[entry.key] = entry.value.length;
          _commentsCache[entry.key] = List.from(entry.value);
          _commentCounts[entry.key] = entry.value.length;
        }
        print('[SocialService] Memory storage initialized with ${_memoryComments.length} games');
      } catch (e) {
        print('[SocialService] Error initializing memory storage: $e');
      }
    });
  }
}
