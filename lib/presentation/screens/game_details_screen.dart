import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/game_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';
import 'game_webview_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailsScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _contentAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareGame() {
    final String gameDeepLink = 'gamestagram://game/${widget.game.id}';
    final String message = 'Check out this game: ${widget.game.title}\n$gameDeepLink';
    Share.share(message);
  }

  void _playGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameWebViewScreen(
          gameId: widget.game.id,
          gameUrl: widget.game.gameUrl!,
          gameTitle: widget.game.title,
        ),
      ),
    );
  }

  // Helper method to get appropriate icons for different game genres
  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'puzzle':
        return Icons.extension;
      case 'arcade':
        return Icons.videogame_asset;
      case 'runner':
        return Icons.directions_run;
      case 'board':
        return Icons.grid_on;
      case 'card':
        return Icons.style;
      case 'platformer':
        return Icons.filter_hdr;
      case 'rhythm':
        return Icons.music_note;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    final gameViewModel = Provider.of<GameViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final currentUser = authViewModel.currentUser;
    
    final bool isSaved = currentUser != null 
        ? gameViewModel.isGameSavedByUser(widget.game.id, currentUser.id) 
        : false;
    
    final bool isLiked = currentUser != null 
        ? gameViewModel.isGameLikedByUser(widget.game.id, currentUser.id) 
        : false;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: _shareGame,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image with gradient overlay
          SizedBox.expand(
            child: widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty
                ? Stack(
                    children: [
                      // Game image
                      Image.network(
                        widget.game.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.7),
                                  theme.colorScheme.secondary.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.videogame_asset,
                                size: 80,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.7),
                          theme.colorScheme.secondary.withOpacity(0.7),
                          theme.colorScheme.background,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.videogame_asset,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top spacer
                  SizedBox(height: size.height * 0.25),
                  
                  // Game info section with animation
                  FadeTransition(
                    opacity: _headerAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_headerAnimation),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title with shadow for better visibility
                            Text(
                              widget.game.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1, 1),
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Ratings and metrics
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Like count with heart icon
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: Colors.red.shade400,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.game.likeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Comment count with chat icon
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.blue.shade200,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.game.commentCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Playable badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sports_esports,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PLAYABLE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Genre badge (if available)
                                if (widget.game.genre != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getGenreIcon(widget.game.genre!),
                                          color: Colors.amber.shade300,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.game.genre!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Game description and details
                  FadeTransition(
                    opacity: _contentAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_contentAnimation),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section title
                            Text(
                              'About this Game',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Game description without expand/collapse
                            Container(
                              child: Text(
                                widget.game.description,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Interaction buttons row
                            Row(
                              children: [
                                // Like button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (currentUser != null) {
                                        gameViewModel.toggleLikeGame(
                                          widget.game.id, 
                                          currentUser.id
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please login to like games')),
                                        );
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isLiked 
                                            ? theme.colorScheme.primary.withOpacity(0.2) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isLiked 
                                              ? theme.colorScheme.primary 
                                              : theme.colorScheme.onSurface.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            isLiked 
                                                ? Icons.favorite 
                                                : Icons.favorite_border,
                                            color: isLiked 
                                                ? Colors.red 
                                                : theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Like',
                                            style: TextStyle(
                                              color: isLiked 
                                                  ? theme.colorScheme.primary 
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Save button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (currentUser != null) {
                                        gameViewModel.toggleSaveGame(
                                          widget.game.id, 
                                          currentUser.id
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please login to save games')),
                                        );
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSaved 
                                            ? theme.colorScheme.primary.withOpacity(0.2) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSaved 
                                              ? theme.colorScheme.primary 
                                              : theme.colorScheme.onSurface.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            isSaved 
                                                ? Icons.bookmark 
                                                : Icons.bookmark_border,
                                            color: isSaved 
                                                ? theme.colorScheme.primary 
                                                : theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Save',
                                            style: TextStyle(
                                              color: isSaved 
                                                  ? theme.colorScheme.primary 
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Share button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _shareGame,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.share,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Share',
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Play button
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 40),
                                child: ElevatedButton(
                                  onPressed: widget.game.gameUrl != null && widget.game.gameUrl!.isNotEmpty 
                                      ? _playGame 
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'PLAY NOW',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 