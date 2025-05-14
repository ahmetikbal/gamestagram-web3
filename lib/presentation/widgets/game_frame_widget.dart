import 'package:flutter/material.dart';
import '../../data/models/game_model.dart'; // Adjust import path as needed

class GameFrameWidget extends StatelessWidget {
  final Game game;

  const GameFrameWidget({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.primaries[int.parse(game.id) % Colors.primaries.length]
            .withOpacity(0.3), // Give different background for visual cue
      ),
      margin: const EdgeInsets.all(8.0),
      child: Stack( // Use Stack to overlay buttons
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game ID: ${game.id}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                game.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (game.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    game.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          // Overlay for social interaction buttons
          Positioned(
            right: 10,
            bottom: 10, // Adjust position as needed, or center vertically
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () { print('Like tapped for ${game.id}'); }, tooltip: 'Like'),
                // Text('0'), // Placeholder for like count
                const SizedBox(height: 8),
                IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () { print('Comment tapped for ${game.id}'); }, tooltip: 'Comment'),
                // Text('0'), // Placeholder for comment count
                const SizedBox(height: 8),
                IconButton(icon: const Icon(Icons.share_outlined), onPressed: () { print('Share tapped for ${game.id}'); }, tooltip: 'Share'),
                const SizedBox(height: 8),
                IconButton(icon: const Icon(Icons.bookmark_border_outlined), onPressed: () { print('Save tapped for ${game.id}'); }, tooltip: 'Save'),
              ],
            ),
          )
        ],
      ),
    );
  }
} 