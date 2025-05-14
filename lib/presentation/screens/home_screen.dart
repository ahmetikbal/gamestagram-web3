import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/view_models/auth_view_model.dart';
import '../../data/models/game_model.dart';
import '../widgets/game_frame_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Mock data for initial setup - will be replaced by actual game fetching later
  // final List<Game> _games = [
  //   Game(id: '1', title: 'Game One', description: 'The first amazing game!'),
  //   Game(id: '2', title: 'Game Two', description: 'Swipe up for more fun.'),
  //   Game(id: '3', title: 'Game Three', description: 'Challenge your friends!'),
  //   Game(id: '4', title: 'Game Four', description: 'New levels added weekly.'),
  //   Game(id: '5', title: 'Game Five', description: 'Collect all the achievements.'),
  // ];

  // final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? 'Welcome, ${user.username}!' : 'Gamestagram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authViewModel.logout();
              // Navigation to WelcomeScreen is handled by Consumer in main.dart
            },
          ),
        ],
      ),
      body: Center(
        child: user != null 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You are logged in as:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${user.id}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Username: ${user.username}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Email: ${user.email}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '(Game Feed will be here)',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  )
                ],
              )
            : const Text('Not logged in. This should not typically be visible.'),
      ),
      // body: PageView.builder(
      //   controller: _pageController,
      //   scrollDirection: Axis.vertical,
      //   itemCount: _games.length,
      //   itemBuilder: (context, index) {
      //     return GameFrameWidget(game: _games[index]);
      //   },
      // ),
    );
  }
} 