import '../data/models/game_model.dart'; // Adjust path as necessary
import 'dart:math'; // For randomizing game details

class GameService {
  final Random _random = Random();

  // Mock list of potential game titles and descriptions
  final List<String> _mockTitles = [
    'Space Shooter X', 'Jungle Jump Adventure', 'Puzzle Kingdom', 'Racing Rivals',
    'Galaxy Explorer', 'Deep Sea Diver', 'Medieval Siege', 'Zombie Survival'
  ];
  final List<String> _mockDescriptions = [
    'Blast your way through alien hordes!', 'Collect bananas and avoid obstacles!',
    'Solve intricate puzzles to save the princess!', 'Compete in high-speed races!',
    'Discover new planets and civilizations.', 'Explore the ocean depths.',
    'Defend your castle from invaders.', 'Survive the apocalypse!'
  ];

  Future<List<GameModel>> fetchGames({int count = 5}) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: _random.nextInt(800) + 200));

    List<GameModel> games = [];
    for (int i = 0; i < count; i++) {
      // Create unique IDs for mock games
      String gameId = (DateTime.now().millisecondsSinceEpoch + i).toString(); 
      games.add(GameModel(
        id: gameId,
        title: _mockTitles[_random.nextInt(_mockTitles.length)],
        description: _mockDescriptions[_random.nextInt(_mockDescriptions.length)],
      ));
    }
    print('[GameService] Fetched ${games.length} mock games.');
    return games;
  }

  // Future<GameModel> fetchGameById(String id) async { ... }
  // Future<List<GameModel>> fetchTrendingGames() async { ... }
} 