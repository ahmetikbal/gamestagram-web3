import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/view_models/auth_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    if (user == null) {
      // This should ideally not happen if ProfileScreen is only accessible when logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

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
            _buildStatItem('Games Played', '123'), // Placeholder
            _buildStatItem('Achievements', '12'), // Placeholder
            _buildStatItem('Highest Score', '10,000'), // Placeholder
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'My Games (Saved/Bookmarked)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Placeholder for list of saved games
            const Text('No saved games yet.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
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
}
 