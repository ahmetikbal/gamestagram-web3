import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
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

  // Register new user
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

  // Login user
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

  // Try auto-login
  Future<UserModel?> tryAutoLogin() async {
    try {
      firebase_auth.User? firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        print('[AuthService] Found logged in user: ${firebaseUser.email}');
        return await _getUserData(firebaseUser.uid);
      }

      print('[AuthService] No logged in user found');
      return null;
    } catch (e) {
      print('[AuthService] Error during auto-login: $e');
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('[AuthService] User logged out');
    } catch (e) {
      print('[AuthService] Error during logout: $e');
    }
  }
}
