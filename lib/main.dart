import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:app_links/app_links.dart'; // For deep linking
import 'dart:async';
import 'application/view_models/auth_view_model.dart';
import 'application/view_models/game_view_model.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_webview_screen.dart';
import 'presentation/screens/game_details_screen.dart';
import 'services/game_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/* // use Firebase App Check for debugging on Android
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    //webRecaptchaSiteKey: 'recaptcha-v3-site-key',
    // Set androidProvider to `AndroidProvider.debug`
    androidProvider: AndroidProvider.debug,
  );
  //print(FirebaseAppCheck.instance.getToken());
  runApp(const MyApp());
}
*/

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
    // Define a dark theme
    final baseDarkTheme = ThemeData.dark();
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[900], // A deep charcoal
      scaffoldBackgroundColor: const Color(
        0xFF121212,
      ), // Standard dark theme background
      colorScheme: ColorScheme.dark(
        primary: Colors.tealAccent[400]!, // Vibrant accent for primary actions
        secondary:
            Colors.pinkAccent[200]!, // Another vibrant accent (optional use)
        surface:
            Colors
                .grey[850]!, // For surfaces like cards, dialogs (slightly lighter than scaffold)
        background: const Color(0xFF121212),
        error: Colors.redAccent[400]!,
        onPrimary: Colors.black, // Text/icon color on primary accent
        onSecondary: Colors.black, // Text/icon color on secondary accent
        onSurface: Colors.white, // Text/icon color on surfaces
        onBackground: Colors.white, // Text/icon color on background
        onError: Colors.black, // Text/icon color on error
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900]?.withOpacity(
          0.85,
        ), // Slightly transparent AppBar
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.tealAccent[400]),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600, // Adjusted weight for Poppins
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.tealAccent[400], // Default button color
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent[400],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.tealAccent[400],
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.tealAccent[400]!, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: Colors.grey[850], // Matches surface color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme).copyWith(
        bodyLarge: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        titleLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        labelLarge: GoogleFonts.poppins(
          color: Colors.tealAccent[400],
          fontWeight: FontWeight.w600,
        ), // For button text if not overridden by button themes
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

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
            theme: darkTheme, // Apply the dark theme
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
            await gameViewModel.fetchInitialGames();
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
