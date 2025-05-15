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
final List<GameModel> webGames = [
  GameModel(
    id: 'g1',
    title: '2048 Classic',
    description: 'Swipe and merge the numbered tiles to reach 2048.',
    gameUrl: 'https://play2048.co/',
  ),
  GameModel(
    id: 'g2',
    title: 'Flappy Bird',
    description: 'Tap to guide the bird through the pipes.',
    gameUrl: 'https://flappybird.io/',
  ),
  GameModel(
    id: 'g3',
    title: 'Slope',
    description: "Roll the ball down an endless neon track—don't fall!",
    gameUrl: 'https://slope3.com/',
  ),
  GameModel(
    id: 'g4',
    title: 'Cut the Rope',
    description: 'Feed Om Nom by cutting ropes at the right moment.',
    gameUrl: 'https://www.cuttherope.net/timetravel_standalone/game.html',
  ),
  GameModel(
    id: 'g5',
    title: 'Pac-Man',
    description: 'Gobble dots, dodge ghosts, relive the arcade classic.',
    gameUrl: 'https://pacman.live/',
  ),
  GameModel(
    id: 'g6',
    title: 'Minesweeper',
    description: 'Flag all the mines using logic (no guessing!).',
    gameUrl: 'https://minesweeperonline.com/',
  ),
  GameModel(
    id: 'g7',
    title: 'Snake',
    description: "Grow the snake—but don't bite your tail.",
    gameUrl: 'https://playsnake.org/',
  ),
  GameModel(
    id: 'g8',
    title: 'Chrome Dino',
    description: 'Jump the cacti in this offline-era runner.',
    gameUrl: 'https://chromedino.com/',
  ),
  GameModel(
    id: 'g9',
    title: 'Tetris',
    description: 'Rotate and stack tetrominoes to clear lines.',
    gameUrl: 'https://tetris.com/play-tetris',
  ),
  GameModel(
    id: 'g10',
    title: 'Sudoku',
    description: 'Fill every row, column, and block with 1–9.',
    gameUrl: 'https://sudoku.com/play/',
  ),
  GameModel(
    id: 'g11',
    title: 'Lichess Blitz',
    description: 'Battle opponents in live chess matches.',
    gameUrl: 'https://lichess.org/',
  ),
  GameModel(
    id: 'g12',
    title: 'Checkers',
    description: 'Classic draughts against the computer or a friend.',
    gameUrl: 'https://cardgames.io/checkers/',
  ),
  GameModel(
    id: 'g13',
    title: 'Solitaire',
    description: 'Klondike in a single-page web app.',
    gameUrl: 'https://solitr.com/',
  ),
  GameModel(
    id: 'g14',
    title: 'Bubble Shooter',
    description: 'Match-3 bubbles to clear the board.',
    gameUrl: 'https://bubbleshooter.net/game/bubble-shooter/',
  ),
  GameModel(
    id: 'g15',
    title: 'Helix Jump',
    description: 'Fall through the gaps—avoid the colored platforms!',
    gameUrl: 'https://helixjump.io/',
  ),
  GameModel(
    id: 'g16',
    title: 'Subway Surfers',
    description: 'Dash, dodge, and collect coins in this endless runner.',
    gameUrl: 'https://subway-surfers.io/',
  ),
  GameModel(
    id: 'g17',
    title: 'Super Mario HTML5',
    description: 'Fan-made remake of the original Mario levels.',
    gameUrl: 'https://supermario-game.com/',
  ),
  GameModel(
    id: 'g18',
    title: 'Stickman Hook',
    description: 'Swing like Spider-Man to reach the goal.',
    gameUrl: 'https://stickmanhook.io/',
  ),
  GameModel(
    id: 'g19',
    title: 'Geometry Dash',
    description: 'Jump and fly through danger in rhythmic levels.',
    gameUrl: 'https://geometrydash.io/',
  ),
  GameModel(
    id: 'g20',
    title: 'Connect Four',
    description: 'Drop discs and get four in a row before your opponent.',
    gameUrl: 'https://playok.com/en/connect4/',
  ),
];


  Future<List<GameModel>> fetchGames({int count = 5}) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: _random.nextInt(800) + 200));

    // Use the predefined mock games with URLs instead of generating random ones
    print('[GameService] Using predefined mock games instead of generating random ones.');
    
    // Take a slice of the predefined mock games, or return all if count > length
    int endIndex = count < webGames.length ? count : webGames.length;
    List<GameModel> games = webGames.sublist(0, endIndex);
    
    print('[GameService] Fetched ${games.length} mock games. First game URL: ${games.isNotEmpty ? games[0].gameUrl : 'none'}');
    return games;
  }

  // Future<GameModel> fetchGameById(String id) async { ... }
  // Future<List<GameModel>> fetchTrendingGames() async { ... }
} 