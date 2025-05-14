import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/view_models/auth_view_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../data/models/game_model.dart';
import '../widgets/game_frame_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameViewModel>(context, listen: false).fetchInitialGames();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context);
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
            },
          ),
        ],
      ),
      body: Consumer<GameViewModel>(
        builder: (context, gvm, child) {
          if (gvm.isLoading && gvm.games.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (gvm.errorMessage != null && gvm.games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${gvm.errorMessage}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => gvm.fetchInitialGames(),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          if (gvm.games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No games available right now. Try again later!'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                     onPressed: () => gvm.fetchInitialGames(),
                     child: const Text('Refresh Games'),
                  )
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: gvm.games.length,
            itemBuilder: (context, index) {
              return GameFrameWidget(game: gvm.games[index]);
            },
          );
        },
      ),
    );
  }
}