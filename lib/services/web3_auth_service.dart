import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/user_model.dart';
import 'passkey_service.dart';
import 'stellar_service.dart';
import '../utils/logger.dart';

/// Service for handling Web3 authentication with Passkey and Stellar wallet
class Web3AuthService {
  final PasskeyService _passkeyService = PasskeyService();
  final StellarService _stellarService = StellarService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Initialize the service
  Future<void> initialize() async {
    await _stellarService.initialize();
  }

  /// Register a new user with Web3 authentication
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
  }) async {
    try {
      AppLogger.info('Registering new Web3 user: $username', 'Web3AuthService');

      // Generate unique user ID
      final userId = _generateUserId(username, email);

      // Create Passkey credential
      final challenge = _passkeyService.generateChallenge();
      final passkeyResult = await _passkeyService.createCredential(
        userId: userId,
        username: username,
        challenge: challenge,
      );
      if (!passkeyResult['success']) {
        return {
          'success': false,
          'message': 'Failed to create Passkey credential',
        };
      }

      // Create Stellar wallet
      final walletResult = await _stellarService.createWallet(
        userId: userId,
        username: username,
      );
      if (!walletResult['success']) {
        // Clean up Passkey credential if wallet creation fails
        await _passkeyService.deleteCredential(userId);
        return {'success': false, 'message': 'Failed to create Stellar wallet'};
      }

      // Store userId for session
      await _secureStorage.write(key: 'current_user_id', value: userId);
      await _secureStorage.write(
        key: 'current_wallet_address',
        value: walletResult['walletAddress'],
      );

      AppLogger.info(
        'Web3 user registered successfully: $username',
        'Web3AuthService',
      );

      return {
        'success': true,
        'message': 'Registration successful',
        'walletAddress': walletResult['walletAddress'],
        'publicKey': walletResult['publicKey'],
        'mnemonic': walletResult['mnemonic'],
      };
    } catch (e) {
      AppLogger.error('Failed to register Web3 user', 'Web3AuthService', e);
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  /// Login user with Web3 authentication
  Future<Map<String, dynamic>> login({required String walletAddress}) async {
    try {
      AppLogger.info('Logging in Web3 user: $walletAddress', 'Web3AuthService');

      // Check if user has Passkey credential
      final userId = await _secureStorage.read(key: 'current_user_id');
      if (userId == null) {
        return {
          'success': false,
          'message': 'No Passkey credential found. Please re-register.',
        };
      }
      final hasCredential = await _passkeyService.hasCredential(userId);
      if (!hasCredential) {
        return {
          'success': false,
          'message': 'No Passkey credential found. Please re-register.',
        };
      }

      // Authenticate with Passkey
      final challenge = _passkeyService.generateChallenge();
      final authResult = await _passkeyService.authenticate(
        userId: userId,
        challenge: challenge,
      );
      if (!authResult['success']) {
        return {
          'success': false,
          'message': 'Authentication failed: ${authResult['error']}',
        };
      }

      // Fetch account from Stellar
      final balance = await _stellarService.getAccountBalance(walletAddress);
      AppLogger.info(
        'Web3 user logged in successfully: $walletAddress',
        'Web3AuthService',
      );
      await _secureStorage.write(
        key: 'current_wallet_address',
        value: walletAddress,
      );
      return {
        'success': true,
        'message': 'Login successful',
        'walletAddress': walletAddress,
        'balance': balance,
      };
    } catch (e) {
      AppLogger.error('Failed to login Web3 user', 'Web3AuthService', e);
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: 'current_user_id');
      await _secureStorage.delete(key: 'current_wallet_address');
      AppLogger.info('User logged out successfully', 'Web3AuthService');
    } catch (e) {
      AppLogger.error('Failed to logout user', 'Web3AuthService', e);
    }
  }

  /// Get current wallet address
  Future<String?> getCurrentWalletAddress() async {
    return await _secureStorage.read(key: 'current_wallet_address');
  }

  /// Generate unique user ID
  String _generateUserId(String username, String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$username:$email:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
}
