import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';
import 'comment_panel_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../screens/game_details_screen.dart';

class GameFrameWidget extends StatefulWidget {
  final GameModel game;
  final VoidCallback? onPlay;

  const GameFrameWidget({Key? key, required this.game, this.onPlay}) : super(key: key);

  @override
  _GameFrameWidgetState createState() => _GameFrameWidgetState();
}

class _GameFrameWidgetState extends State<GameFrameWidget> with WidgetsBindingObserver {
  bool _isGameLoaded = false;
  bool _isGameVisible = false;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (_isGameLoaded && _controller != null) {
      _cleanupWebView();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isGameLoaded && _controller != null) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _pauseWebView();
      } else if (state == AppLifecycleState.resumed && _isGameVisible) {
        _resumeWebView();
      }
    }
  }

  void _toggleGameVisibility() {
    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    
    setState(() {
      if (!_isGameVisible) {
        // First time showing the game
        if (!_isGameLoaded) {
          _initializeWebView();
        }
        _isGameVisible = true;
        gameViewModel.setCurrentlyPlayingGame(widget.game.id);
      } else {
        // Hide the game but keep it loaded
        _isGameVisible = false;
        gameViewModel.setCurrentlyPlayingGame(null);
      }
    });
  }

  void _initializeWebView() {
    if (_isGameLoaded) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onPageFinished: (url) {
            setState(() {
              _isGameLoaded = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.game.gameUrl ?? 'about:blank'));

    _isGameLoaded = true;
  }

  void _pauseWebView() {
    if (_controller != null) {
      _controller!.runJavaScript('''
        // Pause any audio/video elements
        document.querySelectorAll('audio, video').forEach(function(el) {
          if(el && !el.paused) { el.pause(); }
        });
        
        // Attempt to pause canvas animations
        if (window.cancelAnimationFrame) {
          var id = window.requestAnimationFrame(function(){});
          while(id--) { window.cancelAnimationFrame(id); }
        }
        
        // Inform game it's paused (for games that support visibility API)
        document.hidden = true;
        if (document.dispatchEvent) {
          document.dispatchEvent(new Event('visibilitychange'));
        }
      ''');
    }
  }

  void _resumeWebView() {
    if (_controller != null) {
      _controller!.runJavaScript('''
        // Resume game visibility
        document.hidden = false;
        if (document.dispatchEvent) {
          document.dispatchEvent(new Event('visibilitychange'));
        }
      ''');
    }
  }

  void _cleanupWebView() {
    if (_controller != null) {
      _controller!.runJavaScript('''
        // Release WebGL contexts
        var canvas = document.querySelectorAll('canvas');
        canvas.forEach(function(c) {
          var gl = c.getContext('webgl') || c.getContext('experimental-webgl');
          if (gl) {
            gl.getExtension('WEBGL_lose_context')?.loseContext();
          }
        });
        
        // Clear any timeouts and intervals
        var id = window.setTimeout(function() {}, 0);
        while (id--) {
          window.clearTimeout(id);
          window.clearInterval(id);
        }
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context);
    final currentUser = authViewModel.currentUser;
    final theme = Theme.of(context);
    final onBackgroundColor = theme.colorScheme.onBackground;
    final primaryAccentColor = theme.colorScheme.primary;
    final secondaryIconColor = theme.colorScheme.onSurface.withOpacity(0.7);

    // Get global full view state
    final bool isGlobalFullView = gameViewModel.isGlobalFullViewEnabled;

    // Check if game is saved
    final bool isSaved = currentUser != null ? 
      gameViewModel.isGameSavedByUser(widget.game.id, currentUser.id) : false;

    void _shareGame() {
      final String gameDeepLink = 'gamestagram://game/${widget.game.id}';
      final String message = 'Check out this game: ${widget.game.title}\n$gameDeepLink';
      
      Share.share(message);
    }

    // Background for the card with game image or placeholder
    Widget backgroundLayer() {
      return Container(
        decoration: BoxDecoration(
          image: widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(widget.game.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: isGlobalFullView 
                      ? null 
                      : ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                )
              : null,
          gradient: widget.game.imageUrl == null || widget.game.imageUrl!.isEmpty
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.7),
                    theme.colorScheme.secondary.withOpacity(0.7),
                  ],
                )
              : null,
        ),
        child: widget.game.imageUrl == null || widget.game.imageUrl!.isEmpty
            ? Center(
                child: Icon(
                  Icons.videogame_asset,
                  size: 80,
                  color: theme.colorScheme.onPrimary.withOpacity(0.3),
                ),
              )
            : null,
      );
    }
    
    // Game content - WebView when visible, otherwise nothing
    Widget gameLayer() {
      if (!_isGameVisible || !_isGameLoaded || _controller == null) {
        return const SizedBox.shrink();
      }
      
      return WebViewWidget(controller: _controller!);
    }

    // UI overlay with information and buttons
    Widget uiLayer() {
      return Stack(
        children: [
          // Information overlay (only visible when game is not visible and not in full view)
          if (!_isGameVisible && !isGlobalFullView)
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.game.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.game.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _toggleGameVisibility,
                      icon: Icon(Icons.play_circle_outline, color: theme.colorScheme.onPrimary),
                      label: Text(
                        'Play Game',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Modern "Playable" badge with animation
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.85),
                    theme.colorScheme.secondary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated game controller icon
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Transform.rotate(
                        angle: 0.1 * value * math.sin(value * 5),
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PLAYABLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Control buttons at top
          Positioned(
            top: 10,
            left: 10,
            child: Row(
              children: [
                // Enhanced global full view toggle button (only when game is not playing)
                if (!_isGameVisible)
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          gameViewModel.toggleGlobalFullView();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isGlobalFullView 
                                ? theme.colorScheme.secondary.withOpacity(0.85) 
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: Icon(
                              isGlobalFullView 
                                ? Icons.visibility_outlined 
                                : Icons.fullscreen_rounded,
                              key: ValueKey<bool>(isGlobalFullView),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                                    // Enhanced close/pause game button (only when game is visible)
                if (_isGameVisible)
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _toggleGameVisibility,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Game details button (when game is not visible)
                if (!_isGameVisible)
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Navigate to game details screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameDetailsScreen(game: widget.game),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Social interaction buttons
          Positioned(
            right: 10,
            bottom: 10, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<GameViewModel>(
                  builder: (context, gvm, child) {
                    bool isLiked = gvm.isGameLikedByUser(widget.game.id, currentUser?.id);
                    int currentLikeCount = gvm.getGameLikeCount(widget.game.id);
                    return Column(
                      children: [
                        // Modern Like button with animation
                        GestureDetector(
                          onTap: () {
                            if (currentUser != null) {
                              Provider.of<GameViewModel>(context, listen: false).toggleLikeGame(widget.game.id, currentUser.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please login to like games')),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLiked ? primaryAccentColor.withOpacity(0.9) : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isLiked ? primaryAccentColor.withOpacity(0.5) : Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLikeCount.toString(), 
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 16),
                // Modern Comment button
                GestureDetector(
                  onTap: () {
                    if (_isGameVisible) {
                      _pauseWebView();
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext bc) {
                        return CommentPanelWidget(game: widget.game);
                      },
                    ).then((_) {
                      // Resume the game when comments are closed if it was visible
                      if (_isGameVisible) {
                        _resumeWebView();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded, 
                      color: Colors.white, 
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Modern Share button
                GestureDetector(
                  onTap: _shareGame,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.share_rounded, 
                      color: Colors.white, 
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Modern Save button with animation
                GestureDetector(
                  onTap: () {
                    if (currentUser != null) {
                      Provider.of<GameViewModel>(context, listen: false)
                          .toggleSaveGame(widget.game.id, currentUser.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please login to save games')),
                      );
                    }
                  }, 
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSaved ? primaryAccentColor.withOpacity(0.9) : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSaved ? primaryAccentColor.withOpacity(0.5) : Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, 
                      color: Colors.white, 
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      );
    }

    // Return the combined container with all layers
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background layer (image or gradient)
          backgroundLayer(),
          
          // Game layer (WebView when visible)
          gameLayer(),
          
          // UI layer (controls and info)
          uiLayer(),
        ],
      ),
    );
  }
}