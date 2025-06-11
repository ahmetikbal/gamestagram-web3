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
                        color: Colors.grey[700],
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[600]!,
                            Colors.blue[400]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 13, 
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
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
                        ? Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isCurrentUser 
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey[700]!,
                  Colors.grey[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: _getBorderRadius(),
        border: Border.all(
          color: isCurrentUser 
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.grey[500]!.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser 
                ? theme.colorScheme.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show username at the top of first comment in group
          if (isFirstInGroup && !isCurrentUser) ...[
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  comment.username.isNotEmpty ? comment.username : 'Unknown User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          // Comment content
          Text(
            comment.content ?? comment.text ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          
          // Show timestamp and username info on last comment in group
          if (isLastInGroup) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
              children: [
                // Show username for current user on the left
                if (isCurrentUser) ...[
                  Text(
                    comment.username.isNotEmpty ? comment.username : 'You',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 1,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Timestamp with tooltip for full date/time
                Tooltip(
                  message: _formatFullTimestamp(comment.timestamp),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimestamp(comment.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 1,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    
    if (difference.inDays > 7) {
      // Show formatted date for older comments
      return _formatShortDate(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inSeconds > 30) {
      return '${difference.inSeconds} sec ago';
    }
    return 'just now';
  }
  
  /// Formats a complete timestamp for tooltips
  String _formatFullTimestamp(DateTime timestamp) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[timestamp.month - 1];
    final day = timestamp.day;
    final year = timestamp.year;
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour == 0 ? 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year • $hour:$minute $ampm';
  }
  
  /// Formats a short date for older comments
  String _formatShortDate(DateTime timestamp) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final month = months[timestamp.month - 1];
    final day = timestamp.day;
    final year = timestamp.year;
    
    return '$month $day, $year';
  }
}
 