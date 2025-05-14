class GameModel {
  final String id;
  final String title;
  final String description;
  int likeCount;
  int commentCount;
  bool isLikedByCurrentUser;

  GameModel({
    required this.id,
    required this.title,
    this.description = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
  });
}