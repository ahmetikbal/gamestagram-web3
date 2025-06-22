// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  stellarWalletAddress: json['stellarWalletAddress'] as String?,
  publicKey: json['publicKey'] as String?,
  isWalletCreated: json['isWalletCreated'] as bool? ?? false,
  xlmBalance: (json['xlmBalance'] as num?)?.toDouble() ?? 0.0,
  gameTokenBalance: (json['gameTokenBalance'] as num?)?.toDouble() ?? 0.0,
  ownedNFTs:
      (json['ownedNFTs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  passkeyCredentialId: json['passkeyCredentialId'] as String?,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
  totalPlayTime: (json['totalPlayTime'] as num?)?.toInt() ?? 0,
  achievementsUnlocked: (json['achievementsUnlocked'] as num?)?.toInt() ?? 0,
  totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
  isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
  following:
      (json['following'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  followers:
      (json['followers'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isDeveloper: json['isDeveloper'] as bool? ?? false,
  publishedGames:
      (json['publishedGames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  developerEarnings: (json['developerEarnings'] as num?)?.toDouble() ?? 0.0,
  totalDownloads: (json['totalDownloads'] as num?)?.toInt() ?? 0,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  bio: json['bio'] as String?,
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  lastActive:
      json['lastActive'] == null
          ? null
          : DateTime.parse(json['lastActive'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'stellarWalletAddress': instance.stellarWalletAddress,
  'publicKey': instance.publicKey,
  'isWalletCreated': instance.isWalletCreated,
  'xlmBalance': instance.xlmBalance,
  'gameTokenBalance': instance.gameTokenBalance,
  'ownedNFTs': instance.ownedNFTs,
  'passkeyCredentialId': instance.passkeyCredentialId,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'gamesPlayed': instance.gamesPlayed,
  'totalPlayTime': instance.totalPlayTime,
  'achievementsUnlocked': instance.achievementsUnlocked,
  'totalEarnings': instance.totalEarnings,
  'isLikedByCurrentUser': instance.isLikedByCurrentUser,
  'following': instance.following,
  'followers': instance.followers,
  'isDeveloper': instance.isDeveloper,
  'publishedGames': instance.publishedGames,
  'developerEarnings': instance.developerEarnings,
  'totalDownloads': instance.totalDownloads,
  'profilePictureUrl': instance.profilePictureUrl,
  'bio': instance.bio,
  'createdAt': instance.createdAt?.toIso8601String(),
  'lastActive': instance.lastActive?.toIso8601String(),
};
