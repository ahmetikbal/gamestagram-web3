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
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: authViewModel.currentUser != null 
                ? const HomeScreen() 
                : const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
