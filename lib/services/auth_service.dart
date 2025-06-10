import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

/// Service for handling user authentication and session management
/// Uses Firebase Auth and Firestore for user management
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user data from Firestore
  Future<UserModel?> _getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel(
          id: uid,
          username: data['username'] ?? '',
          email: data['email'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('[AuthService] Error getting user data: $e');
      return null;
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print(
        '[AuthService] Attempting to register: $email, Username: $username',
      );

      // Check if username already exists in Firestore
      QuerySnapshot usernameQuery =
          await _firestore
              .collection('Users')
              .where('username', isEqualTo: username)
              .get();

      if (usernameQuery.docs.isNotEmpty) {
        return {'success': false, 'message': 'Username already taken'};
      }

      // Create user with Firebase Auth
      firebase_auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'likedGames': [],
        'savedGames': [],
        'likeCount': 0,
        'commentCount': 0,
      });

      // Create and return user model
      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        username: username,
        email: email,
      );

      print('[AuthService] Registration successful for $email');
      return {
        'success': true,
        'message': 'Registration successful',
        'user': newUser,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }

      print('[AuthService] Registration error: $errorMessage');
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('[AuthService] Unexpected error during registration: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Login user with email/username and password
  Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      print('[AuthService] Attempting login for: $emailOrUsername');

      String email = emailOrUsername;

      // If user entered a username instead of email, find the email
      if (!emailOrUsername.contains('@')) {
        QuerySnapshot userQuery =
            await _firestore
                .collection('Users')
                .where('username', isEqualTo: emailOrUsername)
                .limit(1)
                .get();

        if (userQuery.docs.isEmpty) {
          return {'success': false, 'message': 'Invalid username or password'};
        }

        email = userQuery.docs.first.get('email') as String;
      }

      // Sign in with Firebase Auth
      firebase_auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Get user data from Firestore
      UserModel? user = await _getUserData(userCredential.user!.uid);

      if (user == null) {
        return {'success': false, 'message': 'User data not found'};
      }

      print('[AuthService] Login successful for ${user.username}');
      return {'success': true, 'message': 'Login successful', 'user': user};
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid email/username or password';
      } else {
        errorMessage = 'Login failed: ${e.message}';
      }

      print('[AuthService] Login error: $errorMessage');
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('[AuthService] Unexpected error during login: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      firebase_auth.User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return await _getUserData(firebaseUser.uid);
      }
      return null;
    } catch (e) {
      print('[AuthService] Error getting current user: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('[AuthService] User logged out successfully');
    } catch (e) {
      print('[AuthService] Error during logout: $e');
    }
  }

  /// Try auto-login for existing user
  Future<UserModel?> tryAutoLogin() async {
    try {
      return await getCurrentUser();
    } catch (e) {
      print('[AuthService] Error during auto-login: $e');
      return null;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String username,
    required String email,
    required String currentPassword,
    String? newPassword,
  }) async {
    try {
      print('[AuthService] Updating profile for user: $userId');
      
      firebase_auth.User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null || firebaseUser.uid != userId) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Verify current password by re-authenticating
      firebase_auth.AuthCredential credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      
      await firebaseUser.reauthenticateWithCredential(credential);

      // Check if username is already taken (if changed)
      if (username != firebaseUser.displayName) {
        QuerySnapshot usernameQuery = await _firestore
            .collection('Users')
            .where('username', isEqualTo: username)
            .get();

        // Remove current user from results
        var existingUsers = usernameQuery.docs.where((doc) => doc.id != userId).toList();
        if (existingUsers.isNotEmpty) {
          return {'success': false, 'message': 'Username already taken'};
        }
      }

      // Update email if changed
      if (email != firebaseUser.email) {
        await firebaseUser.updateEmail(email);
      }

      // Update password if provided
      if (newPassword != null && newPassword.isNotEmpty) {
        await firebaseUser.updatePassword(newPassword);
      }

      // Update user document in Firestore
      await _firestore.collection('Users').doc(userId).update({
        'username': username,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[AuthService] Profile update successful for user: $userId');
      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already in use by another account';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please re-login and try again';
      } else {
        errorMessage = 'Update failed: ${e.message}';
      }
      
      print('[AuthService] Profile update error: $errorMessage');
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('[AuthService] Unexpected error during profile update: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
