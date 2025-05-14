import 'package:flutter/material.dart';
// import 'presentation/screens/home_screen.dart'; // Adjusted import path
import 'presentation/screens/welcome_screen.dart'; // Import WelcomeScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamestagram',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: const HomeScreen(),
      home: const WelcomeScreen(), // Set WelcomeScreen as home
    );
  }
}
