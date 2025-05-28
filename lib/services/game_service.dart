import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../data/models/game_model.dart';

/// Service for managing game data and operations
/// Loads games from JSON asset file and provides game-related functionality
class GameService {
  static List<GameModel>? _cachedGames;
  static bool _isLoading = false;

  /// Loads all games from the JSON asset file
  /// Uses caching to avoid repeated file reads
  Future<List<GameModel>> _loadGamesFromAsset() async {
    if (_cachedGames != null) {
      return _cachedGames!;
    }

    if (_isLoading) {
      // Wait for the current loading operation to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedGames ?? [];
    }

    _isLoading = true;
    try {
      print('[GameService] Loading games from JSON asset...');
      final String jsonString = await rootBundle.loadString('assets/games.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> gamesJson = jsonData['games'] as List<dynamic>;
      
      _cachedGames = gamesJson.map((gameJson) => GameModel.fromJson(gameJson as Map<String, dynamic>)).toList();
      
      print('[GameService] Successfully loaded ${_cachedGames!.length} games from JSON');
      return _cachedGames!;
    } catch (e) {
      print('[GameService] Error loading games from JSON: $e');
      // Return empty list on error
      _cachedGames = [];
      return _cachedGames!;
    } finally {
      _isLoading = false;
    }
  }

  /// Fetches a specified number of games with optional shuffling
  /// Simulates pagination by returning random subsets
  Future<List<GameModel>> fetchGames({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromAsset();
      
      if (allGames.isEmpty) {
        print('[GameService] No games available');
        return [];
      }

      // Shuffle the games to provide variety
      final shuffledGames = List<GameModel>.from(allGames);
      shuffledGames.shuffle(Random());
      
      // Return the requested number of games
      final gamesToReturn = shuffledGames.take(count).toList();
      
      print('[GameService] Returning ${gamesToReturn.length} games out of ${allGames.length} total');
      return gamesToReturn;
    } catch (e) {
      print('[GameService] Error in fetchGames: $e');
      return [];
    }
  }

  /// Gets all available games without pagination
  Future<List<GameModel>> getAllGames() async {
    return await _loadGamesFromAsset();
  }

  /// Finds a specific game by its ID
  Future<GameModel?> getGameById(String gameId) async {
    try {
      final allGames = await _loadGamesFromAsset();
      return allGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => throw Exception('Game not found'),
      );
    } catch (e) {
      print('[GameService] Game with ID $gameId not found: $e');
      return null;
    }
  }

  /// Gets games filtered by genre
  Future<List<GameModel>> getGamesByGenre(String genre) async {
    try {
      final allGames = await _loadGamesFromAsset();
      return allGames.where((game) => game.genre?.toLowerCase() == genre.toLowerCase()).toList();
    } catch (e) {
      print('[GameService] Error filtering games by genre $genre: $e');
      return [];
    }
  }

  /// Gets all unique genres available in the game collection
  Future<List<String>> getAvailableGenres() async {
    try {
      final allGames = await _loadGamesFromAsset();
      final genres = allGames
          .map((game) => game.genre)
          .where((genre) => genre != null && genre.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      genres.sort(); // Sort alphabetically
      return genres;
    } catch (e) {
      print('[GameService] Error getting available genres: $e');
      return [];
    }
  }

  /// Searches games by title or description
  Future<List<GameModel>> searchGames(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllGames();
      }

      final allGames = await _loadGamesFromAsset();
      final lowercaseQuery = query.toLowerCase();
      
      return allGames.where((game) {
        return game.title.toLowerCase().contains(lowercaseQuery) ||
               game.description.toLowerCase().contains(lowercaseQuery) ||
               (game.genre?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      print('[GameService] Error searching games with query "$query": $e');
      return [];
    }
  }

  /// Clears the cached games (useful for testing or forcing reload)
  void clearCache() {
    _cachedGames = null;
    print('[GameService] Game cache cleared');
  }

  /// Gets the total number of available games
  Future<int> getTotalGameCount() async {
    final allGames = await _loadGamesFromAsset();
    return allGames.length;
  }
} 