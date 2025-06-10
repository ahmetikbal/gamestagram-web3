import 'package:flutter/material.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../services/game_service.dart';
import '../../services/social_service.dart';
import '../../utils/logger.dart';

/// ViewModel for managing game-related state and business logic
/// Handles game loading, social interactions, and UI state management
class GameViewModel extends ChangeNotifier {
  final GameService _gameService = GameService();
  final SocialService _socialService = SocialService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GameModel> _games = [];
  List<GameModel> get games => _games;

  List<GameModel> _savedGames = [];
  List<GameModel> get savedGames => _savedGames;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<InteractionModel> _currentViewingGameComments = [];
  List<InteractionModel> get currentViewingGameComments => _currentViewingGameComments;
  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;
  String? _currentCommentsGameId; // Track which game's comments are currently loaded
  
  // Global fullscreen mode flag for all games
  bool _isGlobalFullViewEnabled = false;
  bool get isGlobalFullViewEnabled => _isGlobalFullViewEnabled;
  
  // Track the currently playing game, if any
  String? _currentlyPlayingGameId;
  String? get currentlyPlayingGameId => _currentlyPlayingGameId;
  
  // Enhanced performance settings
  final int _initialLoadCount = 5;
  final int _additionalLoadCount = 5;
  final int _loadThreshold = 2; // Load more when 2 games remain
  final Map<String, GameModel> _gameCache = {};
  bool _hasMoreGames = true;

  // Comment pagination
  int _commentsPage = 0;
  bool _hasMoreComments = true;

  GameViewModel() {
    // GameService is already initialized as a final field
    // Skip pre-warming for now to prevent crashes
    AppLogger.debug('GameViewModel initialized', 'GameViewModel');
  }
  
  /// Get current user ID from auth context
  String? getCurrentUserId() {
    // This will be set by the calling context - for now return null
    // In a real implementation, this would get the current user from AuthViewModel
    return null; // TODO: Implement proper user ID retrieval
  }
  
  /// Toggles fullscreen mode for all games globally
  void toggleGlobalFullView() {
    _isGlobalFullViewEnabled = !_isGlobalFullViewEnabled;
    notifyListeners();
  }
  
  /// Sets the currently playing game for tracking purposes
  void setCurrentlyPlayingGame(String? gameId) {
    _currentlyPlayingGameId = gameId;
    notifyListeners();
  }

  void _setLoading(bool loading, {bool notify = true}) {
    _isLoading = loading;
    if (notify) notifyListeners();
  }

  void _setLoadingComments(bool loading) {
    _isLoadingComments = loading;
    notifyListeners();
  }



  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// SIMPLIFIED Initial loading - get games working first, optimize later
  /// Focus on getting games to load reliably without complex prefetching
  Future<void> loadInitialGames({int? count}) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      AppLogger.info('Loading games with simplified approach...', 'GameViewModel');
      
      // Step 1: Get games directly from service (most reliable path)
      final requestedCount = count ?? _initialLoadCount;
      final loadedGames = await _gameService.fetchGames(count: requestedCount);
      
      AppLogger.debug('Got ${loadedGames.length} games from service', 'GameViewModel');
      
      if (loadedGames.isEmpty) {
        AppLogger.warning('No games returned from service', 'GameViewModel');
        _games = [];
        _hasMoreGames = false;
        return;
      }
      
      // Step 2: Apply default social data (no prefetching for now)
      final processedGames = <GameModel>[];
      for (final game in loadedGames) {
        // Set simple defaults - no network calls during initial load
        game.likeCount = 0;
        game.commentCount = 0;
        game.isLikedByCurrentUser = false;
        game.isSavedByCurrentUser = false;
        
        processedGames.add(game);
        _gameCache[game.id] = game;
      }
      
      _games = processedGames;
      _hasMoreGames = processedGames.length >= requestedCount;
      
      AppLogger.info('✅ Successfully loaded ${_games.length} games', 'GameViewModel');
      
      // NO background loading - keep it simple for now
      
    } catch (e) {
      AppLogger.error('Error in loadInitialGames: $e', 'GameViewModel');
      _setError('Failed to load games: $e');
      _games = [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// DEPRECATED: No longer needed - all social data is prefetched
  /// This method is kept for compatibility but does nothing
  void _loadSocialDataInBackground() async {
    AppLogger.debug('Background loading skipped - all data prefetched', 'GameViewModel');
    // No-op: All social data is prefetched during initial load
  }

  /// SIMPLIFIED: Loads additional games with basic defaults
  /// Focus on reliability over complex optimizations
  Future<void> fetchMoreGames({int? count}) async {
    if (_isLoading || !_hasMoreGames) return;
    _setLoading(true, notify: false);
    
    try {
      final moreGames = await _gameService.fetchGames(count: count ?? _additionalLoadCount);
      
      // Apply simple defaults - no complex prefetching
      for (var game in moreGames) {
        game.likeCount = 0;
        game.commentCount = 0;
        game.isLikedByCurrentUser = false;
        game.isSavedByCurrentUser = false;
        _gameCache[game.id] = game;
      }
      
      _games.addAll(moreGames);
      _hasMoreGames = moreGames.length >= (count ?? _additionalLoadCount);
      _setLoading(false);
      
      AppLogger.info('More games loaded. Total: ${_games.length}', 'GameViewModel');
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('Error fetching more games: $e', 'GameViewModel');
      _setLoading(false);
    }
  }
  
  /// Load social data for specific games in background
  void _loadSocialDataForGames(List<GameModel> games) async {
    // Run in background without blocking
    Future.microtask(() async {
      for (final game in games) {
        try {
          // Use fast methods to avoid blocking
          game.commentCount = _socialService.getCommentCountFast(game.id);
          
          // Load like count asynchronously
          _socialService.getLikeCount(game.id).then((likeCount) {
            if (mounted) {
              game.likeCount = likeCount;
              // Only notify if this game is currently visible
              notifyListeners();
            }
          });
        } catch (e) {
          AppLogger.error('Error loading social data for ${game.id}', 'GameViewModel', e);
        }
        
        // Yield control to prevent blocking
        await Future.delayed(const Duration(microseconds: 100));
      }
    });
  }
  
  /// Check if the ViewModel is still mounted (for background operations)
  bool get mounted => _games.isNotEmpty;
  
  /// Determines if more games should be loaded based on current scroll position
  bool shouldLoadMoreGames(int currentIndex) {
    return _hasMoreGames && 
           !_isLoading &&
           (_games.length - currentIndex - 1) <= _loadThreshold;
  }

  /// Toggles like status for a game with optimistic UI updates
  Future<void> toggleLikeGame(String gameId, String userId) async {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    final originalIsLiked = game.isLikedByCurrentUser;
    final originalLikeCount = game.likeCount;

    game.isLikedByCurrentUser = !game.isLikedByCurrentUser;
    game.isLikedByCurrentUser ? game.likeCount++ : game.likeCount--;
    notifyListeners(); // Optimistic update

    try {
      final actualLikedState = await _socialService.toggleLikeGame(gameId, userId);
      _games[gameIndex].isLikedByCurrentUser = actualLikedState;
      _games[gameIndex].likeCount = await _socialService.getLikeCount(gameId);
      // Only notify if state actually changed
      if (game.isLikedByCurrentUser != actualLikedState || game.likeCount != _games[gameIndex].likeCount) {
        notifyListeners();
      }
      print('[GameViewModel] Game $gameId like toggled by $userId. New status: ${game.isLikedByCurrentUser}, Likes: ${game.likeCount}');
    } catch (e) {
      print('[GameViewModel] Error toggling like for $gameId: $e. Reverting optimistic update.');
      _games[gameIndex].isLikedByCurrentUser = originalIsLiked;
      _games[gameIndex].likeCount = originalLikeCount;
      notifyListeners();
    }
  }

  /// Toggles save status for a game with optimistic UI updates
  Future<void> toggleSaveGame(String gameId, String userId) async {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    final originalIsSaved = game.isSavedByCurrentUser;

    // Optimistic update
    game.isSavedByCurrentUser = !game.isSavedByCurrentUser;
    notifyListeners(); // Optimistic update

    try {
      final actualSavedState = await _socialService.toggleSaveGame(gameId, userId);
      _games[gameIndex].isSavedByCurrentUser = actualSavedState;

      // Update saved games list (this already calls notifyListeners)
      await fetchSavedGames(userId);
      
      // Don't notify again - fetchSavedGames already did
      print('[GameViewModel] Game $gameId save toggled by $userId. New status: ${game.isSavedByCurrentUser}');
    } catch (e) {
      print('[GameViewModel] Error toggling save for $gameId: $e. Reverting optimistic update.');
      _games[gameIndex].isSavedByCurrentUser = originalIsSaved;
      notifyListeners();
    }
  }

  /// Fetches all games saved by a specific user
  Future<void> fetchSavedGames(String userId) async {
    _savedGames = [];
    
    try {
      final savedGameIds = await _socialService.getSavedGameIds(userId);
      
      // Create a set to prevent duplicate games
      final addedGameIds = <String>{};
      
      // Filter games that are saved by the user
      for (var game in _games) {
        if (savedGameIds.contains(game.id) && !addedGameIds.contains(game.id)) {
          game.isSavedByCurrentUser = true;
          _savedGames.add(game);
          addedGameIds.add(game.id);
        }
      }

      print('[GameViewModel] Fetched ${_savedGames.length} saved games for user $userId');
      notifyListeners();
    } catch (e) {
      print('[GameViewModel] Error fetching saved games: $e');
    }
  }

  /// Checks if a game is saved by the current user
  Future<bool> isGameSavedByUser(String gameId, String userId) async {
    final savedGameIds = await _socialService.getSavedGameIds(userId);
    return savedGameIds.contains(gameId);
  }

  /// Checks if a game is liked by the current user
  Future<bool> isGameLikedByUser(String gameId, String userId) async {
    return await _socialService.isGameLikedByUser(gameId, userId);
  }

  /// Synchronous version - checks if a game is saved by the current user (from cached state)
  bool isGameSavedByUserSync(String gameId, String userId) {
    // Use the game's isSavedByCurrentUser flag which should be set when games are loaded
    final game = _games.firstWhere((g) => g.id == gameId, orElse: () => GameModel(id: '', title: '', description: ''));
    return game.isSavedByCurrentUser;
  }

  /// Synchronous version - checks if a game is liked by the current user (from cached state)
  bool isGameLikedByUserSync(String gameId, String userId) {
    // Use the game's isLikedByCurrentUser flag which should be set when games are loaded
    final game = _games.firstWhere((g) => g.id == gameId, orElse: () => GameModel(id: '', title: '', description: ''));
    return game.isLikedByCurrentUser;
  }

  /// Gets the like count for a specific game
  int getGameLikeCount(String gameId) {
    final game = _games.firstWhere((g) => g.id == gameId, orElse: () => GameModel(id: '', title: '', description: ''));
    return game.likeCount;
  }

  /// PREFETCH-OPTIMIZED: Fetches comments instantly from cache
  /// No network requests - all comments are prefetched
  Future<void> fetchComments(String gameId, {bool forceRefresh = false}) async {
    // If switching to a different game, reset pagination
    if (_currentCommentsGameId != gameId) {
      _currentCommentsGameId = gameId;
      _commentsPage = 0;
      _hasMoreComments = false; // All comments are prefetched, no pagination needed
      _currentViewingGameComments.clear();
    }
    
    try {
      // Get comments INSTANTLY from prefetched cache (ZERO latency)
      final comments = _socialService.getCommentsInstant(gameId);
      
      // Remove duplicates by ID
      final uniqueComments = <InteractionModel>[];
      final seenIds = <String>{};
      for (final comment in comments) {
        if (!seenIds.contains(comment.id)) {
          uniqueComments.add(comment);
          seenIds.add(comment.id);
        }
      }
      
      _currentViewingGameComments = uniqueComments;
      AppLogger.debug('Fetched ${uniqueComments.length} comments INSTANTLY for game $gameId', 'GameViewModel');
    } catch (e) {
      // Fallback to empty comments if prefetch failed
      AppLogger.debug('Comments prefetch not available for $gameId, using empty list: $e', 'GameViewModel');
      _currentViewingGameComments = [];
    }
    
    notifyListeners();
  }
  
  /// Loads more comments for pagination
  Future<void> fetchMoreComments() async {
    if (_isLoadingComments || !_hasMoreComments || _currentCommentsGameId == null) return;
    
    _commentsPage++;
    await fetchComments(_currentCommentsGameId!, forceRefresh: false);
  }

  /// Super-fast comment fetching that shows memory data instantly
  void fetchCommentsFast(String gameId) {
    // Switch game context
    if (_currentCommentsGameId != gameId) {
      _currentCommentsGameId = gameId;
      _commentsPage = 0;
      _hasMoreComments = true;
    }
    
    // Get comments from memory instantly (no await needed)
    final comments = _socialService.getCommentsFast(gameId);
    
    // Remove duplicates and update UI immediately
    final uniqueComments = <InteractionModel>[];
    final seenIds = <String>{};
    for (final comment in comments) {
      if (!seenIds.contains(comment.id)) {
        uniqueComments.add(comment);
        seenIds.add(comment.id);
      }
    }
    
    // Only notify if comments actually changed
    if (_currentViewingGameComments.length != uniqueComments.length ||
        !_listsEqual(_currentViewingGameComments, uniqueComments)) {
      _currentViewingGameComments = uniqueComments;
      _hasMoreComments = false; // Memory loads all at once
      notifyListeners();
    }
    
    print('[GameViewModel] Fast loaded ${uniqueComments.length} comments for game $gameId');
  }

  /// Adds a comment with ultra-fast in-memory storage
  Future<void> addCommentFast(String gameId, String userId, String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Add comment using fast service (instant)
      final comment = await _socialService.addCommentFast(gameId, userId, text.trim());
      
      if (comment != null) {
        // Batch updates to reduce notifications
        bool shouldNotify = false;
        
        // Update UI immediately with the real comment
        if (_currentCommentsGameId == gameId) {
          // Check for duplicates before adding
          final existingIndex = _currentViewingGameComments.indexWhere((c) => c.id == comment.id);
          if (existingIndex == -1) {
            _currentViewingGameComments.insert(0, comment);
            shouldNotify = true;
          }
        }
        
        // Update game comment count
        final gameIndex = _games.indexWhere((g) => g.id == gameId);
        if (gameIndex != -1) {
          // Get accurate comment count from Firestore
          _games[gameIndex].commentCount = await _socialService.getCommentCount(gameId);
          shouldNotify = true;
        }
        
        // Refresh user statistics to update profile counts
        await loadUserStatistics(userId);
        
        // Single notification for all updates
        if (shouldNotify) {
          notifyListeners();
        }
        
        print('[GameViewModel] Fast comment added to game $gameId by user $userId');
      }
    } catch (e) {
      print('[GameViewModel] Error adding fast comment: $e');
    }
  }

  /// Helper method to compare lists efficiently
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Cache for user stats to avoid frequent Firestore calls
  final Map<String, Map<String, int>> _userStatsCache = {};
  
  /// Gets user statistics for likes across all games
  int getUserLikeCount(String userId) {
    return _userStatsCache[userId]?['likeCount'] ?? 0;
  }
  
  /// Gets user statistics for comments across all games
  int getUserCommentCount(String userId) {
    return _userStatsCache[userId]?['commentCount'] ?? 0;
  }

  /// Loads and caches user statistics
  Future<void> loadUserStatistics(String userId) async {
    try {
      final likeCount = await _socialService.getUserLikeCount(userId);
      final commentCount = await _socialService.getUserCommentCount(userId);
      
      _userStatsCache[userId] = {
        'likeCount': likeCount,
        'commentCount': commentCount,
      };
      
      notifyListeners();
      print('[GameViewModel] Loaded user stats for $userId: $likeCount likes, $commentCount comments');
    } catch (e) {
      print('[GameViewModel] Error loading user stats: $e');
      _userStatsCache[userId] = {
        'likeCount': 0,
        'commentCount': 0,
      };
    }
  }

  /// Call this when new games are loaded to preload their comments
  void _preloadNewGameComments(List<GameModel> newGames) {
    final gameIds = newGames.map((game) => game.id).toList();
    _socialService.preloadComments(gameIds);
  }

  /// Loads game statistics (likes, comments, etc.)
  Future<void> loadGameStats(GameModel game) async {
    try {
      // Update like count
      game.likeCount = await _socialService.getLikeCount(game.id);
      
      // Update comment count
      game.commentCount = await _socialService.getCommentCount(game.id);
      
      notifyListeners();
      print('[GameViewModel] Loaded stats for game ${game.id}: ${game.likeCount} likes, ${game.commentCount} comments');
    } catch (e) {
      print('[GameViewModel] Error loading game stats: $e');
    }
  }

  /// Loads user statistics
  Future<Map<String, int>> loadUserStats(String userId) async {
    try {
      final stats = {
        'likeCount': 0,
        'commentCount': 0,
        'savedGamesCount': 0,
      };
      
      // Count saved games
      final savedGameIds = await _socialService.getSavedGameIds(userId);
      stats['savedGamesCount'] = savedGameIds.length;
      
      // For now, we don't have user-specific like/comment counts in the simplified service
      // These would need to be implemented if needed
      
      return stats;
    } catch (e) {
      print('[GameViewModel] Error loading user stats: $e');
      return {
        'likeCount': 0,
        'commentCount': 0,
        'savedGamesCount': 0,
      };
    }
  }

  /// Toggles like status for a game
  Future<void> toggleLike(String gameId, String userId) async {
    try {
      final isLiked = await _socialService.toggleLikeGame(gameId, userId);
      
      // Update the game in memory
      final gameIndex = _games.indexWhere((g) => g.id == gameId);
      if (gameIndex != -1) {
        _games[gameIndex].isLikedByCurrentUser = isLiked;
        // Update like count
        _games[gameIndex].likeCount = await _socialService.getLikeCount(gameId);
      }
      
      // Refresh user statistics to update profile counts
      await loadUserStatistics(userId);
      
      notifyListeners();
      print('[GameViewModel] Game $gameId ${isLiked ? 'liked' : 'unliked'} by user $userId');
    } catch (e) {
      print('[GameViewModel] Error toggling like: $e');
    }
  }

  /// Toggles save status for a game
  Future<void> toggleSave(String gameId, String userId) async {
    try {
      final isSaved = await _socialService.toggleSaveGame(gameId, userId);
      
      // Update the game in memory
      final gameIndex = _games.indexWhere((g) => g.id == gameId);
      if (gameIndex != -1) {
        _games[gameIndex].isSavedByCurrentUser = isSaved;
      }
      
      // If the game was unsaved, remove it from saved games list
      if (!isSaved) {
        _savedGames.removeWhere((g) => g.id == gameId);
      } else {
        // If the game was saved and it's not in the saved games list, add it
        final savedGame = _games.firstWhere((g) => g.id == gameId);
        if (!_savedGames.any((g) => g.id == gameId)) {
          _savedGames.add(savedGame);
        }
      }
      
      notifyListeners();
      print('[GameViewModel] Game $gameId ${isSaved ? 'saved' : 'unsaved'} by user $userId');
    } catch (e) {
      print('[GameViewModel] Error toggling save: $e');
    }
  }
}
 