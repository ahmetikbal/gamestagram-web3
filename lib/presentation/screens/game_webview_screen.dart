import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class GameWebViewScreen extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;

  const GameWebViewScreen({Key? key, required this.gameUrl, required this.gameTitle}) : super(key: key);

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  String? _loadingError;
  bool _triedFallback = false;

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
          let gameInterval;
          
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
              // Special handling for SSL/connection errors
              final errorMessage = (error.description.contains('SSL') || 
                                   error.description.contains('ERR_CONNECTION_RESET') ||
                                   error.description.contains('ERR_CONNECTION_REFUSED'))
                  ? "Connection error: Unable to connect securely to the game server. This may be due to network restrictions or site policies."
                  : "Failed to load game (Code: ${error.errorCode}). Please check your connection or try again later.";
                  
              setState(() {
                _isLoadingPage = false;
                _loadingError = errorMessage;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );
      
    // Set custom User-Agent header to work with Cloudflare protection
    _controller.setUserAgent(
      'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.86 Mobile Safari/537.36'
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameTitle, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
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
    );
  }
} 