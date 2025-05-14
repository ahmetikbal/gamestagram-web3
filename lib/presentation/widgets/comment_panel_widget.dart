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
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Comments for ${widget.game.title}', style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            Expanded(
              child: Consumer<GameViewModel>(
                builder: (context, gvm, child) {
                  if (gvm.isLoadingComments) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (gvm.currentViewingGameComments.isEmpty) {
                    return const Center(child: Text('No comments yet. Be the first!'));
                  }
                  return ListView.builder(
                    itemCount: gvm.currentViewingGameComments.length,
                    itemBuilder: (context, index) {
                      final comment = gvm.currentViewingGameComments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(comment.userId.isNotEmpty ? comment.userId[0].toUpperCase() : 'U')),
                          title: Text(comment.text ?? ''),
                          subtitle: Text('User ID: ${comment.userId} \n${comment.timestamp.toLocal().toString().substring(0, 16)}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment (max 200 chars)...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isPostingComment ? null : (_) => _postComment(),
                      maxLength: 200,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPostingComment 
                    ? const CircularProgressIndicator() 
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _postComment,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
