import 'dart:isolate';

/// Helper class for running heavy operations in isolates to prevent main thread blocking
class IsolateHelper {
  
  /// Process games data in a background isolate
  static Future<List<Map<String, dynamic>>> processGamesInIsolate(
    List<Map<String, dynamic>> rawGamesData,
    int maxCount,
  ) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _processGamesIsolate,
      {
        'sendPort': receivePort.sendPort,
        'gamesData': rawGamesData,
        'maxCount': maxCount,
      },
    );
    
    final result = await receivePort.first as List<Map<String, dynamic>>;
    return result;
  }
  
  /// Isolate function for processing games
  static void _processGamesIsolate(Map<String, dynamic> params) {
    final sendPort = params['sendPort'] as SendPort;
    final gamesData = params['gamesData'] as List<Map<String, dynamic>>;
    final maxCount = params['maxCount'] as int;
    
    try {
      final processedGames = <Map<String, dynamic>>[];
      
      for (int i = 0; i < gamesData.length && processedGames.length < maxCount; i++) {
        final gameData = gamesData[i];
        
        // Basic validation and processing
        if (gameData['title']?.toString().isNotEmpty == true &&
            gameData['description']?.toString().isNotEmpty == true &&
            gameData['id']?.toString().isNotEmpty == true) {
          
          final processedGame = Map<String, dynamic>.from(gameData);
          processedGame['likeCount'] = 0;
          processedGame['commentCount'] = 0;
          processedGame['isLikedByCurrentUser'] = false;
          processedGame['isSavedByCurrentUser'] = false;
          
          processedGames.add(processedGame);
        }
      }
      
      sendPort.send(processedGames);
    } catch (e) {
      sendPort.send(<Map<String, dynamic>>[]);
    }
  }
  
  /// Process image URLs for validation in background
  static Future<List<String>> validateImageUrlsInIsolate(List<String> imageUrls) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _validateImageUrlsIsolate,
      {
        'sendPort': receivePort.sendPort,
        'imageUrls': imageUrls,
      },
    );
    
    final result = await receivePort.first as List<String>;
    return result;
  }
  
  /// Isolate function for validating image URLs
  static void _validateImageUrlsIsolate(Map<String, dynamic> params) {
    final sendPort = params['sendPort'] as SendPort;
    final imageUrls = params['imageUrls'] as List<String>;
    
    try {
      final validUrls = <String>[];
      
      for (final url in imageUrls) {
        // Basic URL validation
        if (url.isNotEmpty && 
            (url.startsWith('http') || url.startsWith('assets/'))) {
          validUrls.add(url);
        }
      }
      
      sendPort.send(validUrls);
    } catch (e) {
      sendPort.send(<String>[]);
    }
  }
} 