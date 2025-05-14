import 'package:flutter/material.dart';
import '../../services/game_service.dart'; // Adjust path
import '../../data/models/game_model.dart'; // Adjust path

class GameViewModel extends ChangeNotifier {
  final GameService _gameService = GameService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GameModel> _games = [];
  List<GameModel> get games => _games;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GameViewModel() {
    // Optionally load initial games when the ViewModel is created
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
    if (_isLoading) return; // Prevent multiple simultaneous fetches
    _setLoading(true);
    _clearError();
    try {
      final fetchedGames = await _gameService.fetchGames(count: count);
      _games = fetchedGames;
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
    // No _clearError() here, as we are appending, not replacing
    try {
      final moreGames = await _gameService.fetchGames(count: count);
      _games.addAll(moreGames);
      print('[GameViewModel] More games loaded. Total: ${_games.length}');
    } catch (e) {
      _errorMessage = e.toString(); // Could set a specific error for fetching more
      print('[GameViewModel] Error fetching more games: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  // Placeholder for pre-fetching logic if needed
  // Future<void> prefetchNextGames(String currentGameId) async { ... }
}
