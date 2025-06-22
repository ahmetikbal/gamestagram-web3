import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Represents a user with their profile information, interaction statistics, and Web3 features
@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String email;

  // Web3 and Stellar Blockchain Fields
  final String? stellarWalletAddress;
  final String? publicKey;
  final bool isWalletCreated;
  final double xlmBalance;
  final double gameTokenBalance;
  final List<String> ownedNFTs;
  final String? passkeyCredentialId;

  // Game Interaction Statistics
  int likeCount;
  int commentCount;
  int gamesPlayed;
  int totalPlayTime; // in minutes
  int achievementsUnlocked;
  double totalEarnings; // in XLM

  // Social Features
  bool isLikedByCurrentUser;
  List<String> following;
  List<String> followers;

  // Developer Specific Fields
  final bool isDeveloper;
  final List<String> publishedGames;
  final double developerEarnings;
  final int totalDownloads;

  // Profile Information
  final String? profilePictureUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? lastActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.stellarWalletAddress,
    this.publicKey,
    this.isWalletCreated = false,
    this.xlmBalance = 0.0,
    this.gameTokenBalance = 0.0,
    this.ownedNFTs = const [],
    this.passkeyCredentialId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.gamesPlayed = 0,
    this.totalPlayTime = 0,
    this.achievementsUnlocked = 0,
    this.totalEarnings = 0.0,
    this.isLikedByCurrentUser = false,
    this.following = const [],
    this.followers = const [],
    this.isDeveloper = false,
    this.publishedGames = const [],
    this.developerEarnings = 0.0,
    this.totalDownloads = 0,
    this.profilePictureUrl,
    this.bio,
    this.createdAt,
    this.lastActive,
  });

  // Factory constructor to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Method to convert UserModel instance to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Method to create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? stellarWalletAddress,
    String? publicKey,
    bool? isWalletCreated,
    double? xlmBalance,
    double? gameTokenBalance,
    List<String>? ownedNFTs,
    String? passkeyCredentialId,
    int? likeCount,
    int? commentCount,
    int? gamesPlayed,
    int? totalPlayTime,
    int? achievementsUnlocked,
    double? totalEarnings,
    bool? isLikedByCurrentUser,
    List<String>? following,
    List<String>? followers,
    bool? isDeveloper,
    List<String>? publishedGames,
    double? developerEarnings,
    int? totalDownloads,
    String? profilePictureUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      stellarWalletAddress: stellarWalletAddress ?? this.stellarWalletAddress,
      publicKey: publicKey ?? this.publicKey,
      isWalletCreated: isWalletCreated ?? this.isWalletCreated,
      xlmBalance: xlmBalance ?? this.xlmBalance,
      gameTokenBalance: gameTokenBalance ?? this.gameTokenBalance,
      ownedNFTs: ownedNFTs ?? this.ownedNFTs,
      passkeyCredentialId: passkeyCredentialId ?? this.passkeyCredentialId,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isDeveloper: isDeveloper ?? this.isDeveloper,
      publishedGames: publishedGames ?? this.publishedGames,
      developerEarnings: developerEarnings ?? this.developerEarnings,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Helper methods for Web3 functionality
  bool get hasWallet => stellarWalletAddress != null && isWalletCreated;
  bool get hasPasskey => passkeyCredentialId != null;
  bool get isActive =>
      lastActive != null && DateTime.now().difference(lastActive!).inDays < 7;

  // Get formatted balance strings
  String get formattedXlmBalance => '${xlmBalance.toStringAsFixed(4)} XLM';
  String get formattedGameTokenBalance =>
      '${gameTokenBalance.toStringAsFixed(2)} GAME';
  String get formattedTotalEarnings =>
      '${totalEarnings.toStringAsFixed(4)} XLM';
  String get formattedDeveloperEarnings =>
      '${developerEarnings.toStringAsFixed(4)} XLM';

  // Get play time in human readable format
  String get formattedPlayTime {
    if (totalPlayTime < 60) return '${totalPlayTime}m';
    if (totalPlayTime < 1440)
      return '${(totalPlayTime / 60).floor()}h ${totalPlayTime % 60}m';
    return '${(totalPlayTime / 1440).floor()}d ${((totalPlayTime % 1440) / 60).floor()}h';
  }
}
