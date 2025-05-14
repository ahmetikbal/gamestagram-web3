import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Adjust path
import '../../data/models/user_model.dart'; // Adjust path

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
    final response = await _authService.register(
      username: username,
      email: email,
      password: password,
    );
    _setLoading(false);

    if (response['success']) {
      // Optionally set _currentUser if auto-login after registration (SRS 3.2.1.4)
      // _currentUser = response['user'];
      // For now, just return true, UI will navigate to login
      notifyListeners(); // If currentUser or other state changes
      return true;
    } else {
      _errorMessage = response['message'];
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
    final response = await _authService.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );
    _setLoading(false);

    if (response['success']) {
      _currentUser = response['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }
} 