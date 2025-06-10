import '../data/models/game_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

enum GameOrientation {
  portrait,
  landscape,
  auto, // Let the system decide
}

class OrientationAnalysis {
  final GameOrientation recommendation;
  final double confidence; // 0.0 to 1.0
  final String reasoning;
  final bool allowUserControl;

  OrientationAnalysis({
    required this.recommendation,
    required this.confidence,
    required this.reasoning,
    required this.allowUserControl,
  });
}

class OrientationService {
  static const String _prefPrefix = 'game_orientation_';
  
  // Keywords that suggest landscape orientation
  static const List<String> _landscapeKeywords = [
    'racing', 'car', 'drive', 'flight', 'airplane', 'plane', 'helicopter',
    'side-scroller', 'platformer', 'run', 'runner', 'endless', 'subway',
    'temple run', 'geometry dash', 'mario', 'sonic', 'metroidvania',
    'shooter', 'fps', 'strategy', 'rts', 'civilization', 'age of',
    'racing', 'drift', 'rally', 'formula', 'nascar', 'motorcycle',
    'flight simulator', 'pilot', 'aircraft', 'spaceship', 'galaxy',
    'horizontal', 'landscape', 'wide', 'panoramic', 'cinematic'
  ];

  // Keywords that suggest portrait orientation  
  static const List<String> _portraitKeywords = [
    'puzzle', 'match', 'candy', 'jewel', 'gem', 'bubble', 'pop',
    'tetris', 'blocks', 'stack', 'drop', 'fall', 'cascade',
    'card', 'solitaire', 'poker', 'blackjack', 'casino',
    'tower', 'defense', 'td', 'idle', 'clicker', 'tap',
    'jump', 'hop', 'climb', 'ascent', 'vertical', 'up',
    'flappy', 'bird', 'doodle', 'temple', 'subway surfer',
    'portrait', 'tall', 'mobile', 'phone'
  ];

  // Game categories that typically work better in landscape
  static const List<String> _landscapeCategories = [
    'racing', 'action', 'adventure', 'strategy', 'simulation',
    'shooter', 'platformer', 'rpg', 'mmorpg'
  ];

  // Game categories that typically work better in portrait
  static const List<String> _portraitCategories = [
    'puzzle', 'casual', 'card', 'board', 'trivia', 'word',
    'match-3', 'arcade'
  ];

  /// Analyzes a game to determine optimal orientation
  static OrientationAnalysis analyzeGame(GameModel game) {
    double landscapeScore = 0.0;
    double portraitScore = 0.0;
    List<String> reasons = [];

    final String searchText = '${game.title} ${game.description} ${game.genre ?? ''}'.toLowerCase();

    // Keyword analysis
    for (String keyword in _landscapeKeywords) {
      if (searchText.contains(keyword)) {
        landscapeScore += 1.0;
        if (keyword.length > 4) landscapeScore += 0.5; // Longer keywords are more specific
      }
    }

    for (String keyword in _portraitKeywords) {
      if (searchText.contains(keyword)) {
        portraitScore += 1.0;
        if (keyword.length > 4) portraitScore += 0.5;
      }
    }

    // Genre analysis
    if (game.genre != null) {
      final genre = game.genre!.toLowerCase();
      for (String cat in _landscapeCategories) {
        if (genre.contains(cat)) {
          landscapeScore += 2.0; // Categories are more reliable
          reasons.add('${cat} games typically work better in landscape');
        }
      }
      for (String cat in _portraitCategories) {
        if (genre.contains(cat)) {
          portraitScore += 2.0;
          reasons.add('${cat} games typically work better in portrait');
        }
      }
    }

    // URL analysis for additional hints
    if (game.gameUrl != null) {
      final url = game.gameUrl!.toLowerCase();
      if (url.contains('mobile') || url.contains('phone')) {
        portraitScore += 1.0;
        reasons.add('Mobile-optimized games often prefer portrait');
      }
      if (url.contains('desktop') || url.contains('pc')) {
        landscapeScore += 1.0;
        reasons.add('Desktop games typically prefer landscape');
      }
    }

    // Title pattern analysis
    if (game.title.length > 20) {
      // Longer titles might suggest more complex games that benefit from landscape
      landscapeScore += 0.5;
    }

    // Determine recommendation
    final double totalScore = landscapeScore + portraitScore;
    final double confidence = totalScore > 0 ? (landscapeScore - portraitScore).abs() / totalScore : 0.0;
    
    GameOrientation recommendation;
    String reasoning;
    bool allowUserControl = true;

    if (confidence > 0.6) {
      // High confidence recommendation
      if (landscapeScore > portraitScore) {
        recommendation = GameOrientation.landscape;
        reasoning = 'Strong indicators for landscape: ${reasons.take(2).join(', ')}';
        allowUserControl = confidence < 0.8; // Very high confidence locks the orientation
      } else {
        recommendation = GameOrientation.portrait;
        reasoning = 'Strong indicators for portrait: ${reasons.take(2).join(', ')}';
        allowUserControl = confidence < 0.8;
      }
    } else if (confidence > 0.3) {
      // Medium confidence
      recommendation = landscapeScore > portraitScore ? GameOrientation.landscape : GameOrientation.portrait;
      reasoning = 'Moderate indicators suggest ${recommendation.name} orientation';
      allowUserControl = true;
    } else {
      // Low confidence - default to auto
      recommendation = GameOrientation.auto;
      reasoning = 'No clear orientation preference detected - user can choose';
      allowUserControl = true;
    }

    return OrientationAnalysis(
      recommendation: recommendation,
      confidence: confidence,
      reasoning: reasoning,
      allowUserControl: allowUserControl,
    );
  }

  /// Gets user preference for a specific game
  static Future<GameOrientation?> getUserPreference(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('${_prefPrefix}$gameId');
      if (value != null) {
        return GameOrientation.values.firstWhere((e) => e.name == value);
      }
    } catch (e) {
      AppLogger.error('[OrientationService] Error getting user preference: $e', 'OrientationService');
    }
    return null;
  }

  /// Sets user preference for a specific game
  static Future<bool> setUserPreference(String gameId, GameOrientation orientation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefPrefix}$gameId', orientation.name);
      AppLogger.debug('Saved preference for $gameId: ${orientation.name}', 'OrientationService');
      return true;
    } catch (e) {
      AppLogger.error('[OrientationService] Error saving user preference: $e', 'OrientationService');
      return false;
    }
  }

  /// Gets the final orientation decision combining analysis and user preference
  static Future<GameOrientation> getFinalOrientation(GameModel game) async {
    // First check user preference
    final userPref = await getUserPreference(game.id);
    if (userPref != null && userPref != GameOrientation.auto) {
      return userPref;
    }

    // If no user preference or set to auto, use analysis
    final analysis = analyzeGame(game);
    return analysis.recommendation;
  }

  /// Clears all user preferences (for settings/reset)
  static Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefPrefix));
      for (String key in keys) {
        await prefs.remove(key);
      }
      AppLogger.debug('Cleared all orientation preferences', 'OrientationService');
    } catch (e) {
      AppLogger.error('[OrientationService] Error clearing preferences: $e', 'OrientationService');
    }
  }
} 