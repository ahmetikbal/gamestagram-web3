import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';
import '../screens/game_webview_screen.dart';
import 'comment_panel_widget.dart';

class GameFrameWidget extends StatelessWidget {
  final GameModel game;

  const GameFrameWidget({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;
    final theme = Theme.of(context);
    final onBackgroundColor = theme.colorScheme.onBackground;
    final primaryAccentColor = theme.colorScheme.primary;
    final secondaryIconColor = theme.colorScheme.onSurface.withOpacity(0.7);

    // Debug: Check if game has URL
    print('Building GameFrameWidget for ${game.title}, gameUrl: ${game.gameUrl}');

    Widget content = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.surface.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12.0),
        color: theme.scaffoldBackgroundColor.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ]
      ),
      margin: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          // Overlay a "Play Game" gradient banner if this game has a URL
          if (game.gameUrl != null && game.gameUrl!.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videogame_asset, color: theme.colorScheme.onPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Playable',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  game.title,
                  style: theme.textTheme.titleLarge?.copyWith(color: onBackgroundColor),
                ),
                const SizedBox(height: 8),
                Text(
                  game.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: onBackgroundColor.withOpacity(0.8)),
                ),
                
                // Add a play button indicator if the game has a URL
                if (game.gameUrl != null && game.gameUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline, color: theme.colorScheme.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Play Game',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    bool isLiked = gvm.isGameLikedByUser(game.id, currentUser?.id);
                    int currentLikeCount = gvm.getGameLikeCount(game.id);
                    return Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? primaryAccentColor : secondaryIconColor,
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
                        Text(currentLikeCount.toString(), style: TextStyle(color: secondaryIconColor, fontSize: 12)),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 12),
                IconButton(
                  icon: Icon(Icons.comment_outlined, color: secondaryIconColor, size: 30),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext bc) {
                        return CommentPanelWidget(game: game);
                      },
                    );
                  },
                  tooltip: 'Comment',
                ),
                const SizedBox(height: 12),
                IconButton(icon: Icon(Icons.share_outlined, color: secondaryIconColor, size: 30), onPressed: () { print('Share tapped for ${game.id}'); }, tooltip: 'Share'),
                const SizedBox(height: 12),
                IconButton(icon: Icon(Icons.bookmark_border_outlined, color: secondaryIconColor, size: 30), onPressed: () { print('Save tapped for ${game.id}'); }, tooltip: 'Save'),
              ],
            ),
          )
        ],
      ),
    );

    if (game.gameUrl != null && game.gameUrl!.isNotEmpty) {
      return InkWell(
        onTap: () {
          print('Game widget tapped! Navigating to WebView for game: ${game.title}, URL: ${game.gameUrl}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameWebViewScreen(
                gameUrl: game.gameUrl!,
                gameTitle: game.title,
              ),
            ),
          );
        },
        child: content,
      );
    } else {
      return content;
    }
  }
}