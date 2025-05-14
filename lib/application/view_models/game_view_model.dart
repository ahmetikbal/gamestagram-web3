import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/social_service.dart';
import '../../data/models/game_model.dart';
import '../../data/models/user_model.dart';

class GameViewModel extends ChangeNotifier {
  final GameService _gameService = GameService();
  final SocialService _socialService = SocialService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GameModel> _games = [];
  List<GameModel> get games => _games;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GameViewModel() {
    // fetchInitialGames();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> fetchInitialGames({int count = 5}) async {
    if (_isLoading && _games.isEmpty) return;
    _setLoading(true);
    _clearError();
    try {
      final fetchedGames = await _gameService.fetchGames(count: count);
      _games = fetchedGames;
      for (var game in _games) {
        game.likeCount = _socialService.getLikeCount(game.id);
      }
      print('[GameViewModel] Initial games loaded: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching initial games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMoreGames({int count = 3}) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final moreGames = await _gameService.fetchGames(count: count);
      for (var game in moreGames) {
        game.likeCount = _socialService.getLikeCount(game.id);
      }
      _games.addAll(moreGames);
      print('[GameViewModel] More games loaded. Total: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString();
      print('[GameViewModel] Error fetching more games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleLikeGame(String gameId, String userId) async {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex == -1) return;

    final game = _games[gameIndex];
    game.isLikedByCurrentUser = !game.isLikedByCurrentUser;
    game.isLikedByCurrentUser ? game.likeCount++ : game.likeCount--;
    notifyListeners();

    final success = await _socialService.toggleLikeGame(gameId, userId);
    if (game.isLikedByCurrentUser != success) {
      print('[GameViewModel] Like toggle failed for $gameId, reverting UI (mock scenario)');
      game.isLikedByCurrentUser = !game.isLikedByCurrentUser;
      game.isLikedByCurrentUser ? game.likeCount++ : game.likeCount--;
      notifyListeners();
    } else {
      _games[gameIndex].likeCount = _socialService.getLikeCount(gameId);
      notifyListeners();
  // Placeholder for pre-fetching logic if needed
  // Future<void> prefetchNextGames(String currentGameId) async { ... }
}
