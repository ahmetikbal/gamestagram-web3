import 'package:flutter/material.dart';
import 'registration_screen.dart'; // Import RegistrationScreen
// Import for LoginScreen will be added later

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Gamestagram'),
        automaticallyImplyLeading: false, // Hide back button if it's the first screen
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Placeholder for App Logo
              const Icon(Icons.gamepad, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 48),
              Text(
                'Gamestagram',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe, Play, Connect.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0)
                ),
                onPressed: () {
                  // Navigate to Registration Screen - to be implemented
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
                  // print('Navigate to Registration Screen'); // Placeholder
                },
                child: const Text('Register', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                 style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0)
                ),
                onPressed: () {
                  // Navigate to Login Screen - to be implemented
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                  print('Navigate to Login Screen'); // Placeholder
                },
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
