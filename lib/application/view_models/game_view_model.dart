import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/social_service.dart';
import '../../data/models/game_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/interaction_model.dart';

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

  GameViewModel() {
    // fetchInitialGames();
  }

  // Toggle global fullscreen mode for all games
  void toggleGlobalFullView() {
    _isGlobalFullViewEnabled = !_isGlobalFullViewEnabled;
    notifyListeners();
  }

  // Set the currently playing game
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

  Future<void> fetchInitialGames({int? count}) async {
    if (_isLoading && _games.isEmpty) return;
    _setLoading(true);
    _clearError();
    try {
      final fetchedGames = await _gameService.fetchGames(
        count: count ?? _initialLoadCount,
      );
      _games = fetchedGames;
      for (var game in _games) {
        game.likeCount = await _socialService.getLikeCount(game.id);

        // Cache the game for better performance
        _gameCache[game.id] = game;

        // Initialize comment counts
        final comments = await _socialService.getComments(game.id);
        game.commentCount = comments.length;
      }

      // If we received fewer games than requested, we've likely reached the end
      _hasMoreGames = fetchedGames.length >= (count ?? _initialLoadCount);

      print('[GameViewModel] Initial games loaded: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching initial games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMoreGames({int? count}) async {
    if (_isLoading || !_hasMoreGames) return;
    _setLoading(true);
    try {
      final moreGames = await _gameService.fetchGames(
        count: count ?? _additionalLoadCount,
      );

      // Process and cache each game
      for (var game in moreGames) {
        game.likeCount = await _socialService.getLikeCount(game.id);

        // Cache the game for better performance
        _gameCache[game.id] = game;

        // Initialize comment counts
        final comments = await _socialService.getComments(game.id);
        game.commentCount = comments.length;
      }

      _games.addAll(moreGames);

      // Update whether we have more games to load
      _hasMoreGames = moreGames.length >= (count ?? _additionalLoadCount);

      print('[GameViewModel] More games loaded. Total: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching more games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  // Determine if we should load more games based on position
  bool shouldLoadMoreGames(int currentIndex) {
    return _hasMoreGames &&
        !_isLoading &&
        (_games.length - currentIndex - 1) <= _loadThreshold;
  }

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

  Future<void> fetchSavedGames(String userId) async {
    _savedGames = [];

    try {
      // Get list of saved game IDs
      final savedGameIds = await _socialService.getSavedGameIds(userId);

      // Create a Set to track already added game IDs to avoid duplicates
      final Set<String> addedGameIds = {};

      // Filter games that are saved
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

  // Check if a game is saved by the user
  bool isGameSavedByUser(String gameId, String? userId) {
    if (userId == null) return false;
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse: () => GameModel(id: '', title: '', description: ''),
    );
    return game.isSavedByCurrentUser;
  }

  bool isGameLikedByUser(String gameId, String? userId) {
    if (userId == null) return false;
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse: () => GameModel(id: '', title: '', description: ''),
    );
    return game.isLikedByCurrentUser;
  }

  int getGameLikeCount(String gameId) {
    final game = _games.firstWhere(
      (g) => g.id == gameId,
      orElse: () => GameModel(id: '', title: '', description: ''),
    );
    return game.likeCount;
  }

  Future<void> fetchCommentsForGame(String gameId) async {
    _setLoadingComments(true);
    try {
      _currentViewingGameComments = await _socialService.getComments(gameId);
      print(
        '[GameViewModel] Fetched ${_currentViewingGameComments.length} comments for game $gameId',
      );
    } catch (e) {
      print('[GameViewModel] Error fetching comments for $gameId: $e');
      _currentViewingGameComments = [];
    } finally {
      _setLoadingComments(false);
    }
  }

  Future<bool> addCommentToGame(
    String gameId,
    String userId,
    String text,
  ) async {
    final newComment = await _socialService.addComment(gameId, userId, text);
    if (newComment != null) {
      _currentViewingGameComments.insert(0, newComment);
      final gameIndex = _games.indexWhere((g) => g.id == gameId);
      if (gameIndex != -1) {
        _games[gameIndex].commentCount++;
      }
      notifyListeners();
      print('[GameViewModel] Comment added to $gameId by $userId');
      return true;
    }
    return false;
  }

  // Load like counts when games are fetched
  Future<void> loadGameStats(GameModel game) async {
    final stats = await _socialService.getGameStats(game.id);
    game.likeCount = stats['likeCount'] ?? 0;
    game.commentCount = stats['commentCount'] ?? 0;
  }

  // Update these to cache the values for better performance
  int _userLikeCountCache = 0;
  int _userCommentCountCache = 0;

  Future<void> loadUserStats(String userId) async {
    final stats = await _socialService.getUserStats(userId);
    _userLikeCountCache = stats['likeCount'] ?? 0;
    _userCommentCountCache = stats['commentCount'] ?? 0;
    notifyListeners();
  }

  int getUserLikeCount(String userId) {
    return _userLikeCountCache;
  }

  int getUserCommentCount(String userId) {
    return _userCommentCountCache;
  }

  /*
  // Get the number of likes made by a user
  Future<int> getUserLikeCount(String userId) {
    return _socialService.getUserLikeCount(userId);
  }

  // Get the number of comments made by a user
  Future<int> getUserCommentCount(String userId) {
    return _socialService.getUserCommentCount(userId);
  }
  */
}
