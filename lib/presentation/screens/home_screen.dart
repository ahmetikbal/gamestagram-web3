import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/game_frame_widget.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';
import 'profile_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final ScrollPhysics _scrollPhysics = const BouncingScrollPhysics();
  int _lastFetchIndex = -1; // Track last index where we triggered a fetch

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameViewModel>(context, listen: false).loadInitialGames();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context);
    final user = authViewModel.currentUser;
    final theme = Theme.of(context);
    
    // Check if a game is currently being played
    final bool isGamePlaying = gameViewModel.currentlyPlayingGameId != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Optimized background decoration - moved to RepaintBoundary for better performance
          RepaintBoundary(
            child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.secondary.withValues(alpha: 0.25),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Top left decorative element
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Bottom right decorative element
                Positioned(
                  bottom: -100,
                  right: -50,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ],
                ),
            ),
          ),

          // Main content
          Consumer<GameViewModel>(
            builder: (context, gvm, child) {
              if (gvm.isLoading && gvm.games.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (gvm.errorMessage != null && gvm.games.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${gvm.errorMessage}'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => gvm.loadInitialGames(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                );
              }
              if (gvm.games.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No games available right now. Try again later!'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => gvm.loadInitialGames(),
                        child: const Text('Refresh Games'),
                      )
                    ],
                  ),
                );
              }

              // Determine scroll physics based on whether a game is currently playing
              final effectiveScrollPhysics = isGamePlaying 
                  ? const NeverScrollableScrollPhysics() // Disable scrolling when game is playing
                  : _scrollPhysics;
                  
              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: effectiveScrollPhysics,
                itemCount: gvm.games.length + (gvm.isLoading && gvm.games.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == gvm.games.length && gvm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // IMPROVED: Better guard against infinite loading
                  if (index >= gvm.games.length - 2 && 
                      !gvm.isLoading && 
                      gvm.hasMoreGames && 
                      index != _lastFetchIndex) {
                    
                    _lastFetchIndex = index; // Remember this index to prevent duplicate calls
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        print('DEBUG: Triggering fetchMoreGames at index $index, total games: ${gvm.games.length}');
                        Provider.of<GameViewModel>(context, listen: false).fetchMoreGames();
                      }
                    });
                  }
                  
                  return RepaintBoundary(
                    child: GameFrameWidget(game: gvm.games[index]),
                  );
                },
              );
            },
          ),
          
          // User profile info in bottom left corner
          if (user != null && !isGamePlaying) // Only show when not playing a game
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}