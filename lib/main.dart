import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[900], // A deep charcoal
      scaffoldBackgroundColor: Colors.grey[850], // Slightly lighter for background
      colorScheme: ColorScheme.dark(
        primary: Colors.tealAccent[400]!, // Vibrant accent for primary actions
        secondary: Colors.pinkAccent[200]!, // Another vibrant accent (optional use)
        surface: Colors.grey[800]!, // For surfaces like cards, dialogs
        background: Colors.grey[850]!,
        error: Colors.redAccent[400]!,
        onPrimary: Colors.black, // Text/icon color on primary accent
        onSecondary: Colors.black, // Text/icon color on secondary accent
        onSurface: Colors.white,   // Text/icon color on surfaces
        onBackground: Colors.white, // Text/icon color on background
        onError: Colors.black,     // Text/icon color on error
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.tealAccent[400]),
        titleTextStyle: TextStyle(
          color: Colors.white, 
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.tealAccent[400], // Default button color
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent[400],
          foregroundColor: Colors.black,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.tealAccent[400],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.tealAccent[400]!),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        // Define other text styles as needed
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
