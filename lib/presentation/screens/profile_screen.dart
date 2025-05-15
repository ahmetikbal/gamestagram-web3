import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/view_models/auth_view_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../data/models/game_model.dart';
import '../screens/game_webview_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        gameViewModel.fetchSavedGames(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final gameViewModel = Provider.of<GameViewModel>(context);
    final user = authViewModel.currentUser;
    final savedGames = gameViewModel.savedGames;

    if (user == null) {
      // This should ideally not happen if ProfileScreen is only accessible when logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not logged in.')),
      );
    }
    
    // Get accurate like and comment counts
    final userLikeCount = gameViewModel.getUserLikeCount(user.id);
    final userCommentCount = gameViewModel.getUserCommentCount(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              // TODO: Navigate to EditProfileScreen
              print('Edit Profile tapped');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              // backgroundImage: NetworkImage(user.profilePictureUrl ?? ''), // Placeholder
              child: Icon(Icons.person, size: 50), // Placeholder
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.email, // Displaying email, bio can be added later
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildStatItem(context, 'Games Saved', savedGames.length.toString()),
            _buildStatItem(context, 'Games Liked', userLikeCount.toString()),
            _buildStatItem(context, 'Comments Made', userCommentCount.toString()),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'My Saved Games',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // List of saved games
            savedGames.isEmpty
                ? const Text('No saved games yet.', style: TextStyle(color: Colors.grey))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: savedGames.length,
                    itemBuilder: (context, index) {
                      return _buildSavedGameCard(context, savedGames[index]);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSavedGameCard(BuildContext context, GameModel game) {
    return GestureDetector(
      onTap: () {
        if (game.gameUrl != null && game.gameUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameWebViewScreen(
                gameUrl: game.gameUrl!,
                gameTitle: game.title,
                gameId: game.id,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This game is not playable')),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videogame_asset, size: 40),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                game.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text('${game.likeCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 