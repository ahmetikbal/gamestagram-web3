import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';

/// A modal bottom sheet widget for displaying and managing game comments
/// 
/// Features:
/// - Glassmorphism design with backdrop blur effect
/// - Real-time comment loading and posting
/// - Chat-style comment bubbles with user identification
/// - Keyboard-aware layout that adjusts for input
/// - Optimistic UI updates for smooth user experience
/// - Auto-scroll to new comments for better UX
class CommentPanelWidget extends StatefulWidget {
  final GameModel game;

  const CommentPanelWidget({Key? key, required this.game}) : super(key: key);

  @override
  State<CommentPanelWidget> createState() => _CommentPanelWidgetState();
}

class _CommentPanelWidgetState extends State<CommentPanelWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
<<<<<<< HEAD
      Provider.of<GameViewModel>(
        context,
        listen: false,
      ).fetchCommentsForGame(widget.game.id);
=======
      Provider.of<GameViewModel>(context, listen: false).fetchComments(widget.game.id);
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to comment')));
      return;
    }

    setState(() => _isPostingComment = true);
<<<<<<< HEAD
    final success = await gameViewModel.addCommentToGame(
      widget.game.id,
      currentUser.id,
      _commentController.text.trim(),
    );
    setState(() => _isPostingComment = false);

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();

      // Scroll to top to see new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment. Please try again.'),
          ),
        );
      }
=======
    await gameViewModel.addComment(widget.game.id, currentUser.id, _commentController.text.trim());
    setState(() => _isPostingComment = false);

    _commentController.clear();
    FocusScope.of(context).unfocus();
    
    // Scroll to top to see new comment
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
>>>>>>> 650e07f (Refactors on commenting and meaningful on-line explanations)
    }
  }

  Widget _buildCommentBubble(InteractionModel comment, ThemeData theme) {
    final bool isCurrentUser =
        Provider.of<AuthViewModel>(context, listen: false).currentUser?.id ==
        comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                comment.username.isNotEmpty
                    ? comment.username[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (!isCurrentUser) const SizedBox(width: 10),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? theme.colorScheme.primary.withOpacity(0.85)
                        : theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and timestamp
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isCurrentUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatTimestamp(comment.timestamp)}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isCurrentUser
                                  ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                  : theme.colorScheme.onSurface.withOpacity(
                                    0.7,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Comment text
                  Text(
                    comment.content,
                    style: TextStyle(
                      color:
                          isCurrentUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isCurrentUser) const SizedBox(width: 10),

          if (isCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                comment.userId.isNotEmpty
                    ? comment.userId[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surfaceColor.withOpacity(0.85),
                  surfaceColor.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle for better UX
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comments',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.game.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurfaceColor.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: onSurfaceColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: onSurfaceColor.withOpacity(0.1), thickness: 1),

                // Comments list
                Expanded(
                  child: Consumer<GameViewModel>(
                    builder: (context, gvm, child) {
                      if (gvm.isLoadingComments) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: primaryAccentColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading comments...',
                                style: TextStyle(
                                  color: onSurfaceColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (gvm.currentViewingGameComments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: onSurfaceColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: onSurfaceColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to comment on this game!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onSurfaceColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: gvm.currentViewingGameComments.length,
                        itemBuilder: (context, index) {
                          final comment = gvm.currentViewingGameComments[index];
                          return _buildCommentBubble(comment, theme);
                        },
                      );
                    },
                  ),
                ),

                // Comment input field
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.8,
                        ),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: onSurfaceColor),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                              color: onSurfaceColor.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted:
                              _isPostingComment ? null : (_) => _postComment(),
                          maxLength: 200,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isPostingComment
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: primaryAccentColor,
                              strokeWidth: 2,
                            ),
                          )
                          : Material(
                            color: primaryAccentColor,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _postComment,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
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
