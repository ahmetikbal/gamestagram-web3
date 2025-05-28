import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';

class GameWebViewScreen extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;
  final String gameId;

  const GameWebViewScreen({
    Key? key,
    required this.gameUrl,
    required this.gameTitle,
    required this.gameId,
  }) : super(key: key);

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  String? _loadingError;
  bool _triedFallback = false;
  bool _isPaused = false;

  /// Loads a simple HTML5 game (circle clicker) when external URLs fail
  void _loadFallbackGame() {
    if (_triedFallback) return;

    _triedFallback = true;
    print('Loading fallback HTML game');

    // Simple clicker game HTML
    const String fallbackGameHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 20px; font-family: Arial, sans-serif; text-align: center; 
                 background-color: #121212; color: white; touch-action: manipulation; }
          #game-area { margin: 20px auto; position: relative; width: 300px; height: 300px; 
                      border: 2px solid #444; border-radius: 8px; overflow: hidden; }
          .target { position: absolute; width: 30px; height: 30px; background-color: #ff4081;
                   border-radius: 50%; cursor: pointer; }
          #score { font-size: 24px; margin: 20px; }
          button { background: #2196F3; color: white; border: none; padding: 10px 20px;
                  border-radius: 4px; font-size: 16px; margin-top: 10px; cursor: pointer; }
        </style>
      </head>
      <body>
        <h1>Circle Clicker</h1>
        <div id="score">Score: 0</div>
        <div id="game-area"></div>
        <button id="restart">Restart Game</button>

        <script>
          const gameArea = document.getElementById('game-area');
          const scoreDisplay = document.getElementById('score');
          const restartButton = document.getElementById('restart');
          let score = 0;

          function createTarget() {
            const target = document.createElement('div');
            target.className = 'target';

            // Random position
            const maxX = gameArea.clientWidth - 30;
            const maxY = gameArea.clientHeight - 30;
            target.style.left = Math.floor(Math.random() * maxX) + 'px';
            target.style.top = Math.floor(Math.random() * maxY) + 'px';

            target.onclick = function() {
              score++;
              scoreDisplay.textContent = 'Score: ' + score;
              gameArea.removeChild(target);
              createTarget();
            };

            gameArea.appendChild(target);

            // Remove target after 2 seconds if not clicked
            setTimeout(() => {
              if (target.parentNode === gameArea) {
                gameArea.removeChild(target);
                createTarget();
              }
            }, 2000);
          }

          function startGame() {
            score = 0;
            scoreDisplay.textContent = 'Score: 0';
            gameArea.innerHTML = '';
            createTarget();
          }

          restartButton.onclick = startGame;
          startGame();
        </script>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(fallbackGameHtml);

    if (mounted) {
      setState(() {
        _loadingError = null;
        _isLoadingPage = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Register observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    print('GameWebViewScreen: Initializing WebView for URL: ${widget.gameUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(const Color(0x00000000)) // Optional: for transparency if needed
      ..enableZoom(true) // Allow zooming
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar, if any.
            print('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoadingPage = true;
                _loadingError = null;
              });
            }
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoadingPage = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
            ''');

            // Only update UI for main frame errors
            if (mounted && error.isForMainFrame == true) {
              // Enhanced SSL/connection error handling
              String errorMessage;
              bool shouldShowFallback = false;
              
              if (error.description.contains('SSL') || 
                  error.description.contains('ERR_SSL_') ||
                  error.description.contains('ERR_CERT_') ||
                  error.description.contains('ERR_CONNECTION_RESET') ||
                  error.description.contains('ERR_CONNECTION_REFUSED') ||
                  error.description.contains('ERR_CONNECTION_TIMED_OUT') ||
                  error.description.contains('ERR_NAME_NOT_RESOLVED') ||
                  error.description.contains('ERR_INTERNET_DISCONNECTED') ||
                  error.description.contains('net::ERR_CONNECTION_RESET') ||
                  error.errorCode == -101 || // ERR_CONNECTION_RESET
                  error.errorCode == -102 || // ERR_CONNECTION_REFUSED  
                  error.errorCode == -7 ||   // ERR_TIMED_OUT
                  error.errorCode == -105 ||  // ERR_NAME_NOT_RESOLVED
                  error.errorCode == -106) {  // ERR_INTERNET_DISCONNECTED
                
                errorMessage = "Connection error: Unable to connect to the game server. This may be due to:\n\n" +
                    "• SSL/Security certificate issues\n" +
                    "• Network connectivity problems\n" +
                    "• Server temporarily unavailable\n" +
                    "• Firewall or proxy restrictions\n\n" +
                    "Try the offline game below or check your connection.";
                shouldShowFallback = true;
              } else if (error.description.contains('ERR_BLOCKED_BY_CLIENT') ||
                         error.description.contains('ERR_BLOCKED_BY_ADMINISTRATOR')) {
                errorMessage = "Access blocked: This game may be restricted by your network administrator or security settings.";
                shouldShowFallback = true;
              } else {
                errorMessage = "Failed to load game (Error ${error.errorCode}): ${error.description}\n\nPlease check your connection or try again later.";
                shouldShowFallback = true;
              }

              setState(() {
                _isLoadingPage = false;
                _loadingError = errorMessage;
              });
              
              // Auto-load fallback game after 3 seconds for connection errors
              if (shouldShowFallback && !_triedFallback) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted && _loadingError != null) {
                    print("Auto-loading fallback game due to connection error");
                    _loadFallbackGame();
                  }
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    // Set custom User-Agent header to work with Cloudflare protection
    // Note: Ensure webview_flutter package version is at least 4.0.0 to support setUserAgent
    _controller.setUserAgent(
      'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.86 Mobile Safari/537.36',
    );

    // Load the URL after setting the User-Agent
    _controller.loadRequest(Uri.parse(widget.gameUrl));

    // Set a timeout to automatically load the fallback game if the WebView takes too long
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoadingPage) {
        print("WebView loading timeout - loading fallback game");
        _loadFallbackGame();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
        // App is in the background
        print("GameWebViewScreen: App paused, suspending WebView processes");
        _pauseWebView();
        break;
      case AppLifecycleState.resumed:
        // App is in the foreground
        print("GameWebViewScreen: App resumed, resuming WebView if needed");
        _resumeWebViewIfNeeded();
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        print("GameWebViewScreen: App inactive");
        break;
      case AppLifecycleState.detached:
        // App is detached
        print("GameWebViewScreen: App detached, cleaning up WebView");
        _cleanupWebView();
        break;
      default:
        break;
    }
  }

  void _pauseWebView() {
    if (!_isPaused) {
      // Pause WebView activity
      _controller.runJavaScript('document.hidden = true;');
      
      // Additional pause operations
      _controller.runJavaScript('''
        // Pause any audio/video elements
        document.querySelectorAll('audio, video').forEach(function(el) {
          if(el && !el.paused) {
            el.pause();
          }
        });
        
        // Attempt to pause canvas animations
        if (window.cancelAnimationFrame) {
          var id = window.requestAnimationFrame(function(){});
          while(id--) {
            window.cancelAnimationFrame(id);
          }
        }
        
        // Inform game it's paused (for games that support visibility API)
        if (document.dispatchEvent) {
          document.dispatchEvent(new Event('visibilitychange'));
        }
      ''');
      
      _isPaused = true;
    }
  }

  void _resumeWebViewIfNeeded() {
    if (_isPaused) {
      // Resume WebView activity
      _controller.runJavaScript('document.hidden = false;');
      
      // Additional resume operations
      _controller.runJavaScript('''
        // Inform game it's resumed (for games that support visibility API)
        if (document.dispatchEvent) {
          document.dispatchEvent(new Event('visibilitychange'));
        }
      ''');
      
      _isPaused = false;
    }
  }

  void _cleanupWebView() {
    // Clean up WebView resources
    _controller.runJavaScript('''
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
      
      // Remove event listeners
      window.onunload = null;
    ''');
  }

  @override
  void dispose() {
    print("GameWebViewScreen: Disposing and cleaning up WebView");
    _cleanupWebView();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _shareGame() {
    final String gameDeepLink = 'gamestagram://game/${widget.gameId}';
    final String message = 'Check out this game: ${widget.gameTitle}\n$gameDeepLink';

    Share.share(message);
    print('[GameWebViewScreen] Shared game: ${widget.gameTitle} with link: $gameDeepLink');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final gameViewModel = Provider.of<GameViewModel>(context);

    final currentUser = authViewModel.currentUser;
    final userId = currentUser?.id;

    // Check if game is saved by current user
    final bool isSaved = userId != null
        ? gameViewModel.isGameSavedByUser(widget.gameId, userId)
        : false;

    return WillPopScope(
      onWillPop: () async {
        // Clean up WebView before popping
        print("GameWebViewScreen: Back button pressed, cleaning up WebView");
        _cleanupWebView();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.gameTitle,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary),
            onPressed: () {
              // Clean up WebView before navigating back
              _cleanupWebView();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            // Pause/Resume button
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                if (_isPaused) {
                  _resumeWebViewIfNeeded();
                } else {
                  _pauseWebView();
                }
                setState(() {}); // Update UI to reflect pause state
              },
            ),
            // Save button
            if (userId != null)
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary,
                ),
                onPressed: () {
                  gameViewModel.toggleSaveGame(widget.gameId, userId);
                },
              ),
            // Share button
            IconButton(
              icon: Icon(
                Icons.share,
                color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary,
              ),
              onPressed: _shareGame,
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isPaused)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pause_circle_outline, 
                           size: 80, 
                           color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Game Paused',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24, 
                            vertical: 12
                          ),
                        ),
                        onPressed: () {
                          _resumeWebViewIfNeeded();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoadingPage)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_loadingError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        _loadingError!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loadingError = null;
                            _isLoadingPage = true;
                          });
                          _controller.loadRequest(Uri.parse(widget.gameUrl));
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                        onPressed: _loadFallbackGame,
                        child: const Text('Play Offline Game'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}