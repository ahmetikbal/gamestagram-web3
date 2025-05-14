import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'application/view_models/auth_view_model.dart'; // Import AuthViewModel
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/home_screen.dart'; // Keep for later

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(),
      child: MaterialApp(
        title: 'Gamestagram',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Check login status to decide initial route
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            if (authViewModel.currentUser != null) {
              return const HomeScreen(); // Navigate to HomeScreen if logged in
            } else {
              return const WelcomeScreen(); // Else show WelcomeScreen
            }
          },
        ),
        // Define routes for navigation if needed later
        // routes: {
        //   '/login': (context) => LoginScreen(),
        //   '/register': (context) => RegistrationScreen(),
        //   '/home': (context) => HomeScreen(),
        // },
      ),
    );
  }
}
