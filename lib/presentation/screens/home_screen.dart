import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../application/view_models/auth_view_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../data/models/game_model.dart';
import '../widgets/game_frame_widget.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final ScrollPhysics _scrollPhysics = const BouncingScrollPhysics();

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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true, // Important for blur effect
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.7),
                    theme.colorScheme.secondary.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.sports_esports,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Gamestagram',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
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
            physics: _scrollPhysics,
            itemCount: gvm.games.length + (gvm.isLoading && gvm.games.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == gvm.games.length && gvm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (index >= gvm.games.length - 2 && !gvm.isLoading) {
                Provider.of<GameViewModel>(context, listen: false).fetchMoreGames();
              }
              return GameFrameWidget(game: gvm.games[index]);
            },
          );
        },
      ),
    );
  }
}