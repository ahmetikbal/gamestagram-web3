import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../application/view_models/game_view_model.dart'; // Or a dedicated CommentViewModel
import '../../application/view_models/auth_view_model.dart';

class CommentPanelWidget extends StatefulWidget {
  final GameModel game; // To know which game's comments to show/add to

  const CommentPanelWidget({Key? key, required this.game}) : super(key: key);

  @override
  State<CommentPanelWidget> createState() => _CommentPanelWidgetState();
}

class _CommentPanelWidgetState extends State<CommentPanelWidget> {
  final TextEditingController _commentController = TextEditingController();
  // List<InteractionModel> _comments = []; // Will be fetched from a ViewModel
  // bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    // TODO: Fetch comments for widget.game.id when panel opens
    // _loadComments();
  }

  // Future<void> _loadComments() async {
  //   setState(() => _isLoadingComments = true);
  //   // final comments = await Provider.of<SocialViewModel>(context, listen: false).getComments(widget.game.id);
  //   // setState(() {
  //   //   _comments = comments;
  //   //   _isLoadingComments = false;
  //   // });
  // }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to comment')));
      return;
    }

    // TODO: Call a ViewModel method to post the comment
    // await Provider.of<SocialViewModel>(context, listen: false).addComment(widget.game.id, currentUser.id, _commentController.text);
    print('Posting comment: ${_commentController.text} for game ${widget.game.id} by user ${currentUser.id}');
    _commentController.clear();
    // _loadComments(); // Refresh comments list
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Handles keyboard overlap
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height * 0.6, // Take 60% of screen height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comments for ${widget.game.title}', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            // Expanded(
            //   child: _isLoadingComments 
            //     ? const Center(child: CircularProgressIndicator())
            //     : _comments.isEmpty 
            //       ? const Center(child: Text('No comments yet. Be the first!')) 
            //       : ListView.builder(
            //           itemCount: _comments.length,
            //           itemBuilder: (context, index) {
            //             final comment = _comments[index];
            //             return ListTile(
            //               leading: CircleAvatar(child: Text(comment.userId[0])), // Placeholder avatar
            //               title: Text(comment.text ?? ''),
            //               subtitle: Text('User ${comment.userId} - ${comment.timestamp.toLocal().toString().substring(0,16)}'),
            //             );
            //           },
            //         ),
            // ),
            const Expanded(child: Center(child: Text('Comments list will appear here.'))), // Placeholder
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
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
