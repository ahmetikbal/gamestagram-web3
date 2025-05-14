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
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          print('[MainApp Consumer] Rebuilding. CurrentUser: ${authViewModel.currentUser?.username}, isLoading: ${authViewModel.isLoading}');
          return MaterialApp(
            key: ValueKey(authViewModel.currentUser?.id ?? 'loggedOut'), // Optional: Add a key based on login state
            title: 'Gamestagram',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: authViewModel.currentUser != null 
                ? const HomeScreen() 
                : const WelcomeScreen(),
            // Define routes for navigation if needed later
            // routes: {
            //   '/login': (context) => LoginScreen(),
            //   '/register': (context) => RegistrationScreen(),
            //   '/home': (context) => HomeScreen(),
            // },
          );
        },
      ),
    );
  }
}
