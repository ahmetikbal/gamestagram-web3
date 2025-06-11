import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../data/models/game_model.dart';
import '../utils/image_validator.dart';
import '../../utils/logger.dart';

/// Service for managing game data and operations
/// Loads games from JSON asset file and provides game-related functionality with image validation
class GameService {
  static List<GameModel>? _cachedGames;
  static bool _isLoading = false;
  static final Set<String> _usedGameIds = <String>{}; // Track used games to avoid duplicates

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
      AppLogger.debug('Loading games from JSON asset...', 'GameService');
      final String jsonString = await rootBundle.loadString('assets/games.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> gamesJson = jsonData['games'] as List<dynamic>;
      
      _cachedGames = gamesJson.map((gameJson) => GameModel.fromJson(gameJson as Map<String, dynamic>)).toList();
      
      AppLogger.debug('Successfully loaded ${_cachedGames!.length} games from JSON', 'GameService');
      return _cachedGames!;
    } catch (e) {
      AppLogger.error('[GameService] Error loading games from JSON: $e', 'GameService');
      // Return empty list on error
      _cachedGames = [];
      return _cachedGames!;
    } finally {
      _isLoading = false;
    }
  }

  /// Fetches games with optimized image validation and progressive loading
  /// Uses batch validation and caching to minimize lag
  Future<List<GameModel>> fetchGames({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromAsset();
      
      if (allGames.isEmpty) {
        AppLogger.debug('No games available', 'GameService');
        return [];
      }

      // Get games that haven't been used yet
      final availableGames = allGames.where((game) => !_usedGameIds.contains(game.id)).toList();
      
      // If we're running low on unused games, reset the used set (for infinite scroll)
      if (availableGames.length < count * 2) {
        AppLogger.debug('Resetting used games list to provide more variety', 'GameService');
        _usedGameIds.clear();
        availableGames.clear();
        availableGames.addAll(allGames);
      }

      // Shuffle available games
      availableGames.shuffle(Random());
      
      // NO VALIDATION - Return games directly with images
      final gamesWithImages = availableGames
          .where((game) => game.imageUrl != null && game.imageUrl!.trim().isNotEmpty)
          .take(count)
          .toList();
      
      if (gamesWithImages.isEmpty) {
        AppLogger.debug('No games with images found', 'GameService');
        return [];
      }

      AppLogger.debug('Returning ${gamesWithImages.length} games WITHOUT validation', 'GameService');
      
      // Mark games as used
      for (final game in gamesWithImages) {
          _usedGameIds.add(game.id);
      }
      
      AppLogger.debug('Total used games: ${_usedGameIds.length}', 'GameService');
      
      return gamesWithImages;
    } catch (e) {
      AppLogger.error('[GameService] Error in fetchGames: $e', 'GameService');
      return [];
    }
  }

  /// Fast fetch method that returns games immediately without any validation
  Future<List<GameModel>> fetchGamesFast({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromAsset();
      
      if (allGames.isEmpty) {
        AppLogger.debug('No games available', 'GameService');
        return [];
      }

      // Get games that haven't been used yet
      final availableGames = allGames.where((game) => !_usedGameIds.contains(game.id)).toList();
      
      if (availableGames.length < count * 2) {
        _usedGameIds.clear();
        availableGames.clear();
        availableGames.addAll(allGames);
      }

      availableGames.shuffle(Random());
      
      // NO VALIDATION - Just return games with non-empty image URLs
      final gamesWithImages = availableGames
          .where((game) => game.imageUrl != null && game.imageUrl!.trim().isNotEmpty)
          .take(count)
          .toList();
      
      // Mark games as used
      for (final game in gamesWithImages) {
          _usedGameIds.add(game.id);
      }
      
      AppLogger.debug('Fast fetch returning ${gamesWithImages.length} games without validation', 'GameService');
      
      return gamesWithImages;
    } catch (e) {
      AppLogger.error('[GameService] Error in fetchGamesFast: $e', 'GameService');
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
      AppLogger.debug('Game with ID $gameId not found: $e', 'GameService');
      return null;
    }
  }

  /// Gets games filtered by genre
  Future<List<GameModel>> getGamesByGenre(String genre) async {
    try {
      final allGames = await _loadGamesFromAsset();
      return allGames.where((game) => game.genre?.toLowerCase() == genre.toLowerCase()).toList();
    } catch (e) {
      AppLogger.error('[GameService] Error filtering games by genre $genre: $e', 'GameService');
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
      AppLogger.error('[GameService] Error getting available genres: $e', 'GameService');
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
      AppLogger.error('[GameService] Error searching games with query "$query": $e', 'GameService');
      return [];
    }
  }

  /// Clears the cached games and used games tracking (useful for testing or forcing reload)
  void clearCache() {
    _cachedGames = null;
    _usedGameIds.clear();
    ImageValidator.clearCache();
    AppLogger.debug('Game cache and used games tracking cleared', 'GameService');
  }

  /// Resets the used games tracking to allow games to be shown again
  void resetUsedGames() {
    _usedGameIds.clear();
    AppLogger.debug('Used games tracking reset', 'GameService');
  }

  /// Gets the total number of available games
  Future<int> getTotalGameCount() async {
    final allGames = await _loadGamesFromAsset();
    return allGames.length;
  }

  /// Pre-warms image cache for better performance
  /// This significantly improves scroll performance
  static Future<void> preWarmImages(List<GameModel> games) async {
    // Temporarily disable image pre-warming to prevent crashes
    AppLogger.debug('Image pre-warming disabled for stability', 'GameService');
    return;
    
    /*
    // Original pre-warming code - disabled for now
    if (games.isEmpty) return;
    
    AppLogger.debug('Pre-warming image cache with ${games.length} images...', 'GameService');
    
    int validCount = 0;
    int processedCount = 0;
    
    // Process in smaller batches to prevent overwhelming the system
    const batchSize = 10;
    for (int i = 0; i < games.length; i += batchSize) {
      final batch = games.skip(i).take(batchSize).toList();
      
      final futures = batch.map((game) async {
        processedCount++;
        if (game.imageUrl == null || game.imageUrl!.isEmpty) return false;
        
        try {
          // Try to load the image into cache
          final imageProvider = CachedNetworkImageProvider(game.imageUrl!);
          final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
          
          final Completer<bool> completer = Completer<bool>();
          late ImageStreamListener listener;
          
          listener = ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
              if (!completer.isCompleted) {
                validCount++;
                completer.complete(true);
              }
              stream.removeListener(listener);
            },
            onError: (dynamic error, StackTrace? stackTrace) {
              if (!completer.isCompleted) {
                completer.complete(false);
              }
              stream.removeListener(listener);
            },
          );
          
          stream.addListener(listener);
          
          // Timeout after 3 seconds
          return await completer.future.timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              stream.removeListener(listener);
              return false;
            },
          );
        } catch (e) {
          return false;
        }
      });
      
      await Future.wait(futures);
      
      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < games.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    AppLogger.debug('✓ Pre-warmed cache: $validCount/$processedCount images valid', 'GameService');
    */
  }
} 