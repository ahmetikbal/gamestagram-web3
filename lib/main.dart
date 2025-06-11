import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'application/view_models/auth_view_model.dart';
import 'application/view_models/game_view_model.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_details_screen.dart';
import 'services/game_service.dart';
import 'utils/logger.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized successfully', 'Main');
  } catch (e) {
    AppLogger.error('Firebase initialization failed', 'Main', e);
  }
  
  // Initialize the theme
  AppTheme.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GameViewModel()),
      ],
      child: MaterialApp(
        title: 'Gamestagram',
        theme: AppTheme.darkTheme,
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            if (authViewModel.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            return authViewModel.currentUser != null 
                ? const HomeScreen() 
                : const WelcomeScreen();
          },
        ),
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


