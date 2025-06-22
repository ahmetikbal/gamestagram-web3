import 'package:json_annotation/json_annotation.dart';

part 'game_model.g.dart';

/// Represents a game with its metadata, user interaction state, and Web3 features
@JsonSerializable()
class GameModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? gameUrl;
  final String? genre;

  // Developer Information
  final String developerId;
  final String developerName;
  final String? developerWalletAddress;

  // Web3 and Blockchain Features
  final String? smartContractAddress; // Soroban contract address
  final String? gameTokenAddress; // Custom game token address
  final List<String> supportedTokens; // List of supported payment tokens
  final bool isNFTEnabled;
  final String? nftCollectionAddress;

  // Game Statistics and Metrics
  int likeCount;
  int commentCount;
  int playCount;
  int totalPlayTime; // in minutes
  double averageRating;
  int ratingCount;
  double totalRevenue; // in XLM
  double developerRevenue; // in XLM
  double platformRevenue; // in XLM

  // User Interaction State
  bool isLikedByCurrentUser;
  bool isSavedByCurrentUser;
  bool isOwnedByCurrentUser; // For NFT games
  double? userHighScore;
  int? userPlayTime; // in minutes

  // Game Configuration
  final bool isFreeToPlay;
  final double? price; // in XLM
  final List<String> tags;
  final String? difficulty;
  final int? estimatedPlayTime; // in minutes
  final String? ageRating;

  // Technical Information
  final String? version;
  final DateTime? releaseDate;
  final DateTime? lastUpdated;
  final String? platform; // HTML5, Unity, etc.
  final Map<String, dynamic>? metadata; // Additional game metadata

  // Social Features
  final List<String> leaderboard; // Top player IDs
  final List<String> achievements; // Available achievements
  final bool hasMultiplayer;
  final bool hasLeaderboard;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.gameUrl,
    this.genre,
    required this.developerId,
    required this.developerName,
    this.developerWalletAddress,
    this.smartContractAddress,
    this.gameTokenAddress,
    this.supportedTokens = const ['XLM'],
    this.isNFTEnabled = false,
    this.nftCollectionAddress,
    this.likeCount = 0,
    this.commentCount = 0,
    this.playCount = 0,
    this.totalPlayTime = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.totalRevenue = 0.0,
    this.developerRevenue = 0.0,
    this.platformRevenue = 0.0,
    this.isLikedByCurrentUser = false,
    this.isSavedByCurrentUser = false,
    this.isOwnedByCurrentUser = false,
    this.userHighScore,
    this.userPlayTime,
    this.isFreeToPlay = true,
    this.price,
    this.tags = const [],
    this.difficulty,
    this.estimatedPlayTime,
    this.ageRating,
    this.version,
    this.releaseDate,
    this.lastUpdated,
    this.platform,
    this.metadata,
    this.leaderboard = const [],
    this.achievements = const [],
    this.hasMultiplayer = false,
    this.hasLeaderboard = true,
  });

  /// Creates a GameModel instance from JSON data
  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  /// Converts GameModel instance to JSON format
  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  /// Creates a copy of GameModel with updated fields
  GameModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? gameUrl,
    String? genre,
    String? developerId,
    String? developerName,
    String? developerWalletAddress,
    String? smartContractAddress,
    String? gameTokenAddress,
    List<String>? supportedTokens,
    bool? isNFTEnabled,
    String? nftCollectionAddress,
    int? likeCount,
    int? commentCount,
    int? playCount,
    int? totalPlayTime,
    double? averageRating,
    int? ratingCount,
    double? totalRevenue,
    double? developerRevenue,
    double? platformRevenue,
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
    bool? isOwnedByCurrentUser,
    double? userHighScore,
    int? userPlayTime,
    bool? isFreeToPlay,
    double? price,
    List<String>? tags,
    String? difficulty,
    int? estimatedPlayTime,
    String? ageRating,
    String? version,
    DateTime? releaseDate,
    DateTime? lastUpdated,
    String? platform,
    Map<String, dynamic>? metadata,
    List<String>? leaderboard,
    List<String>? achievements,
    bool? hasMultiplayer,
    bool? hasLeaderboard,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      gameUrl: gameUrl ?? this.gameUrl,
      genre: genre ?? this.genre,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      developerWalletAddress:
          developerWalletAddress ?? this.developerWalletAddress,
      smartContractAddress: smartContractAddress ?? this.smartContractAddress,
      gameTokenAddress: gameTokenAddress ?? this.gameTokenAddress,
      supportedTokens: supportedTokens ?? this.supportedTokens,
      isNFTEnabled: isNFTEnabled ?? this.isNFTEnabled,
      nftCollectionAddress: nftCollectionAddress ?? this.nftCollectionAddress,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      playCount: playCount ?? this.playCount,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      developerRevenue: developerRevenue ?? this.developerRevenue,
      platformRevenue: platformRevenue ?? this.platformRevenue,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? this.isOwnedByCurrentUser,
      userHighScore: userHighScore ?? this.userHighScore,
      userPlayTime: userPlayTime ?? this.userPlayTime,
      isFreeToPlay: isFreeToPlay ?? this.isFreeToPlay,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      estimatedPlayTime: estimatedPlayTime ?? this.estimatedPlayTime,
      ageRating: ageRating ?? this.ageRating,
      version: version ?? this.version,
      releaseDate: releaseDate ?? this.releaseDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      platform: platform ?? this.platform,
      metadata: metadata ?? this.metadata,
      leaderboard: leaderboard ?? this.leaderboard,
      achievements: achievements ?? this.achievements,
      hasMultiplayer: hasMultiplayer ?? this.hasMultiplayer,
      hasLeaderboard: hasLeaderboard ?? this.hasLeaderboard,
    );
  }

  // Helper methods for Web3 functionality
  bool get isBlockchainEnabled => smartContractAddress != null;
  bool get hasCustomToken => gameTokenAddress != null;
  bool get isPremium => !isFreeToPlay && price != null && price! > 0;

  // Get formatted values
  String get formattedPrice =>
      price != null ? '${price!.toStringAsFixed(4)} XLM' : 'Free';
  String get formattedRevenue => '${totalRevenue.toStringAsFixed(4)} XLM';
  String get formattedDeveloperRevenue =>
      '${developerRevenue.toStringAsFixed(4)} XLM';
  String get formattedAverageRating =>
      averageRating > 0 ? averageRating.toStringAsFixed(1) : 'No ratings';
  String get formattedPlayTime {
    if (totalPlayTime < 60) return '${totalPlayTime}m';
    if (totalPlayTime < 1440)
      return '${(totalPlayTime / 60).floor()}h ${totalPlayTime % 60}m';
    return '${(totalPlayTime / 1440).floor()}d ${((totalPlayTime % 1440) / 60).floor()}h';
  }

  // Get user play time in human readable format
  String get formattedUserPlayTime {
    if (userPlayTime == null || userPlayTime == 0) return 'Not played';
    if (userPlayTime! < 60) return '${userPlayTime}m';
    if (userPlayTime! < 1440)
      return '${(userPlayTime! / 60).floor()}h ${userPlayTime! % 60}m';
    return '${(userPlayTime! / 1440).floor()}d ${((userPlayTime! % 1440) / 60).floor()}h';
  }

  // Get estimated play time in human readable format
  String get formattedEstimatedPlayTime {
    if (estimatedPlayTime == null) return 'Unknown';
    if (estimatedPlayTime! < 60) return '${estimatedPlayTime}m';
    if (estimatedPlayTime! < 1440)
      return '${(estimatedPlayTime! / 60).floor()}h ${estimatedPlayTime! % 60}m';
    return '${(estimatedPlayTime! / 1440).floor()}d ${((estimatedPlayTime! % 1440) / 60).floor()}h';
  }

  // Check if user has played this game
  bool get hasUserPlayed => userPlayTime != null && userPlayTime! > 0;

  // Get popularity score based on various metrics
  double get popularityScore {
    return (likeCount * 0.3) +
        (playCount * 0.4) +
        (averageRating * ratingCount * 0.3);
  }

  // Get game status
  String get status {
    if (releaseDate == null) return 'Coming Soon';
    if (DateTime.now().isBefore(releaseDate!)) return 'Coming Soon';
    return 'Available';
  }
}
