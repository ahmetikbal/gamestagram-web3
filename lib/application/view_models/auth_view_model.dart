import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Adjust path
import '../../data/models/user_model.dart'; // Adjust path
import '../../utils/logger.dart';

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
      AppLogger.info('Auto-login successful. User: ${_currentUser?.username}', 'AuthViewModel');
    } else {
      AppLogger.warning('Auto-login failed or no saved user.', 'AuthViewModel');
    }
    _setLoading(false);
    notifyListeners(); // Notify listeners regardless of outcome to update UI
  }

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
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();
    
    print('[AuthViewModel] Updating profile for user: ${_currentUser!.username}');
    
    final response = await _authService.updateProfile(
      userId: _currentUser!.id,
      username: username,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    _setLoading(false);
    
    if (response['success']) {
      // Update the current user data
      _currentUser = _currentUser!.copyWith(
        username: username,
        email: email,
      );
      print('[AuthViewModel] Profile update successful. Updated user: ${_currentUser?.username}');
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['message'];
      print('[AuthViewModel] Profile update error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }
}
