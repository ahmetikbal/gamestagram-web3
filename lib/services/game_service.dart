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
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/JMNWaZel_qg7OfvvMbLdIGs1P5hNJqcr9CIMLZfoXtgLyUjBtvdHPMnCWbD8jZ7SsA=w480-h960-rw',
  ),
  GameModel(
    id: 'g2',
    title: 'Flappy Bird',
    description: 'Tap to guide the bird through the pipes.',
    gameUrl: 'https://flappybird.io/',
    genre: 'Arcade',
    imageUrl: 'https://play-lh.googleusercontent.com/8-uBOtSswDT1wDr1y3CWoBAG8j8nIXN6Ji40GHYkLfMvVYhfD-wZ8vWRwZfVAF0jYSE=w480-h960-rw',
  ),
  GameModel(
    id: 'g3',
    title: 'Slope',
    description: "Roll the ball down an endless neon track—don't fall!",
    gameUrl: 'https://slope3.com/',
    genre: 'Arcade',
    imageUrl: 'https://play-lh.googleusercontent.com/uJn2i9h7KxYQarC_c6DPMK1_xpK8BgPqXWdwY5aTZTjcsa5KYH7oLyK5h_zWiNKoOw=w480-h960-rw',
  ),
  GameModel(
    id: 'g4',
    title: 'Cut the Rope',
    description: 'Feed Om Nom by cutting ropes at the right moment.',
    gameUrl: 'https://www.cuttherope.net/timetravel_standalone/game.html',
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/8FNcAyLXtQB_0Ux2ZO8VZoEoihL6a5VMBNf6V2lydRM24hXLnNUdlEup1d5miVjl3JY=w480-h960-rw',
  ),
  GameModel(
    id: 'g5',
    title: 'Pac-Man',
    description: 'Gobble dots, dodge ghosts, relive the arcade classic.',
    gameUrl: 'https://pacman.live/',
    genre: 'Arcade',
    imageUrl: 'https://play-lh.googleusercontent.com/Oi2jC8-z3CZE5sKNHJ23buxxAQa0Ysznv_2jxPNGGJvAFOnY9IgCEu8yAEKzYgAcVQ=w480-h960-rw',
  ),
  GameModel(
    id: 'g6',
    title: 'Minesweeper',
    description: 'Flag all the mines using logic (no guessing!).',
    gameUrl: 'https://minesweeperonline.com/',
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/PfcQyztDQcJLvHLB_lLD4JjQNXn6fWEGK04k1mwRsOFZaR9pDr-7SOlTCMPWrG9BSqw=w480-h960-rw',
  ),
  GameModel(
    id: 'g7',
    title: 'Snake',
    description: "Grow the snake—but don't bite your tail.",
    gameUrl: 'https://playsnake.org/',
    genre: 'Arcade',
    imageUrl: 'https://play-lh.googleusercontent.com/GpP5oD5vKT0yaDSKdQYydLvQrjHkI1jB6AkLKGzZqKz0jCwdWjfB0IMDBbcrEMDKQ8s=w480-h960-rw',
  ),
  GameModel(
    id: 'g8',
    title: 'Chrome Dino',
    description: 'Jump the cacti in this offline-era runner.',
    gameUrl: 'https://chromedino.com/',
    genre: 'Runner',
    imageUrl: 'https://play-lh.googleusercontent.com/9nOm2lXYVpb-sHMEperEuKu_0O7yqBsvvRlYZ-xTe0wShm_iJxAkEroEzuQQEfjXVqw=w480-h960-rw',
  ),
  GameModel(
    id: 'g9',
    title: 'Tetris',
    description: 'Rotate and stack tetrominoes to clear lines.',
    gameUrl: 'https://tetris.com/play-tetris',
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/za2Nu_qjMw5GzWfbzet4zeiZT1vziVUJRiMbKoeiWv0MlgiJEMIqXkiBNK3de-aExYLq=w480-h960-rw',
  ),
  GameModel(
    id: 'g10',
    title: 'Sudoku',
    description: 'Fill every row, column, and block with 1–9.',
    gameUrl: 'https://sudoku.com/play/',
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/E8T4K54MxLTCOCXALCOJEv_SuWQZMUqXuiw8rA2RjKgWjscC3SdqLJQJUJdZHDKf8d4=w480-h960-rw',
  ),
  GameModel(
    id: 'g11',
    title: 'Lichess Blitz',
    description: 'Battle opponents in live chess matches.',
    gameUrl: 'https://lichess.org/',
    genre: 'Board',
    imageUrl: 'https://play-lh.googleusercontent.com/Fes8YnykLMY1DwzOCr9Nb3FH7JpFRX_nLVmTIpFQQUEgznM6P3LXfWe4L3Jd7-qxvnc=w480-h960-rw',
  ),
  GameModel(
    id: 'g12',
    title: 'Checkers',
    description: 'Classic draughts against the computer or a friend.',
    gameUrl: 'https://cardgames.io/checkers/',
    genre: 'Board',
    imageUrl: 'https://play-lh.googleusercontent.com/qI-Ng8-a-vyA4z_HqjJkfY1rwTJKIpvZHf2kzFTBYC-Q8XlZhrEXC-4dR0bZRYPVltI=w480-h960-rw',
  ),
  GameModel(
    id: 'g13',
    title: 'Solitaire',
    description: 'Klondike in a single-page web app.',
    gameUrl: 'https://solitr.com/',
    genre: 'Card',
    imageUrl: 'https://play-lh.googleusercontent.com/V-lvUzA-sCiuZ2hQSGY8a220SPYHwjG6PUJqQZmyfdM-hv3gXzs9M8YeaA9MDzOJL4Y=w480-h960-rw',
  ),
  GameModel(
    id: 'g14',
    title: 'Bubble Shooter',
    description: 'Match-3 bubbles to clear the board.',
    gameUrl: 'https://bubbleshooter.net/game/bubble-shooter/',
    genre: 'Puzzle',
    imageUrl: 'https://play-lh.googleusercontent.com/8oaW_WQRLDBu6jWTg49GkYYHSrXD2Y8J6elDYJPOC4rUAGXU1wLvBGQSVLDc2rmGHg=w480-h960-rw',
  ),
  GameModel(
    id: 'g15',
    title: 'Helix Jump',
    description: 'Fall through the gaps—avoid the colored platforms!',
    gameUrl: 'https://helixjump.io/',
    genre: 'Arcade',
    imageUrl: 'https://play-lh.googleusercontent.com/cRrILzwT0xfHNWsz9nTfbTRmIEh-0CJO6xPkQQBdOlXrQeknG9-u1EzWNXNrUgh0UBY=w480-h960-rw',
  ),
  GameModel(
    id: 'g16',
    title: 'Subway Surfers',
    description: 'Dash, dodge, and collect coins in this endless runner.',
    gameUrl: 'https://subway-surfers.io/',
    genre: 'Runner',
    imageUrl: 'https://play-lh.googleusercontent.com/SRumRM69YTVoZJGQ_arGhOGmvxILAJTv5UwWmDqK5ZXJe-GY9iKR2JE5xi1zpVKsgKs=w480-h960-rw',
  ),
  GameModel(
    id: 'g17',
    title: 'Super Mario HTML5',
    description: 'Fan-made remake of the original Mario levels.',
    gameUrl: 'https://supermario-game.com/',
    genre: 'Platformer',
    imageUrl: 'https://play-lh.googleusercontent.com/Vz0GfMdDE4ijwBm9oK0Ijd8xYWGbsiAJ9YKXfRTnZPSggNJw7mvMZ1x4nXRCPDnwVQ=w480-h960-rw',
  ),
  GameModel(
    id: 'g18',
    title: 'Stickman Hook',
    description: 'Swing like Spider-Man to reach the goal.',
    gameUrl: 'https://stickmanhook.io/',
    genre: 'Platformer',
    imageUrl: 'https://play-lh.googleusercontent.com/RqTWPYi-aGpuUbNlMJZLrLUKj9OUMv6IWXsIFl5kWu0Fl_Km5mM5eMEzGzdYnKC-O2A=w480-h960-rw',
  ),
  GameModel(
    id: 'g19',
    title: 'Geometry Dash',
    description: 'Jump and fly through danger in rhythmic levels.',
    gameUrl: 'https://geometrydash.io/',
    genre: 'Rhythm',
    imageUrl: 'https://play-lh.googleusercontent.com/-79d2S-9dUUoNMOLQgGRvB9oGH0Y0jGX5CV-iq3Pd0EIrG2N5b2DZl-9jHRZGRK2XxM=w480-h960-rw',
  ),
  GameModel(
    id: 'g20',
    title: 'Connect Four',
    description: 'Drop discs and get four in a row before your opponent.',
    gameUrl: 'https://playok.com/en/connect4/',
    genre: 'Board',
    imageUrl: 'https://play-lh.googleusercontent.com/S6oOavK-Qur1BAGZXmtmVsDFMGP5uaB7dws0m2frDH8nVsL0cZGTKIF-EwevXuKQKQ=w480-h960-rw',
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