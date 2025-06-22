import 'package:flutter/foundation.dart';
import '../../services/web3_auth_service.dart';
import '../../services/passkey_service.dart';
import '../../utils/logger.dart';

/// ViewModel for handling Web3 authentication state
class Web3AuthViewModel extends ChangeNotifier {
  final Web3AuthService _authService = Web3AuthService();
  final PasskeyService _passkeyService = PasskeyService();

  String? _walletAddress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  Map<String, dynamic>? _biometricStatus;

  // Getters
  String? get walletAddress => _walletAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _walletAddress != null;
  bool get isBiometricAvailable => _isBiometricAvailable;
  Map<String, dynamic>? get biometricStatus => _biometricStatus;

  /// Initialize the Web3 authentication
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();
      await _checkBiometricAvailability();
      _walletAddress = await _authService.getCurrentWalletAddress();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Register a new user with Web3 authentication
  Future<bool> register({
    required String username,
    required String email,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Registering new user: $username', 'Web3AuthViewModel');
      final result = await _authService.register(
        username: username,
        email: email,
      );
      if (result['success']) {
        _walletAddress = result['walletAddress'] as String?;
        AppLogger.info(
          'User registered successfully: $_walletAddress',
          'Web3AuthViewModel',
        );
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login user with Web3 authentication
  Future<bool> login({required String walletAddress}) async {
    try {
      _setLoading(true);
      _clearError();
      AppLogger.info('Logging in user: $walletAddress', 'Web3AuthViewModel');
      final result = await _authService.login(walletAddress: walletAddress);
      if (result['success']) {
        _walletAddress = walletAddress;
        AppLogger.info(
          'User logged in successfully: $_walletAddress',
          'Web3AuthViewModel',
        );
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();
      await _authService.logout();
      _walletAddress = null;
      AppLogger.info('User logged out successfully', 'Web3AuthViewModel');
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Check biometric availability
  Future<void> _checkBiometricAvailability() async {
    try {
      _isBiometricAvailable = await _passkeyService.isBiometricAvailable();
      _biometricStatus = await _passkeyService.getBiometricStatus();
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Failed to check biometric availability',
        'Web3AuthViewModel',
        e,
      );
      _isBiometricAvailable = false;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    AppLogger.error('Web3AuthViewModel error: $error', 'Web3AuthViewModel');
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message manually
  void clearError() {
    _clearError();
  }
}
