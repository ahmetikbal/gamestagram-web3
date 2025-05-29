import 'package:flutter/material.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../services/game_service.dart';
import '../../services/social_service.dart';

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
    // Start background cache pre-warming for better performance
    _prewarmCacheInBackground();
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

  void _clearError() {
    _errorMessage = null;
  }

  /// Loads the initial set of games with optimized performance
  Future<void> fetchInitialGames({int? count}) async {
    if (_isLoading && _games.isEmpty) return;
    _setLoading(true);
    _clearError();
    try {
      // Use the fast fetch method that prioritizes cached results
      final fetchedGames = await _gameService.fetchGamesFast(count: count ?? _initialLoadCount);
      _games = fetchedGames;
      for (var game in _games) {
        game.likeCount = _socialService.getLikeCount(game.id);
        
        // Cache the game for better performance
        _gameCache[game.id] = game;
        
        // Use fast comment count for instant loading
        game.commentCount = _socialService.getCommentCountFast(game.id);
      }
      
      // If we received fewer games than requested, we've likely reached the end
      _hasMoreGames = fetchedGames.length >= (count ?? _initialLoadCount);
      
      // Preload comments for these games in background
      _preloadNewGameComments(fetchedGames);
      
      print('[GameViewModel] Initial games loaded: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching initial games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads additional games with optimized performance for infinite scrolling
  Future<void> fetchMoreGames({int? count}) async {
    if (_isLoading || !_hasMoreGames) return;
    _setLoading(true);
    try {
      // Use the fast fetch method for better performance
      final moreGames = await _gameService.fetchGamesFast(count: count ?? _additionalLoadCount);
      
      // Process and cache each game
      for (var game in moreGames) {
        game.likeCount = _socialService.getLikeCount(game.id);
        
        // Cache the game for better performance
        _gameCache[game.id] = game;
        
        // Use fast comment count for instant loading
        game.commentCount = _socialService.getCommentCountFast(game.id);
      }
      
      _games.addAll(moreGames);
      
      // Update whether we have more games to load
      _hasMoreGames = moreGames.length >= (count ?? _additionalLoadCount);
      
      // Preload comments for these games in background
      _preloadNewGameComments(moreGames);
      
      print('[GameViewModel] More games loaded. Total: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching more games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }
  
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
    notifyListeners();

    try {
      final actualLikedState = await _socialService.toggleLikeGame(gameId, userId);
      _games[gameIndex].isLikedByCurrentUser = actualLikedState;
      _games[gameIndex].likeCount = _socialService.getLikeCount(gameId);
      notifyListeners();
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
    notifyListeners();

    try {
      final actualSavedState = await _socialService.toggleSaveGame(gameId, userId);
      _games[gameIndex].isSavedByCurrentUser = actualSavedState;

      // Update saved games list
      await fetchSavedGames(userId);
      
      notifyListeners();
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
      final savedGameIds = _socialService.getSavedGameIds(userId);
      
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

  /// Checks if a specific game is saved by a user
  bool isGameSavedByUser(String gameId, String userId) {
    return _socialService.isGameSavedByUser(gameId, userId);
  }

  /// Checks if a specific game is liked by a user
  bool isGameLikedByUser(String gameId, String userId) {
    return _socialService.isGameLikedByUser(gameId, userId);
  }

  /// Gets the like count for a specific game
  int getGameLikeCount(String gameId) {
    final game = _games.firstWhere((g) => g.id == gameId, orElse: () => GameModel(id: '', title: '', description: ''));
    return game.likeCount;
  }

  /// Fetches comments for a specific game with optimized caching
  /// Shows cached comments immediately, then loads fresh data in background
  Future<void> fetchComments(String gameId, {bool forceRefresh = false}) async {
    // If switching to a different game, reset pagination
    if (_currentCommentsGameId != gameId) {
      _currentCommentsGameId = gameId;
      _commentsPage = 0;
      _hasMoreComments = true;
      _currentViewingGameComments.clear();
    }
    
    // Show cached comments immediately for instant UI feedback
    if (!forceRefresh && _commentsPage == 0) {
      final cachedComments = _socialService.getCachedComments(gameId);
      if (cachedComments.isNotEmpty) {
        // Remove duplicates by ID
        final uniqueComments = <InteractionModel>[];
        final seenIds = <String>{};
        for (final comment in cachedComments) {
          if (!seenIds.contains(comment.id)) {
            uniqueComments.add(comment);
            seenIds.add(comment.id);
          }
        }
        _currentViewingGameComments = uniqueComments;
        notifyListeners();
      }
    }
    
    // Load fresh comments in background
    _setLoadingComments(true);
    try {
      final comments = await _socialService.getComments(gameId, page: _commentsPage, forceRefresh: forceRefresh);
      
      if (_commentsPage == 0) {
        // Remove duplicates by ID for fresh load
        final uniqueComments = <InteractionModel>[];
        final seenIds = <String>{};
        for (final comment in comments) {
          if (!seenIds.contains(comment.id)) {
            uniqueComments.add(comment);
            seenIds.add(comment.id);
          }
        }
        _currentViewingGameComments = uniqueComments;
      } else {
        // For pagination, check for duplicates against existing comments
        final existingIds = _currentViewingGameComments.map((c) => c.id).toSet();
        final newComments = comments.where((c) => !existingIds.contains(c.id)).toList();
        _currentViewingGameComments.addAll(newComments);
      }
      
      _hasMoreComments = comments.length >= 20; // Assuming 20 comments per page
      print('[GameViewModel] Fetched ${comments.length} comments for game $gameId (page $_commentsPage)');
    } catch (e) {
      print('[GameViewModel] Error fetching comments for $gameId: $e');
      if (_commentsPage == 0) {
        _currentViewingGameComments = [];
      }
    } finally {
      _setLoadingComments(false);
    }
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
          final newCount = _socialService.getCommentCountFast(gameId);
          if (_games[gameIndex].commentCount != newCount) {
            _games[gameIndex].commentCount = newCount;
            shouldNotify = true;
          }
        }
        
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

  /// Gets user statistics for likes across all games
  int getUserLikeCount(String userId) {
    return _socialService.getUserLikeCount(userId);
  }
  
  /// Gets user statistics for comments across all games
  int getUserCommentCount(String userId) {
    return _socialService.getUserCommentCount(userId);
  }

  /// Pre-warms the image validation cache in the background
  void _prewarmCacheInBackground() {
    // Don't await this - let it run in background
    _gameService.prewarmImageCache().catchError((e) {
      print('[GameViewModel] Error pre-warming cache: $e');
    });
    
    // Also preload comments for better performance
    _preloadCommentsInBackground();
  }
  
  /// Preloads comments for current games in background
  void _preloadCommentsInBackground() {
    if (_games.isNotEmpty) {
      final gameIds = _games.map((game) => game.id).toList();
      _socialService.preloadComments(gameIds);
    }
  }
  
  /// Call this when new games are loaded to preload their comments
  void _preloadNewGameComments(List<GameModel> newGames) {
    final gameIds = newGames.map((game) => game.id).toList();
    _socialService.preloadComments(gameIds);
  }
}
 