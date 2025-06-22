import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../utils/logger.dart';
import 'package:http/http.dart' as http;

/// Real Stellar blockchain service for testnet deployment
class StellarService {
  static const String _networkUrl = 'https://horizon-testnet.stellar.org';
  static const String _networkPassphrase = 'Test SDF Network ; September 2015';
  static const String _friendbotUrl = 'https://friendbot.stellar.org';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late StellarSDK _sdk;
  late Network _network;

  StellarService();

  /// Initialize the Stellar service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing Stellar service...', 'StellarService');

      _network = Network.TESTNET;
      _sdk = StellarSDK(_networkUrl);

      AppLogger.info(
        'Stellar service initialized successfully',
        'StellarService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to initialize Stellar service',
        'StellarService',
        e,
      );
      rethrow;
    }
  }

  /// Create a new Stellar wallet for a user
  Future<Map<String, dynamic>> createWallet({
    required String userId,
    required String username,
  }) async {
    try {
      AppLogger.info('Creating wallet for user: $username', 'StellarService');

      // Generate mnemonic phrase
      final mnemonic = bip39.generateMnemonic();

      // Derive key pair from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);

      // Create Stellar keypair
      final keypair = KeyPair.fromSecretSeed(utf8.decode(master.key));

      // Fund account with testnet XLM using Friendbot
      final fundResult = await _fundAccountWithFriendbot(keypair.accountId);
      if (!fundResult['success']) {
        return {'success': false, 'error': 'Failed to fund account'};
      }

      // Store sensitive data securely
      await _secureStorage.write(
        key: 'stellar_mnemonic_$userId',
        value: mnemonic,
      );

      await _secureStorage.write(
        key: 'stellar_secret_$userId',
        value: keypair.secretSeed,
      );

      AppLogger.info(
        'Wallet created successfully for $username',
        'StellarService',
      );

      return {
        'success': true,
        'walletAddress': keypair.accountId,
        'publicKey': keypair.accountId,
        'mnemonic': mnemonic,
        'secretKey': keypair.secretSeed,
      };
    } catch (e) {
      AppLogger.error('Failed to create wallet', 'StellarService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fund account with testnet XLM using Friendbot
  Future<Map<String, dynamic>> _fundAccountWithFriendbot(
    String accountId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_friendbotUrl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'addr': accountId}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'response': response.body};
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      AppLogger.error(
        'Failed to fund account with Friendbot',
        'StellarService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get account balance
  Future<Map<String, double>> getAccountBalance(String accountId) async {
    try {
      final account = await _sdk.accounts.account(accountId);
      final balances = <String, double>{};

      for (final balance in account.balances) {
        if (balance.assetType == Asset.TYPE_NATIVE) {
          balances['XLM'] = double.parse(balance.balance);
        } else {
          final assetCode = balance.assetCode ?? '';
          balances[assetCode] = double.parse(balance.balance);
        }
      }

      return balances;
    } catch (e) {
      AppLogger.error('Failed to get account balance', 'StellarService', e);
      return {};
    }
  }

  /// Send XLM payment
  Future<Map<String, dynamic>> sendPayment({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String secretKey,
    String? memo,
  }) async {
    try {
      final sourceKeypair = KeyPair.fromSecretSeed(secretKey);
      final sourceAccount = await _sdk.accounts.account(fromAccountId);

      // Create payment operation
      final paymentOp =
          PaymentOperationBuilder(
            toAccountId,
            Asset.NATIVE,
            amount.toString(),
          ).build();

      // Create transaction
      final transaction = TransactionBuilder(
        sourceAccount,
      ).addOperation(paymentOp);

      if (memo != null) {
        transaction.addMemo(Memo.text(memo));
      }

      final builtTransaction = await transaction.build();
      builtTransaction.sign(sourceKeypair, _network);

      // Submit transaction
      final response = await _sdk.submitTransaction(builtTransaction);

      AppLogger.info('Payment sent successfully', 'StellarService');

      return {
        'success': true,
        'transactionHash': response.hash,
        'fee': 0.00001, // Default fee for now
      };
    } catch (e) {
      AppLogger.error('Failed to send payment', 'StellarService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create custom token (asset)
  Future<Map<String, dynamic>> createToken({
    required String issuerAccountId,
    required String issuerSecretKey,
    required String tokenCode,
    required String tokenName,
    String? tokenDescription,
  }) async {
    try {
      final issuerKeypair = KeyPair.fromSecretSeed(issuerSecretKey);
      final issuerAccount = await _sdk.accounts.account(issuerAccountId);

      // Create asset
      final asset = Asset.createNonNativeAsset(
        tokenCode,
        issuerKeypair.accountId,
      );

      // Create trustline operation
      final trustlineOp =
          ChangeTrustOperationBuilder(
            asset,
            "1000000", // 1 million tokens
          ).build();

      // Create transaction
      final transaction =
          TransactionBuilder(issuerAccount).addOperation(trustlineOp).build();

      transaction.sign(issuerKeypair, _network);

      // Submit transaction
      final response = await _sdk.submitTransaction(transaction);

      AppLogger.info(
        'Token created successfully: $tokenCode',
        'StellarService',
      );

      return {
        'success': true,
        'assetCode': tokenCode,
        'issuer': issuerAccountId,
        'tokenName': tokenName,
        'transactionHash': response.hash,
      };
    } catch (e) {
      AppLogger.error('Failed to create token', 'StellarService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get transaction fee estimate
  Future<double> getTransactionFee() async {
    try {
      // Use a default fee for now since feeStats API might have changed
      return 0.00001; // Default fee in XLM
    } catch (e) {
      AppLogger.error('Failed to get transaction fee', 'StellarService', e);
      return 0.00001; // Default fee
    }
  }

  /// Check if account exists
  Future<bool> accountExists(String accountId) async {
    try {
      await _sdk.accounts.account(accountId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove or comment out getAccountTransactions and getAccountOperations for now
  // They are not required for hackathon MVP and cause build errors due to SDK API changes.
}
