import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';

class GameFrameWidget extends StatelessWidget {
  final GameModel game;

  const GameFrameWidget({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.primaries[int.parse(game.id) % Colors.primaries.length]
            .withOpacity(0.3),
      ),
      margin: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Game ID: ${game.id}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (game.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<GameViewModel>(
                  builder: (context, gvm, child) {
                    return Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            game.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                            color: game.isLikedByCurrentUser ? Colors.red : Colors.grey[700],
                            size: 30,
                          ),
                          onPressed: () {
                            if (currentUser != null) {
                              Provider.of<GameViewModel>(context, listen: false).toggleLikeGame(game.id, currentUser.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please login to like games')),
                              );
                            }
                          },
                          tooltip: 'Like',
                        ),
                        Text(game.likeCount.toString(), style: TextStyle(color: Colors.grey[700])),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 12),
                IconButton(icon: Icon(Icons.comment_outlined, color: Colors.grey[700], size: 30), onPressed: () { print('Comment tapped for ${game.id}'); }, tooltip: 'Comment'),
                const SizedBox(height: 12),
                IconButton(icon: Icon(Icons.share_outlined, color: Colors.grey[700], size: 30), onPressed: () { print('Share tapped for ${game.id}'); }, tooltip: 'Share'),
                const SizedBox(height: 12),
                IconButton(icon: Icon(Icons.bookmark_border_outlined, color: Colors.grey[700], size: 30), onPressed: () { print('Save tapped for ${game.id}'); }, tooltip: 'Save'),
              ],
            ),
          )
        ],
      ),
    );
  }
}