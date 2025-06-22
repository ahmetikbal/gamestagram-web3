import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/logger.dart';

/// Service for handling Passkey authentication using WebAuthn
class PasskeyService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      AppLogger.error(
        'Failed to check biometric availability',
        'PasskeyService',
        e,
      );
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.error(
        'Failed to get available biometrics',
        'PasskeyService',
        e,
      );
      return [];
    }
  }

  /// Create a new Passkey credential for user registration
  Future<Map<String, dynamic>> createCredential({
    required String userId,
    required String username,
    required String challenge,
  }) async {
    try {
      AppLogger.info(
        'Creating Passkey credential for user: $username',
        'PasskeyService',
      );

      // Generate a unique credential ID
      final credentialId = _generateCredentialId(userId);

      // Create credential data
      final credentialData = {
        'id': credentialId,
        'userId': userId,
        'username': username,
        'challenge': challenge,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Store credential securely
      await _secureStorage.write(
        key: 'passkey_credential_$userId',
        value: jsonEncode(credentialData),
      );

      // Store credential ID for user
      await _secureStorage.write(
        key: 'passkey_credential_id_$userId',
        value: credentialId,
      );

      AppLogger.info(
        'Passkey credential created successfully',
        'PasskeyService',
      );

      return {
        'success': true,
        'credentialId': credentialId,
        'credentialData': credentialData,
      };
    } catch (e) {
      AppLogger.error(
        'Failed to create Passkey credential',
        'PasskeyService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Authenticate user with Passkey
  Future<Map<String, dynamic>> authenticate({
    required String userId,
    required String challenge,
  }) async {
    try {
      AppLogger.info(
        'Authenticating user with Passkey: $userId',
        'PasskeyService',
      );

      // Check if user has a Passkey credential
      final credentialId = await _secureStorage.read(
        key: 'passkey_credential_id_$userId',
      );
      if (credentialId == null) {
        return {
          'success': false,
          'error': 'No Passkey credential found for user',
        };
      }

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate with your biometric credentials',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        return {'success': false, 'error': 'Biometric authentication failed'};
      }

      // Verify challenge (in a real implementation, this would be more complex)
      final isValidChallenge = await _verifyChallenge(userId, challenge);
      if (!isValidChallenge) {
        return {'success': false, 'error': 'Invalid authentication challenge'};
      }

      AppLogger.info('Passkey authentication successful', 'PasskeyService');

      return {
        'success': true,
        'credentialId': credentialId,
        'authenticatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error(
        'Failed to authenticate with Passkey',
        'PasskeyService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get Passkey credential for a user
  Future<Map<String, dynamic>?> getCredential(String userId) async {
    try {
      final credentialData = await _secureStorage.read(
        key: 'passkey_credential_$userId',
      );
      if (credentialData != null) {
        return jsonDecode(credentialData) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get Passkey credential', 'PasskeyService', e);
      return null;
    }
  }

  /// Check if user has a Passkey credential
  Future<bool> hasCredential(String userId) async {
    try {
      final credentialId = await _secureStorage.read(
        key: 'passkey_credential_id_$userId',
      );
      return credentialId != null;
    } catch (e) {
      AppLogger.error(
        'Failed to check Passkey credential',
        'PasskeyService',
        e,
      );
      return false;
    }
  }

  /// Delete Passkey credential for a user
  Future<bool> deleteCredential(String userId) async {
    try {
      await _secureStorage.delete(key: 'passkey_credential_$userId');
      await _secureStorage.delete(key: 'passkey_credential_id_$userId');
      AppLogger.info(
        'Passkey credential deleted for user: $userId',
        'PasskeyService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to delete Passkey credential',
        'PasskeyService',
        e,
      );
      return false;
    }
  }

  /// Generate a unique credential ID
  String _generateCredentialId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$userId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// Verify authentication challenge
  Future<bool> _verifyChallenge(String userId, String challenge) async {
    try {
      // In a real implementation, this would verify the challenge against
      // a server-side challenge or use cryptographic verification
      // For now, we'll do a simple check
      final credential = await getCredential(userId);
      if (credential != null) {
        final storedChallenge = credential['challenge'] as String?;
        return storedChallenge == challenge;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to verify challenge', 'PasskeyService', e);
      return false;
    }
  }

  /// Generate a new authentication challenge
  String generateChallenge() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final data = '$timestamp:$random';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// Get biometric authentication status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final biometrics = await getAvailableBiometrics();

      return {
        'isAvailable': isAvailable,
        'biometricTypes': biometrics.map((type) => type.toString()).toList(),
        'hasFingerprint': biometrics.contains(BiometricType.fingerprint),
        'hasFace': biometrics.contains(BiometricType.face),
        'hasIris': biometrics.contains(BiometricType.iris),
      };
    } catch (e) {
      AppLogger.error('Failed to get biometric status', 'PasskeyService', e);
      return {
        'isAvailable': false,
        'biometricTypes': [],
        'hasFingerprint': false,
        'hasFace': false,
        'hasIris': false,
      };
    }
  }
}
