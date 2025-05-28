import 'dart:convert';

/// Represents a game with its metadata and user interaction state
class GameModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? gameUrl;
  final String? genre;
  int likeCount;
  int commentCount;
  bool isLikedByCurrentUser;
  bool isSavedByCurrentUser;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.gameUrl,
    this.genre,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    this.isSavedByCurrentUser = false,
  });

  /// Creates a GameModel instance from JSON data
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      gameUrl: json['gameUrl'] as String?,
      genre: json['genre'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool? ?? false,
    );
  }

  /// Converts GameModel instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'gameUrl': gameUrl,
      'genre': genre,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isSavedByCurrentUser': isSavedByCurrentUser,
    };
  }
}