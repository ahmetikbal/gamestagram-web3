import 'dart:convert';
import 'package:http/http.dart' as http;

/// Utility class for extracting direct game URLs from game pages
class GameUrlExtractor {
  /// Extracts the actual game URL from a game page that might contain iframes
  static Future<String?> extractGameUrl(String pageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(pageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );
      
      if (response.statusCode == 200) {
        final html = response.body;
        
        // Look for common iframe patterns
        final iframeRegex = RegExp(r'<iframe[^>]+src=["\'](https?://[^"\']+)["\'][^>]*>');
        final match = iframeRegex.firstMatch(html);
        
        if (match != null) {
          String gameUrl = match.group(1)!;
          
          // Filter out non-game iframes (ads, widgets, etc.)
          if (_isLikelyGameUrl(gameUrl)) {
            print('Extracted game URL: $gameUrl from page: $pageUrl');
            return gameUrl;
          }
        }
        
        // Look for canvas-based games (direct HTML5)
        if (html.contains('<canvas') || html.contains('game')) {
          // The page itself contains the game
          return pageUrl;
        }
      }
    } catch (e) {
      print('Error extracting game URL from $pageUrl: $e');
    }
    
    return null;
  }
  
  /// Determines if a URL is likely to be a game URL
  static bool _isLikelyGameUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Skip common non-game iframe sources
    if (lowerUrl.contains('ads') ||
        lowerUrl.contains('analytics') ||
        lowerUrl.contains('facebook') ||
        lowerUrl.contains('twitter') ||
        lowerUrl.contains('youtube') ||
        lowerUrl.contains('disqus')) {
      return false;
    }
    
    // Common game URL patterns
    return lowerUrl.contains('game') ||
           lowerUrl.contains('play') ||
           lowerUrl.contains('html5') ||
           lowerUrl.contains('canvas') ||
           lowerUrl.contains('.swf') ||
           lowerUrl.contains('unity');
  }
  
  /// Validates if a URL loads a playable game
  static Future<bool> validateGameUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 