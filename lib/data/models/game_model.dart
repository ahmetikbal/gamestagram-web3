class Game {
  final String id;
  final String title;
  final String description; // Optional: A brief description or genre

  Game({
    required this.id,
    required this.title,
    this.description = '',
  });
} 