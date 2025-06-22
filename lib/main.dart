import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'application/view_models/web3_auth_view_model.dart';
import 'application/view_models/web3_game_view_model.dart';
import 'presentation/screens/web3_welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_details_screen.dart';
import 'services/stellar_service.dart';
import 'services/soroban_service.dart';
import 'services/launchtube_service.dart';
import 'utils/logger.dart';
import 'core/theme/app_theme.dart';

// Global service locator
final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Web3 services
    await _initializeWeb3Services();

    // Initialize the theme
    AppTheme.initialize();

    AppLogger.info('Web3 services initialized successfully', 'Main');
  } catch (e) {
    AppLogger.error('Failed to initialize Web3 services', 'Main', e);
  }

  runApp(const MyApp());
}

/// Initialize all Web3 services
Future<void> _initializeWeb3Services() async {
  try {
    // Register services in the service locator
    getIt.registerSingleton<StellarService>(StellarService());
    getIt.registerSingleton<SorobanService>(SorobanService());
    getIt.registerSingleton<LaunchtubeService>(LaunchtubeService());

    // Initialize Stellar service
    await getIt<StellarService>().initialize();

    AppLogger.info('Web3 services registered and initialized', 'Main');
  } catch (e) {
    AppLogger.error('Failed to initialize Web3 services', 'Main', e);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Web3AuthViewModel()),
        ChangeNotifierProvider(create: (_) => Web3GameViewModel()),
      ],
      child: MaterialApp(
        title: 'Gamestagram Web3',
        theme: AppTheme.darkTheme,
        home: Consumer<Web3AuthViewModel>(
          builder: (context, authViewModel, child) {
            if (authViewModel.isLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Initializing Web3...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return authViewModel.isAuthenticated
                ? const HomeScreen()
                : const Web3WelcomeScreen();
          },
        ),
        onGenerateRoute: (settings) {
          // Handle deep links and navigation
          if (settings.name?.startsWith('/game/') == true) {
            final gameId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) {
                // Find the game by ID from the Web3GameViewModel
                final gameViewModel = Provider.of<Web3GameViewModel>(
                  context,
                  listen: false,
                );
                final game = gameViewModel.games.firstWhere(
                  (g) => g.id == gameId,
                  orElse: () => throw Exception('Game not found'),
                );
                return GameDetailsScreen(game: game);
              },
            );
          }
          return null;
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

      // Get the Web3GameViewModel to find the game
      final gameViewModel = Provider.of<Web3GameViewModel>(
        context,
        listen: false,
      );

      // We need to get the game details from the service
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // In a real app, you would have a method to get a game by ID
          // Here we'll look for the game in the current list or fetch initial games
          if (gameViewModel.games.isEmpty) {
            print('[MainApp] Initializing Web3GameViewModel...');
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
