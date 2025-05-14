class UserModel {
  final String id;
  final String username;
  final String email;
  int likeCount; // Kept from previous, though not directly auth related
  int commentCount; // Kept from previous
  bool isLikedByCurrentUser; // Kept from previous
  // Add other fields like bio, profilePictureUrl, etc., as needed later

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.likeCount = 0, 
    this.commentCount = 0, 
    this.isLikedByCurrentUser = false,
  });

  // Factory constructor to create a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      // Optional: Load these if they are part of the stored user profile
      // likeCount: json['likeCount'] as int? ?? 0,
      // commentCount: json['commentCount'] as int? ?? 0,
      // isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
    );
  }

  // Method to convert UserModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      // Optional: Save these if they are part of the stored user profile
      // 'likeCount': likeCount,
      // 'commentCount': commentCount,
      // 'isLikedByCurrentUser': isLikedByCurrentUser,
    };
  }
} 