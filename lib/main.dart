import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'application/view_models/auth_view_model.dart';
import 'application/view_models/game_view_model.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_details_screen.dart';
import 'utils/network_config.dart';
import 'services/game_service.dart';
import 'utils/logger.dart';
import 'utils/performance_monitor.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firebase App Check for development
  await FirebaseAppCheck.instance.activate(
    // For development/testing, use debug provider
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  AppLogger.info('Firebase and App Check initialized successfully', 'MainApp');
  
  // Initialize optimized theme
  AppTheme.initialize();
  
  // DISABLED: Performance monitoring to reduce overhead
  // PerformanceMonitor.startMonitoring();
  
  // Override HTTP client for images to handle SSL issues
  HttpOverrides.global = _CustomHttpOverrides();
  
  runApp(const MyApp());
}

/// Custom HTTP overrides to handle SSL certificates for image loading
class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return NetworkConfig.createHttpClient();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // App links instance
  late AppLinks _appLinks;
  // For the initial URL when app starts
  String? _initialLink;
  // When a link is handled
  bool _initialLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  // Initialize deep linking
  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Handle initial URI if app was started from a deep link
    try {
      final appLinkUri = await _appLinks.getInitialLink();
      if (appLinkUri != null) {
        print('Initial URI: $appLinkUri');
        _initialLink = appLinkUri.toString();
      }
    } catch (e) {
      print('Error handling initial URI: $e');
    }

    // Handle links when app is already running
    _appLinks.uriLinkStream.listen(
      (uri) {
        print('URI received: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        print('Error handling URI: $error');
      },
    );
  }

  // Handle the deep link
  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      String gameId = uri.pathSegments[1];
      _openGameFromId(gameId);
    }
  }

  // Open game by ID
  void _openGameFromId(String gameId) {
    // We need access to the GameService and navigation context, which is tricky from here
    // We'll pass this info down to be handled after initialization
    print('Deep link opening game with ID: $gameId');
    // We'll handle this in the build method via DeepLinkHandler widget
  }

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => GameViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          print(
            '[MainApp Consumer] Rebuilding. CurrentUser: ${authViewModel.currentUser?.username}, isLoading: ${authViewModel.isLoading}',
          );
          return MaterialApp(
            key: ValueKey(authViewModel.currentUser?.id ?? 'loggedOut'),
            title: 'Gamestagram',
            theme: AppTheme.darkTheme, // Use pre-built optimized theme
            home: DeepLinkHandler(
              initialLink: _initialLink,
              initialLinkHandled: _initialLinkHandled,
              onLinkHandled: () {
                // Use post-frame callback to avoid setState during build phase
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _initialLinkHandled = true;
                  });
                });
              },
              child:
                  authViewModel.currentUser != null
                      ? const HomeScreen()
                      : const WelcomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  final String? initialLink;
  final bool initialLinkHandled;
  final VoidCallback onLinkHandled;

  const DeepLinkHandler({
    Key? key,
    required this.child,
    this.initialLink,
    required this.initialLinkHandled,
    required this.onLinkHandled,
  }) : super(key: key);

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Handle initial URI if it exists - use post-frame callback to avoid setState during build
    if (widget.initialLink != null && !widget.initialLinkHandled) {
      // Use addPostFrameCallback to handle this after the build phase completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(Uri.parse(widget.initialLink!));
        widget.onLinkHandled();
      });
    }
  }

  void _handleDeepLink(Uri uri) {
    // Handle game deep links
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      final gameId = uri.pathSegments[1];
      print('DeepLinkHandler: Opening game with ID: $gameId');

      // Get the GameService to find the game
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      final gameService = GameService();

      // We need to get the game details from the service
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // In a real app, you would have a method to get a game by ID
          // Here we'll look for the game in the current list or fetch initial games
          if (gameViewModel.games.isEmpty) {
            print('[MainApp] Initializing GameViewModel...');
            await gameViewModel.loadInitialGames();
          }

          // Find the game
          final game = gameViewModel.games.firstWhere(
            (g) => g.id == gameId,
            orElse: () => throw Exception('Game not found'),
          );

          // Navigate to the Game Details screen instead of WebView directly
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailsScreen(game: game),
            ),
          );
        } catch (e) {
          print('Error handling deep link: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open game: $e')));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
