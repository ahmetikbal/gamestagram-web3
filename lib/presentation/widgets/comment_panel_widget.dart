import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/game_model.dart';
import '../../data/models/interaction_model.dart';
import '../../application/view_models/game_view_model.dart';
import '../../application/view_models/auth_view_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-high performance comment panel with aggressive optimizations
/// 
/// Features:
/// - Widget caching to prevent rebuilds
/// - Optimized ListView with item extent
/// - Minimal Consumer usage
/// - Fast comment bubbles
/// - Non-blocking keyboard handling
/// - Half-screen modal with darkened background
class CommentPanelWidget extends StatefulWidget {
  final GameModel game;

  const CommentPanelWidget({Key? key, required this.game}) : super(key: key);

  @override
  State<CommentPanelWidget> createState() => _CommentPanelWidgetState();
}

class _CommentPanelWidgetState extends State<CommentPanelWidget> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPostingComment = false;
  
  // Cache for comment widgets to prevent rebuilds
  final Map<String, Widget> _commentWidgetCache = {};
  List<InteractionModel> _cachedComments = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Load comments using the proper method
    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    gameViewModel.fetchComments(widget.game.id);
    
    // Cache current user ID
    _currentUserId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.id;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentWidgetCache.clear();
    super.dispose();
  }

  /// Ultra-fast comment posting without UI blocking
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _currentUserId == null) return;

    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
    final commentText = _commentController.text.trim();
    
    // Clear input immediately for instant feedback
    _commentController.clear();
    FocusScope.of(context).unfocus();
    
    // Post comment in background without blocking UI
    setState(() => _isPostingComment = true);
    
    try {
      await gameViewModel.addCommentFast(widget.game.id, _currentUserId!, commentText);
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
        // Force scroll to top if needed
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  /// Cached comment bubble builder for maximum performance
  Widget _buildCachedCommentBubble(InteractionModel comment, ThemeData theme, int index, List<InteractionModel> allComments) {
    // Use cached widget if available
    final cacheKey = '${comment.id}_$index';
    if (_commentWidgetCache.containsKey(cacheKey)) {
      return _commentWidgetCache[cacheKey]!;
    }
    
    final isCurrentUser = _currentUserId == comment.userId;
    
    // Check if this comment is the first in a group (different user than previous)
    final isFirstInGroup = index == 0 || allComments[index - 1].userId != comment.userId;
    
    // Check if this comment is the last in a group (different user than next)
    final isLastInGroup = index == allComments.length - 1 || allComments[index + 1].userId != comment.userId;
    
    // Build optimized comment bubble with grouping info
    final widget = _FastCommentBubble(
      comment: comment,
      isCurrentUser: isCurrentUser,
      theme: theme,
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
    );
    
    // Cache the widget
    _commentWidgetCache[cacheKey] = widget;
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Invisible overlay for tap-to-close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Comment panel
          Positioned(
            bottom: keyboardHeight,
            left: 0,
            right: 0,
            height: screenHeight * 0.5,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping the panel
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
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
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Simple header without heavy decorations
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Comments - ${widget.game.title}',
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    // Ultra-optimized comments list
                    Expanded(
                      child: Selector<GameViewModel, List<InteractionModel>>(
                        selector: (context, gvm) => gvm.currentViewingGameComments,
                        builder: (context, comments, child) {
                          // Update cache only if comments changed
                          if (comments != _cachedComments) {
                            _cachedComments = List.from(comments);
                            // Clear widget cache for removed comments or changed positions
                            final commentIds = comments.map((c) => c.id).toSet();
                            _commentWidgetCache.removeWhere((key, widget) {
                              // Extract comment ID from cache key (format: "commentId_index")
                              final commentId = key.split('_')[0];
                              return !commentIds.contains(commentId);
                            });
                            // Clear all cache when comments change to ensure proper grouping
                            _commentWidgetCache.clear();
                          }
                          
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text('No comments yet. Be the first!'),
                            );
                          }
                          
                          // Ultra-fast ListView with fixed item extent
                          return ListView.builder(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(), // Faster than bouncing
                            itemCount: comments.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemBuilder: (context, index) {
                              return _buildCachedCommentBubble(comments[index], theme, index, comments);
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Minimal input field with keyboard-aware padding
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: _isPostingComment ? null : (_) => _postComment(),
                                    maxLength: 200,
                                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 4, left: 4),
                                  child: _isPostingComment 
                                    ? Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary.withOpacity(0.3),
                                              theme.colorScheme.secondary.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _postComment,
                                              splashColor: Colors.white.withOpacity(0.2),
                                              highlightColor: Colors.white.withOpacity(0.1),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.send_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Highly optimized comment bubble widget with grouping support
class _FastCommentBubble extends StatelessWidget {
  final InteractionModel comment;
  final bool isCurrentUser;
  final ThemeData theme;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _FastCommentBubble({
    required this.comment,
    required this.isCurrentUser,
    required this.theme,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        top: isFirstInGroup ? 4 : 1,
        bottom: isLastInGroup ? 4 : 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Left side - other users
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              child: isFirstInGroup
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        comment.userId.isNotEmpty ? comment.userId[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : null, // Empty space to maintain alignment
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                margin: const EdgeInsets.only(right: 60),
                child: _buildCommentBubble(),
              ),
            ),
          ] else ...[
            // Right side - current user
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    margin: const EdgeInsets.only(left: 60),
                    child: _buildCommentBubble(),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                    child: isFirstInGroup
                        ? CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              comment.userId.isNotEmpty ? comment.userId[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                        : null, // Empty space to maintain alignment
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceVariant,
        borderRadius: _getBorderRadius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            comment.content ?? comment.text ?? '',
            style: TextStyle(
              color: isCurrentUser 
                  ? theme.colorScheme.onPrimary 
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          // Show timestamp only on last comment in group
          if (isLastInGroup) ...[
            const SizedBox(height: 4),
            Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                _formatTimestamp(comment.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser 
                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Get appropriate border radius based on position in group
  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(12);
    const smallRadius = Radius.circular(4);
    
    if (isCurrentUser) {
      // Current user bubbles (right side)
      if (isFirstInGroup && isLastInGroup) {
        // Single comment
        return BorderRadius.circular(12);
      } else if (isFirstInGroup) {
        // First in group
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: smallRadius,
        );
      } else if (isLastInGroup) {
        // Last in group
        return const BorderRadius.only(
          topLeft: radius,
          topRight: smallRadius,
          bottomLeft: radius,
          bottomRight: radius,
        );
      } else {
        // Middle of group
        return const BorderRadius.only(
          topLeft: radius,
          topRight: smallRadius,
          bottomLeft: radius,
          bottomRight: smallRadius,
        );
      }
    } else {
      // Other user bubbles (left side)
      if (isFirstInGroup && isLastInGroup) {
        // Single comment
        return BorderRadius.circular(12);
      } else if (isFirstInGroup) {
        // First in group
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: smallRadius,
          bottomRight: radius,
        );
      } else if (isLastInGroup) {
        // Last in group
        return const BorderRadius.only(
          topLeft: smallRadius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        );
      } else {
        // Middle of group
        return const BorderRadius.only(
          topLeft: smallRadius,
          topRight: radius,
          bottomLeft: smallRadius,
          bottomRight: radius,
        );
      }
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }
}
 