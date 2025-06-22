// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String?,
  gameUrl: json['gameUrl'] as String?,
  genre: json['genre'] as String?,
  developerId: json['developerId'] as String,
  developerName: json['developerName'] as String,
  developerWalletAddress: json['developerWalletAddress'] as String?,
  smartContractAddress: json['smartContractAddress'] as String?,
  gameTokenAddress: json['gameTokenAddress'] as String?,
  supportedTokens:
      (json['supportedTokens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['XLM'],
  isNFTEnabled: json['isNFTEnabled'] as bool? ?? false,
  nftCollectionAddress: json['nftCollectionAddress'] as String?,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  playCount: (json['playCount'] as num?)?.toInt() ?? 0,
  totalPlayTime: (json['totalPlayTime'] as num?)?.toInt() ?? 0,
  averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
  ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
  totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
  developerRevenue: (json['developerRevenue'] as num?)?.toDouble() ?? 0.0,
  platformRevenue: (json['platformRevenue'] as num?)?.toDouble() ?? 0.0,
  isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
  isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool? ?? false,
  isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool? ?? false,
  userHighScore: (json['userHighScore'] as num?)?.toDouble(),
  userPlayTime: (json['userPlayTime'] as num?)?.toInt(),
  isFreeToPlay: json['isFreeToPlay'] as bool? ?? true,
  price: (json['price'] as num?)?.toDouble(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  difficulty: json['difficulty'] as String?,
  estimatedPlayTime: (json['estimatedPlayTime'] as num?)?.toInt(),
  ageRating: json['ageRating'] as String?,
  version: json['version'] as String?,
  releaseDate:
      json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
  lastUpdated:
      json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
  platform: json['platform'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  leaderboard:
      (json['leaderboard'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  hasMultiplayer: json['hasMultiplayer'] as bool? ?? false,
  hasLeaderboard: json['hasLeaderboard'] as bool? ?? true,
);

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'gameUrl': instance.gameUrl,
  'genre': instance.genre,
  'developerId': instance.developerId,
  'developerName': instance.developerName,
  'developerWalletAddress': instance.developerWalletAddress,
  'smartContractAddress': instance.smartContractAddress,
  'gameTokenAddress': instance.gameTokenAddress,
  'supportedTokens': instance.supportedTokens,
  'isNFTEnabled': instance.isNFTEnabled,
  'nftCollectionAddress': instance.nftCollectionAddress,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'playCount': instance.playCount,
  'totalPlayTime': instance.totalPlayTime,
  'averageRating': instance.averageRating,
  'ratingCount': instance.ratingCount,
  'totalRevenue': instance.totalRevenue,
  'developerRevenue': instance.developerRevenue,
  'platformRevenue': instance.platformRevenue,
  'isLikedByCurrentUser': instance.isLikedByCurrentUser,
  'isSavedByCurrentUser': instance.isSavedByCurrentUser,
  'isOwnedByCurrentUser': instance.isOwnedByCurrentUser,
  'userHighScore': instance.userHighScore,
  'userPlayTime': instance.userPlayTime,
  'isFreeToPlay': instance.isFreeToPlay,
  'price': instance.price,
  'tags': instance.tags,
  'difficulty': instance.difficulty,
  'estimatedPlayTime': instance.estimatedPlayTime,
  'ageRating': instance.ageRating,
  'version': instance.version,
  'releaseDate': instance.releaseDate?.toIso8601String(),
  'lastUpdated': instance.lastUpdated?.toIso8601String(),
  'platform': instance.platform,
  'metadata': instance.metadata,
  'leaderboard': instance.leaderboard,
  'achievements': instance.achievements,
  'hasMultiplayer': instance.hasMultiplayer,
  'hasLeaderboard': instance.hasLeaderboard,
};
