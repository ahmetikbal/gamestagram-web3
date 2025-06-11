import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Adjust path
import '../../data/models/user_model.dart'; // Adjust path
import '../../utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor to try auto-login when the ViewModel is created
  AuthViewModel() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    _setLoading(true); // Indicate loading during auto-login attempt
    AppLogger.debug('Attempting auto-login...', 'AuthViewModel');
    final user = await _authService.tryAutoLogin();
    if (user != null) {
      _currentUser = user;
      AppLogger.info(
        'Auto-login successful. User: ${_currentUser?.username}',
        'AuthViewModel',
      );
    } else {
      AppLogger.warning('Auto-login failed or no saved user.', 'AuthViewModel');
    }
    _setLoading(false);
    notifyListeners(); // Notify listeners regardless of outcome to update UI
  }

  //Helper methods to manage loading and error states
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // notifyListeners(); // Only notify if there was an error to clear visually
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    print('[AuthViewModel] Calling AuthService.register for $email');
    final response = await _authService.register(
      username: username,
      email: email,
      password: password,
    );
    print('[AuthViewModel] Response from AuthService.register: $response');
    _setLoading(false);

    if (response['success']) {
      // Optionally set _currentUser if auto-login after registration (SRS 3.2.1.4)
      // _currentUser = response['user'];
      // For now, just return true, UI will navigate to login
      notifyListeners(); // If currentUser or other state changes
      return true;
    } else {
      _errorMessage = response['message'];
      print('[AuthViewModel] Registration error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    print('[AuthViewModel] Calling AuthService.login for $emailOrUsername');
    final response = await _authService.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );
    print('[AuthViewModel] Response from AuthService.login: $response');
    // _setLoading(false); // Moved after potential currentUser update to avoid race condition with UI

    if (response['success']) {
      _currentUser = response['user'];
      _setLoading(false); // Set loading false after state update
      print(
        '[AuthViewModel] Login success. CurrentUser set to: ${_currentUser?.username} (ID: ${_currentUser?.id})',
      );
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['message'];
      _setLoading(false); // Set loading false after state update
      print('[AuthViewModel] Login error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    print('[AuthViewModel] Logging out user: ${_currentUser?.username}');
    await _authService
        .logout(); // This now clears SharedPreferences via AuthService
    _currentUser = null;
    _setLoading(false);
    print('[AuthViewModel] User logged out. CurrentUser is now: $_currentUser');
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
    required String currentPassword,
    String? newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Verify current password is correct before making changes
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = 'User not logged in';
        _setLoading(false);
        return false;
      }

      // Create credential to re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);

      // 1. Update Auth email if changed
      if (email != user.email) {
        await user.updateEmail(email);
      }

      // 2. Update password if provided
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      // 3. Update Firestore user document
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({
            'username': username,
            'email': email,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // 4. Update local user data
      _currentUser = _currentUser?.copyWith(username: username, email: email);

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      AppLogger.error('Profile update error: $e', 'AuthViewModel');
      _errorMessage = _getErrorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  // Helper method to parse Firebase errors
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
          return 'Current password is incorrect';
        case 'requires-recent-login':
          return 'Please log in again before updating your profile';
        case 'email-already-in-use':
          return 'This email is already in use by another account';
        default:
          return error.message ?? 'An unknown error occurred';
      }
    }
    return error.toString();
  }
}
