import 'package:flutter/material.dart';
import '../../data/models/game_model.dart';
import '../widgets/game_frame_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data for initial setup
  final List<Game> _games = [
    Game(id: '1', title: 'Game One', description: 'The first amazing game!'),
    Game(id: '2', title: 'Game Two', description: 'Swipe up for more fun.'),
    Game(id: '3', title: 'Game Three', description: 'Challenge your friends!'),
    Game(id: '4', title: 'Game Four', description: 'New levels added weekly.'),
    Game(id: '5', title: 'Game Five', description: 'Collect all the achievements.'),
  ];

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamestagram'),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _games.length,
        itemBuilder: (context, index) {
          return GameFrameWidget(game: _games[index]);
        },
      ),
    );
  }
} 