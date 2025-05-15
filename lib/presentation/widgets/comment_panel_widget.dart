import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';

class CommentPanelWidget extends StatefulWidget {
  final GameModel game;

  const CommentPanelWidget({Key? key, required this.game}) : super(key: key);

  @override
  State<CommentPanelWidget> createState() => _CommentPanelWidgetState();
}

class _CommentPanelWidgetState extends State<CommentPanelWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameViewModel>(context, listen: false).fetchCommentsForGame(widget.game.id);
    });
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to comment')));
      return;
    }

    setState(() => _isPostingComment = true);
    final success = await gameViewModel.addCommentToGame(widget.game.id, currentUser.id, _commentController.text.trim());
    setState(() => _isPostingComment = false);

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post comment. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme colors for better adaptability
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final primaryAccentColor = theme.colorScheme.primary;

    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Handles keyboard overlap
      child: ClipRRect( // Clip the blur effect to the rounded corners
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Adjust blur intensity
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration( // Apply semi-transparent background
              color: surfaceColor.withOpacity(0.85), // Semi-transparent surface color
              // No need for borderRadius here, ClipRRect handles it
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Comments for ${widget.game.title}',
                        style: theme.textTheme.titleLarge?.copyWith(color: onSurfaceColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: onSurfaceColor),
                      onPressed: () => Navigator.pop(context)
                    )
                  ],
                ),
                Divider(color: onSurfaceColor.withOpacity(0.5)),
                Expanded(
                  child: Consumer<GameViewModel>(
                    builder: (context, gvm, child) {
                      if (gvm.isLoadingComments) {
                        return Center(child: CircularProgressIndicator(color: primaryAccentColor));
                      }
                      if (gvm.currentViewingGameComments.isEmpty) {
                        return Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: onSurfaceColor.withOpacity(0.7))));
                      }
                      return ListView.builder(
                        itemCount: gvm.currentViewingGameComments.length,
                        itemBuilder: (context, index) {
                          final comment = gvm.currentViewingGameComments[index];
                          return Card(
                            color: surfaceColor.withOpacity(0.9), // Slightly more opaque cards
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryAccentColor,
                                child: Text(
                                  comment.userId.isNotEmpty ? comment.userId[0].toUpperCase() : 'U',
                                  style: TextStyle(color: theme.colorScheme.onPrimary),
                                ),
                              ),
                              title: Text(comment.text ?? '', style: TextStyle(color: onSurfaceColor)),
                              subtitle: Text(
                                'User ID: ${comment.userId} \n${comment.timestamp.toLocal().toString().substring(0, 16)}',
                                style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Divider(color: onSurfaceColor.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: onSurfaceColor), // Ensure input text is visible
                          decoration: InputDecoration(
                            hintText: 'Add a comment (max 200 chars)...',
                            // hintStyle is already set by the theme in main.dart
                            // border: OutlineInputBorder(), // Using theme's input decoration
                            // contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // Theme handles this
                            counterStyle: TextStyle(color: onSurfaceColor.withOpacity(0.7)), // For maxLength counter
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _isPostingComment ? null : (_) => _postComment(),
                          maxLength: 200,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isPostingComment 
                        ? CircularProgressIndicator(color: primaryAccentColor) 
                        : IconButton(
                            icon: Icon(Icons.send, color: primaryAccentColor),
                            onPressed: _postComment,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
