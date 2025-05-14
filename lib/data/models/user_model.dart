class UserModel {
  final String id;
  final String username;
  final String email;
  // Add other fields like bio, profilePictureUrl, etc., as needed later

  UserModel({
    required this.id,
    required this.username,
    required this.email,
  });

  // Optional: Factory constructor for JSON parsing if we connect to a real backend
  // factory UserModel.fromJson(Map<String, dynamic> json) {
  //   return UserModel(
  //     id: json['id'],
  //     username: json['username'],
  //     email: json['email'],
  //   );
  // }

  // Optional: Method to convert to JSON
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'username': username,
  //     'email': email,
  //   };
  // }
} 