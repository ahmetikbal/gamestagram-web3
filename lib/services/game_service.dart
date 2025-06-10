import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../data/models/game_model.dart';
import '../utils/image_validator.dart';

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

  /// Fetches games with optimized image validation and progressive loading
  /// Uses batch validation and caching to minimize lag
  Future<List<GameModel>> fetchGames({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromAsset();
      
      if (allGames.isEmpty) {
        print('[GameService] No games available');
        return [];
      }

      // Get games that haven't been used yet
      final availableGames = allGames.where((game) => !_usedGameIds.contains(game.id)).toList();
      
      // If we're running low on unused games, reset the used set (for infinite scroll)
      if (availableGames.length < count * 2) {
        print('[GameService] Resetting used games list to provide more variety');
        _usedGameIds.clear();
        availableGames.clear();
        availableGames.addAll(allGames);
      }

      // Shuffle available games
      availableGames.shuffle(Random());
      
      // Filter games with images and prepare for batch validation
      final gamesWithImages = availableGames
          .where((game) => game.imageUrl != null && game.imageUrl!.trim().isNotEmpty)
          .take(count * 3) // Get more games than needed to account for invalid images
          .toList();
      
      if (gamesWithImages.isEmpty) {
        print('[GameService] No games with images found');
        return [];
      }

      print('[GameService] Starting optimized validation for ${gamesWithImages.length} games...');
      
      // Extract image URLs for batch validation
      final imageUrls = gamesWithImages.map((game) => game.imageUrl!).toList();
      
      // Use batch validation for better performance
      final validationResults = await ImageValidator.validateBatchConcurrent(imageUrls);
      
      // Filter games with valid images
      final validatedGames = <GameModel>[];
      for (final game in gamesWithImages) {
        if (validationResults[game.imageUrl!] == true) {
          validatedGames.add(game);
          _usedGameIds.add(game.id);
          
          // Stop when we have enough games
          if (validatedGames.length >= count) {
            break;
          }
        }
      }
      
      print('[GameService] ✓ Validated ${validatedGames.length} games successfully');
      print('[GameService] Total used games: ${_usedGameIds.length}');
      
      return validatedGames;
    } catch (e) {
      print('[GameService] Error in fetchGames: $e');
      return [];
    }
  }

  /// Fast fetch method that prioritizes cached/known good images
  /// This method checks cache first and falls back to validation only if needed
  Future<List<GameModel>> fetchGamesFast({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromAsset();
      
      if (allGames.isEmpty) {
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
      
      final validatedGames = <GameModel>[];
      final needsValidation = <GameModel>[];
      
      // First pass: Check cached results
      for (final game in availableGames) {
        if (game.imageUrl == null || game.imageUrl!.trim().isEmpty) continue;
        
        final cachedResult = ImageValidator.getCachedResult(game.imageUrl!);
        if (cachedResult == true) {
          validatedGames.add(game);
          _usedGameIds.add(game.id);
          if (validatedGames.length >= count) break;
        } else if (cachedResult == null) {
          needsValidation.add(game);
        }
      }
      
      // If we have enough from cache, return immediately
      if (validatedGames.length >= count) {
        return validatedGames.take(count).toList();
      }
      
      // Second pass: Validate remaining images if needed
      if (needsValidation.isNotEmpty && validatedGames.length < count) {
        final remainingCount = count - validatedGames.length;
        final toValidate = needsValidation.take(remainingCount * 2).toList();
        
        final imageUrls = toValidate.map((game) => game.imageUrl!).toList();
        final validationResults = await ImageValidator.validateBatchConcurrent(imageUrls);
        
        for (final game in toValidate) {
          if (validationResults[game.imageUrl!] == true) {
            validatedGames.add(game);
            _usedGameIds.add(game.id);
            if (validatedGames.length >= count) break;
          }
        }
      }
      
      return validatedGames.take(count).toList();
    } catch (e) {
      print('[GameService] Error in fetchGamesFast: $e');
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

  /// Clears the cached games and used games tracking (useful for testing or forcing reload)
  void clearCache() {
    _cachedGames = null;
    _usedGameIds.clear();
    ImageValidator.clearCache();
    print('[GameService] Game cache and used games tracking cleared');
  }

  /// Resets the used games tracking to allow games to be shown again
  void resetUsedGames() {
    _usedGameIds.clear();
    print('[GameService] Used games tracking reset');
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
    print('[GameService] Image pre-warming disabled for stability');
    return;
    
    /*
    // Original pre-warming code - disabled for now
    if (games.isEmpty) return;
    
    print('[GameService] Pre-warming image cache with ${games.length} images...');
    
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
    
    print('[GameService] ✓ Pre-warmed cache: $validCount/$processedCount images valid');
    */
  }
} 