import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/game_model.dart';
import '../../utils/logger.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Service for managing game data and operations
/// Loads games from Firebase Firestore and provides game-related functionality
class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static List<GameModel>? _cachedGames;
  static bool _isLoading = false;
  static final Set<String> _usedGameIds = <String>{}; // Track used games to avoid duplicates

  // Collection reference
  CollectionReference get _gamesCollection => _firestore.collection('Games');

  /// Loads all games from Firebase Firestore
  /// Uses caching to avoid repeated network calls
  Future<List<GameModel>> _loadGamesFromFirebase() async {
    if (_cachedGames != null) {
      AppLogger.debug('Returning ${_cachedGames!.length} cached games', 'GameService');
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
      AppLogger.debug('Loading games from Firebase...', 'GameService');
      
      final QuerySnapshot querySnapshot = await _gamesCollection.get();
      AppLogger.debug('Firebase query completed. Found ${querySnapshot.docs.length} documents', 'GameService');
      
      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('No games found in Firebase Games collection!', 'GameService');
        _cachedGames = [];
        return _cachedGames!;
      }
      
      _cachedGames = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        AppLogger.debug('Processing game: ${data['title'] ?? 'Unknown'} (ID: ${doc.id})', 'GameService');
        return GameModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          gameUrl: data['gameUrl'],
          genre: data['genre'],
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLikedByCurrentUser: false, // Will be updated by GameViewModel
          isSavedByCurrentUser: false, // Will be updated by GameViewModel
        );
      }).toList();
      
      AppLogger.info('Successfully loaded ${_cachedGames!.length} games from Firebase', 'GameService');
      return _cachedGames!;
    } catch (e) {
      AppLogger.error('Error loading games from Firebase: $e', 'GameService');
      // Return empty list on error
      _cachedGames = [];
      return _cachedGames!;
    } finally {
      _isLoading = false;
    }
  }

  /// Fetches games from Firebase with pagination support
  Future<List<GameModel>> fetchGames({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromFirebase();
      
      if (allGames.isEmpty) {
        AppLogger.debug('No games available from Firebase', 'GameService');
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
      
      // Filter games with valid data
      final validGames = availableGames
          .where((game) => 
              game.id.isNotEmpty) // Only require ID to be present
          .take(count)
          .toList();
      
      if (validGames.isEmpty) {
        AppLogger.debug('No valid games found in Firebase', 'GameService');
        return [];
      }

      AppLogger.debug('Returning ${validGames.length} games from Firebase', 'GameService');
      
      // Mark games as used
      for (final game in validGames) {
        _usedGameIds.add(game.id);
      }
      
      AppLogger.debug('Total used games: ${_usedGameIds.length}', 'GameService');
      
      return validGames;
    } catch (e) {
      AppLogger.error('Error in fetchGames: $e', 'GameService');
      return [];
    }
  }

  /// Fast fetch method that returns games immediately from Firebase
  Future<List<GameModel>> fetchGamesFast({int count = 10}) async {
    try {
      final allGames = await _loadGamesFromFirebase();
      
      if (allGames.isEmpty) {
        AppLogger.debug('No games available from Firebase', 'GameService');
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
      
      // Filter games with valid data
      final validGames = availableGames
          .where((game) => 
              game.id.isNotEmpty) // Only require ID to be present
          .take(count)
          .toList();
      
      // Mark games as used
      for (final game in validGames) {
        _usedGameIds.add(game.id);
      }
      
      AppLogger.debug('Fast fetch returning ${validGames.length} games from Firebase', 'GameService');
      
      return validGames;
    } catch (e) {
      AppLogger.error('Error in fetchGamesFast: $e', 'GameService');
      return [];
    }
  }

  /// Gets all available games from Firebase without pagination
  Future<List<GameModel>> getAllGames() async {
    return await _loadGamesFromFirebase();
  }

  /// Finds a specific game by its ID from Firebase
  Future<GameModel?> getGameById(String gameId) async {
    try {
      final DocumentSnapshot doc = await _gamesCollection.doc(gameId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return GameModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          gameUrl: data['gameUrl'],
          genre: data['genre'],
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLikedByCurrentUser: false,
          isSavedByCurrentUser: false,
        );
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Game with ID $gameId not found in Firebase: $e', 'GameService');
      return null;
    }
  }

  /// Gets games filtered by genre from Firebase
  Future<List<GameModel>> getGamesByGenre(String genre) async {
    try {
      final QuerySnapshot querySnapshot = await _gamesCollection
          .where('genre', isEqualTo: genre)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GameModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          gameUrl: data['gameUrl'],
          genre: data['genre'],
          likeCount: data['likeCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          isLikedByCurrentUser: false,
          isSavedByCurrentUser: false,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error filtering games by genre $genre from Firebase: $e', 'GameService');
      return [];
    }
  }

  /// Gets all unique genres available in Firebase
  Future<List<String>> getAvailableGenres() async {
    try {
      final QuerySnapshot querySnapshot = await _gamesCollection.get();
      final genres = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['genre'])
          .where((genre) => genre != null && genre.toString().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      genres.sort(); // Sort alphabetically
      return genres;
    } catch (e) {
      AppLogger.error('Error getting available genres from Firebase: $e', 'GameService');
      return [];
    }
  }

  /// Searches games by title or description in Firebase
  Future<List<GameModel>> searchGames(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllGames();
      }

      final allGames = await _loadGamesFromFirebase();
      final searchQuery = query.toLowerCase();
      
      return allGames.where((game) {
        return game.title.toLowerCase().contains(searchQuery) ||
               game.description.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      AppLogger.error('Error searching games in Firebase: $e', 'GameService');
      return [];
    }
  }

  /// Adds a new game to Firebase
  Future<bool> addGame(GameModel game) async {
    try {
      await _gamesCollection.add({
        'title': game.title,
        'description': game.description,
        'imageUrl': game.imageUrl,
        'gameUrl': game.gameUrl,
        'genre': game.genre,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache to force reload
      _cachedGames = null;
      
      AppLogger.info('Successfully added game to Firebase: ${game.title}', 'GameService');
      return true;
    } catch (e) {
      AppLogger.error('Error adding game to Firebase: $e', 'GameService');
      return false;
    }
  }

  /// Updates an existing game in Firebase
  Future<bool> updateGame(GameModel game) async {
    try {
      await _gamesCollection.doc(game.id).update({
        'title': game.title,
        'description': game.description,
        'imageUrl': game.imageUrl,
        'gameUrl': game.gameUrl,
        'genre': game.genre,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache to force reload
      _cachedGames = null;
      
      AppLogger.info('Successfully updated game in Firebase: ${game.title}', 'GameService');
      return true;
    } catch (e) {
      AppLogger.error('Error updating game in Firebase: $e', 'GameService');
      return false;
    }
  }

  /// Deletes a game from Firebase
  Future<bool> deleteGame(String gameId) async {
    try {
      await _gamesCollection.doc(gameId).delete();
      
      // Clear cache to force reload
      _cachedGames = null;
      
      AppLogger.info('Successfully deleted game from Firebase: $gameId', 'GameService');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting game from Firebase: $e', 'GameService');
      return false;
    }
  }

  /// Increments play count for a game
  Future<void> incrementPlayCount(String gameId) async {
    try {
      await _gamesCollection.doc(gameId).update({
        'playCount': FieldValue.increment(1),
      });
      
      AppLogger.debug('Incremented play count for game: $gameId', 'GameService');
    } catch (e) {
      AppLogger.error('Error incrementing play count: $e', 'GameService');
    }
  }

  /// Clears the game cache to force reload from Firebase
  void clearCache() {
    _cachedGames = null;
    _usedGameIds.clear();
    AppLogger.debug('Game cache cleared', 'GameService');
  }

  /// Migrates games from local JSON to Firebase (one-time setup)
  Future<bool> migrateGamesFromJsonToFirebase() async {
    try {
      AppLogger.info('Starting migration of games from JSON to Firebase...', 'GameService');
      
      // Load from local JSON first
      final String jsonString = await rootBundle.loadString('assets/games.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> gamesJson = jsonData['games'] as List<dynamic>;
      
      AppLogger.info('Found ${gamesJson.length} games in JSON file', 'GameService');
      
      // Check if Firebase already has games
      final QuerySnapshot existingGames = await _gamesCollection.limit(1).get();
      if (existingGames.docs.isNotEmpty) {
        AppLogger.warning('Firebase already contains games. Skipping migration.', 'GameService');
        return false;
      }
      
      // Batch write to Firebase
      final WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int totalMigrated = 0;
      
      for (final gameJson in gamesJson) {
        final gameData = gameJson as Map<String, dynamic>;
        
        // Create document reference
        final docRef = _gamesCollection.doc();
        
        // Prepare data for Firebase
        final firebaseData = {
          'title': gameData['title'] ?? '',
          'description': gameData['description'] ?? '',
          'imageUrl': gameData['imageUrl'],
          'gameUrl': gameData['gameUrl'],
          'genre': gameData['genre'],
          'likeCount': 0,
          'commentCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        batch.set(docRef, firebaseData);
        batchCount++;
        
        // Firestore batch limit is 500 operations
        if (batchCount >= 400) {
          await batch.commit();
          totalMigrated += batchCount;
          AppLogger.info('Migrated $totalMigrated games so far...', 'GameService');
          batchCount = 0;
          
          // Small delay to avoid overwhelming Firebase
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // Commit remaining games
      if (batchCount > 0) {
        await batch.commit();
        totalMigrated += batchCount;
      }
      
      AppLogger.info('Migration complete! Migrated $totalMigrated games to Firebase', 'GameService');
      
      // Clear cache to force reload
      clearCache();
      
      return true;
    } catch (e) {
      AppLogger.error('Error migrating games to Firebase: $e', 'GameService');
      return false;
    }
  }
} 