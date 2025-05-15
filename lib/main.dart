import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'application/view_models/auth_view_model.dart';
import 'application/view_models/game_view_model.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define a dark theme
    final baseDarkTheme = ThemeData.dark();
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[900], // A deep charcoal
      scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark theme background
      colorScheme: ColorScheme.dark(
        primary: Colors.tealAccent[400]!, // Vibrant accent for primary actions
        secondary: Colors.pinkAccent[200]!, // Another vibrant accent (optional use)
        surface: Colors.grey[850]!, // For surfaces like cards, dialogs (slightly lighter than scaffold)
        background: const Color(0xFF121212),
        error: Colors.redAccent[400]!,
        onPrimary: Colors.black, // Text/icon color on primary accent
        onSecondary: Colors.black, // Text/icon color on secondary accent
        onSurface: Colors.white,   // Text/icon color on surfaces
        onBackground: Colors.white, // Text/icon color on background
        onError: Colors.black,     // Text/icon color on error
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900]?.withOpacity(0.85), // Slightly transparent AppBar
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent[400],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      cardTheme: CardTheme(
        elevation: 4,
        color: Colors.grey[850], // Matches surface color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme).copyWith(
        bodyLarge: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        titleLarge: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 22),
        titleMedium: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),
        labelLarge: GoogleFonts.poppins(color: Colors.tealAccent[400], fontWeight: FontWeight.w600), // For button text if not overridden by button themes
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
          print('[MainApp Consumer] Rebuilding. CurrentUser: ${authViewModel.currentUser?.username}, isLoading: ${authViewModel.isLoading}');
          return MaterialApp(
            key: ValueKey(authViewModel.currentUser?.id ?? 'loggedOut'),
            title: 'Gamestagram',
            theme: darkTheme, // Apply the dark theme
            home: authViewModel.currentUser != null 
                ? const HomeScreen() 
                : const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
