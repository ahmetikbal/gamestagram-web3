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
  List<InteractionModel> get currentViewingGameComments =>
      _currentViewingGameComments;
  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;
  String?
  _currentCommentsGameId; // Track which game's comments are currently loaded

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

  /// Initial loading of games with optimized image validation and caching
  Future<void> loadInitialGames({int? count}) async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      // Get all games but only process a small subset
      final allGames = await _gameService.getAllGames();
      AppLogger.debug(
        'Got ${allGames.length} total games from service',
        'GameViewModel',
      );

      if (allGames.isEmpty) {
        AppLogger.warning('No games available', 'GameViewModel');
        _games = [];
        return;
      }

      // Take only a manageable number of games and filter them
      final requestedCount = count ?? _initialLoadCount;
      final gamesToProcess =
          allGames
              .where(
                (game) =>
                    game.title.isNotEmpty &&
                    game.description.isNotEmpty &&
                    game.id.isNotEmpty,
              )
              .take(
                requestedCount * 3,
              ) // Get more than needed to account for filtering
              .toList();

      AppLogger.debug(
        'Processing ${gamesToProcess.length} games',
        'GameViewModel',
      );

      // Process games in batches to avoid overwhelming the system
      final processedGames = <GameModel>[];
      int processed = 0;

      for (final game in gamesToProcess) {
        try {
          // Basic initialization without heavy image validation
          game.likeCount = 0; // Start with 0, will be updated later
          game.commentCount = 0;
          game.isLikedByCurrentUser = false;
          game.isSavedByCurrentUser = false;

          processedGames.add(game);
          processed++;

          // Stop when we have enough games
          if (processedGames.length >= requestedCount) {
            break;
          }

          // Yield control every 5 games to prevent blocking (reduced from 10)
          if (processed % 5 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          AppLogger.error(
            'Error processing game ${game.id}',
            'GameViewModel',
            e,
          );
          continue;
        }
      }

      _games = processedGames;
      AppLogger.info(
        'Successfully loaded ${_games.length} games',
        'GameViewModel',
      );

      // Update UI immediately with basic game data
      notifyListeners();

      // Load social data in background (non-blocking)
      _loadSocialDataInBackground();

      // Cache games for better performance
      for (var game in _games) {
        _gameCache[game.id] = game;
      }

      // If we received fewer games than requested, we've likely reached the end
      _hasMoreGames = processedGames.length >= requestedCount;

      // Preload comments for these games in background
      _preloadNewGameComments(processedGames);

      AppLogger.info('Initial games loaded: ${_games.length}', 'GameViewModel');
    } catch (e) {
      AppLogger.error('Error in loadInitialGames', 'GameViewModel', e);
      _setError('Failed to load games: $e');
      _games = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load social data (likes, comments) in background without blocking UI
  void _loadSocialDataInBackground() async {
    try {
      bool hasUpdates = false;

      for (int i = 0; i < _games.length; i++) {
        final game = _games[i];

        // Load like count
        try {
          final likeCount = await _socialService.getLikeCount(game.id);
          if (game.likeCount != likeCount) {
            game.likeCount = likeCount;
            hasUpdates = true;
          }
        } catch (e) {
          AppLogger.error(
            'Error loading likes for ${game.id}',
            'GameViewModel',
            e,
          );
        }

        // Load comment count
        try {
          final commentCount = _socialService.getCommentCountFast(game.id);
          if (game.commentCount != commentCount) {
            game.commentCount = commentCount;
            hasUpdates = true;
          }
        } catch (e) {
          AppLogger.error(
            'Error loading comments for ${game.id}',
            'GameViewModel',
            e,
          );
        }

        // Update UI less frequently - every 10 games and only if there are changes
        if (i % 10 == 0 && hasUpdates) {
          notifyListeners();
          hasUpdates = false;
          await Future.delayed(
            const Duration(milliseconds: 50),
          ); // Reduced delay
        }
      }

      // Final UI update if there are pending changes
      if (hasUpdates) {
        notifyListeners();
      }

      AppLogger.info(
        'Background social data loading complete',
        'GameViewModel',
      );
    } catch (e) {
      AppLogger.error(
        'Error in background social data loading',
        'GameViewModel',
        e,
      );
    }
  }

  /// Syncs saved and liked games with current user (call this after login)
  Future<void> syncUserGameStates(String userId) async {
    if (_games.isEmpty) return;

    try {
      // Get saved game IDs for the user
      final savedGameIds = await _socialService.getSavedGameIds(userId);
      AppLogger.debug(
        'Found ${savedGameIds.length} saved games for user $userId',
        'GameViewModel',
      );

      // Update saved states for all games
      bool hasUpdates = false;
      for (var game in _games) {
        final wasSaved = game.isSavedByCurrentUser;
        game.isSavedByCurrentUser = savedGameIds.contains(game.id);

        if (wasSaved != game.isSavedByCurrentUser) {
          hasUpdates = true;
        }

        // Check liked state as well
        try {
          final isLiked = await _socialService.isGameLikedByUser(
            game.id,
            userId,
          );
          if (game.isLikedByCurrentUser != isLiked) {
            game.isLikedByCurrentUser = isLiked;
            hasUpdates = true;
          }
        } catch (e) {
          AppLogger.error(
            'Error checking liked state for game ${game.id}',
            'GameViewModel',
            e,
          );
        }
      }

      // Update saved games list
      _savedGames = _games.where((game) => game.isSavedByCurrentUser).toList();

      if (hasUpdates) {
        notifyListeners();
        AppLogger.info(
          'Synced user game states - ${_savedGames.length} saved games',
          'GameViewModel',
        );
      }
    } catch (e) {
      AppLogger.error('Error syncing user game states', 'GameViewModel', e);
    }
  }

  /// Loads additional games with optimized performance for infinite scrolling
  Future<void> fetchMoreGames({int? count}) async {
    if (_isLoading || !_hasMoreGames) {
      AppLogger.debug(
        'Skipping fetchMoreGames: isLoading=$_isLoading, hasMoreGames=$_hasMoreGames',
        'GameViewModel',
      );
      return;
    }

    final requestedCount = count ?? _additionalLoadCount;
    final currentGameCount = _games.length;

    AppLogger.debug(
      'Starting fetchMoreGames: current games=$currentGameCount, requesting=$requestedCount',
      'GameViewModel',
    );

    _setLoading(true);
    try {
      // Use the fast fetch method for better performance
      final moreGames = await _gameService.fetchGamesFast(
        count: requestedCount,
      );

      AppLogger.debug(
        'fetchGamesFast returned ${moreGames.length} games',
        'GameViewModel',
      );

      // If we got no new games, mark that we have no more
      if (moreGames.isEmpty) {
        _hasMoreGames = false;
        AppLogger.debug(
          'No more games available, setting hasMoreGames=false',
          'GameViewModel',
        );
        return;
      }

      // Process and cache each game
      for (var game in moreGames) {
        game.likeCount = await _socialService.getLikeCount(game.id);

        // Cache the game for better performance
        _gameCache[game.id] = game;

        // Use fast comment count for instant loading
        game.commentCount = _socialService.getCommentCountFast(game.id);
      }

      _games.addAll(moreGames);

      // Update whether we have more games to load - be more conservative
      _hasMoreGames = moreGames.length >= requestedCount;

      // Preload comments for these games in background
      _preloadNewGameComments(moreGames);

      AppLogger.info(
        'More games loaded. Total: ${_games.length}, hasMoreGames: $_hasMoreGames',
        'GameViewModel',
      );
    } catch (e) {
      _errorMessage = e.toString();
      _hasMoreGames = false; // Stop trying to load more if there's an error
      AppLogger.error(
        'Error fetching more games',
        'GameViewModel',
        _errorMessage,
      );
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
      final actualLikedState = await _socialService.toggleLikeGame(
        gameId,
        userId,
      );
      _games[gameIndex].isLikedByCurrentUser = actualLikedState;
      _games[gameIndex].likeCount = await _socialService.getLikeCount(gameId);
      notifyListeners();
      print(
        '[GameViewModel] Game $gameId like toggled by $userId. New status: ${game.isLikedByCurrentUser}, Likes: ${game.likeCount}',
      );
    } catch (e) {
      print(
        '[GameViewModel] Error toggling like for $gameId: $e. Reverting optimistic update.',
      );
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
      final actualSavedState = await _socialService.toggleSaveGame(
        gameId,
        userId,
      );
      _games[gameIndex].isSavedByCurrentUser = actualSavedState;

      // Update saved games list
      await fetchSavedGames(userId);

      notifyListeners();
      print(
        '[GameViewModel] Game $gameId save toggled by $userId. New status: ${game.isSavedByCurrentUser}',
      );
    } catch (e) {
      print(
        '[GameViewModel] Error toggling save for $gameId: $e. Reverting optimistic update.',
      );
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

      print(
        '[GameViewModel] Fetched ${_savedGames.length} saved games for user $userId',
      );
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
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse:
          () => GameModel(
            id: '',
            title: '',
            description: '',
            developerId: '',
            developerName: '',
          ),
    );
    return game.isSavedByCurrentUser;
  }

  /// Synchronous version - checks if a game is liked by the current user (from cached state)
  bool isGameLikedByUserSync(String gameId, String userId) {
    // Use the game's isLikedByCurrentUser flag which should be set when games are loaded
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse:
          () => GameModel(
            id: '',
            title: '',
            description: '',
            developerId: '',
            developerName: '',
          ),
    );
    return game.isLikedByCurrentUser;
  }

  /// Gets the like count for a specific game
  int getGameLikeCount(String gameId) {
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse:
          () => GameModel(
            id: '',
            title: '',
            description: '',
            developerId: '',
            developerName: '',
          ),
    );
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
      final comments = await _socialService.getComments(gameId, limit: 20);

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
        final existingIds =
            _currentViewingGameComments.map((c) => c.id).toSet();
        final newComments =
            comments.where((c) => !existingIds.contains(c.id)).toList();
        _currentViewingGameComments.addAll(newComments);
      }

      _hasMoreComments = comments.length >= 20; // Assuming 20 comments per page
      print(
        '[GameViewModel] Fetched ${comments.length} comments for game $gameId (page $_commentsPage)',
      );
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
    if (_isLoadingComments ||
        !_hasMoreComments ||
        _currentCommentsGameId == null)
      return;

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

    print(
      '[GameViewModel] Fast loaded ${uniqueComments.length} comments for game $gameId',
    );
  }

  /// Adds a comment with ultra-fast in-memory storage
  Future<void> addCommentFast(String gameId, String userId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      // Add comment using fast service (instant)
      final comment = await _socialService.addCommentFast(
        gameId,
        userId,
        text.trim(),
      );

      if (comment != null) {
        // Batch updates to reduce notifications
        bool shouldNotify = false;

        // Update UI immediately with the real comment
        if (_currentCommentsGameId == gameId) {
          // Check for duplicates before adding
          final existingIndex = _currentViewingGameComments.indexWhere(
            (c) => c.id == comment.id,
          );
          if (existingIndex == -1) {
            _currentViewingGameComments.insert(0, comment);
            shouldNotify = true;
          }
        }

        // Update game comment count
        final gameIndex = _games.indexWhere((g) => g.id == gameId);
        if (gameIndex != -1) {
          // Get accurate comment count from Firestore
          _games[gameIndex].commentCount = await _socialService.getCommentCount(
            gameId,
          );
          shouldNotify = true;
        }

        // Refresh user statistics to update profile counts
        await loadUserStatistics(userId);

        // Single notification for all updates
        if (shouldNotify) {
          notifyListeners();
        }

        print(
          '[GameViewModel] Fast comment added to game $gameId by user $userId',
        );
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
      print(
        '[GameViewModel] Loaded user stats for $userId: $likeCount likes, $commentCount comments',
      );
    } catch (e) {
      print('[GameViewModel] Error loading user stats: $e');
      _userStatsCache[userId] = {'likeCount': 0, 'commentCount': 0};
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
      print(
        '[GameViewModel] Loaded stats for game ${game.id}: ${game.likeCount} likes, ${game.commentCount} comments',
      );
    } catch (e) {
      print('[GameViewModel] Error loading game stats: $e');
    }
  }

  /// Loads user statistics
  Future<Map<String, int>> loadUserStats(String userId) async {
    try {
      final stats = {'likeCount': 0, 'commentCount': 0, 'savedGamesCount': 0};

      // Count saved games
      final savedGameIds = await _socialService.getSavedGameIds(userId);
      stats['savedGamesCount'] = savedGameIds.length;

      // For now, we don't have user-specific like/comment counts in the simplified service
      // These would need to be implemented if needed

      return stats;
    } catch (e) {
      print('[GameViewModel] Error loading user stats: $e');
      return {'likeCount': 0, 'commentCount': 0, 'savedGamesCount': 0};
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
      print(
        '[GameViewModel] Game $gameId ${isLiked ? 'liked' : 'unliked'} by user $userId',
      );
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
      print(
        '[GameViewModel] Game $gameId ${isSaved ? 'saved' : 'unsaved'} by user $userId',
      );
    } catch (e) {
      print('[GameViewModel] Error toggling save: $e');
    }
  }

  /// Gets whether there are more games available to load
  bool get hasMoreGames => _hasMoreGames;
}
