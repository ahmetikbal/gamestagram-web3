import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for direct use if needed, though theme should handle it
import 'registration_screen.dart'; // Import RegistrationScreen
import 'login_screen.dart'; // Import LoginScreen
// Import for LoginScreen will be added later

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme data

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Welcome to Gamestagram'),
      //   automaticallyImplyLeading: false, // Hide back button if it's the first screen
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface, // A slightly lighter dark
              theme.scaffoldBackgroundColor, // Base dark
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // App Title / Logo Area
                Text(
                  'Gamestagram',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // Use primary accent color
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Swipe, Play, Connect.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
                const Spacer(flex: 2), // Pushes content to center and buttons down
                
                // Action Buttons
                ElevatedButton(
                  // Style should be picked from ElevatedButtonTheme in main.dart
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
                  },
                  child: const Text('Register'), // Text style from ElevatedButtonTheme
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary, // Text and icon color
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  },
                  child: const Text('Login'),
                ),
                const Spacer(flex: 1), // Some space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 