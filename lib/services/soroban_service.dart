import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service for handling Soroban smart contract interactions
class SorobanService {
  static const String _testnetUrl = 'https://soroban-testnet.stellar.org';
  static const String _mainnetUrl = 'https://soroban.stellar.org';

  final String _baseUrl;
  final http.Client _httpClient = http.Client();

  SorobanService({bool isTestnet = true})
    : _baseUrl = isTestnet ? _testnetUrl : _mainnetUrl;

  /// Deploy a smart contract to Soroban
  Future<Map<String, dynamic>> deployContract({
    required String wasmBytes,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Deploying smart contract to Soroban...',
        'SorobanService',
      );

      // In a real implementation, this would use the Soroban SDK
      // For now, we'll simulate the deployment process

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/contracts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secretKey',
        },
        body: jsonEncode({'wasm': wasmBytes, 'source_account': sourceAccount}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          'Smart contract deployed successfully',
          'SorobanService',
        );

        return {
          'success': true,
          'contractId': data['contract_id'],
          'transactionHash': data['transaction_hash'],
        };
      } else {
        throw Exception('Failed to deploy contract: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to deploy smart contract', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Call a smart contract function
  Future<Map<String, dynamic>> callContract({
    required String contractId,
    required String functionName,
    required List<dynamic> arguments,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Calling smart contract function: $functionName',
        'SorobanService',
      );

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/contracts/$contractId/call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secretKey',
        },
        body: jsonEncode({
          'function': functionName,
          'arguments': arguments,
          'source_account': sourceAccount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Smart contract call successful', 'SorobanService');

        return {
          'success': true,
          'result': data['result'],
          'transactionHash': data['transaction_hash'],
        };
      } else {
        throw Exception('Failed to call contract: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to call smart contract', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Award tokens to a player for completing a game
  Future<Map<String, dynamic>> awardGameTokens({
    required String contractId,
    required String playerAddress,
    required double amount,
    required String gameId,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Awarding tokens to player: $playerAddress',
        'SorobanService',
      );

      final result = await callContract(
        contractId: contractId,
        functionName: 'award_tokens',
        arguments: [playerAddress, amount.toString(), gameId],
        sourceAccount: sourceAccount,
        secretKey: secretKey,
      );

      if (result['success']) {
        AppLogger.info('Tokens awarded successfully', 'SorobanService');
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to award game tokens', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Distribute revenue to game developer
  Future<Map<String, dynamic>> distributeDeveloperRevenue({
    required String contractId,
    required String developerAddress,
    required double amount,
    required String gameId,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Distributing revenue to developer: $developerAddress',
        'SorobanService',
      );

      final result = await callContract(
        contractId: contractId,
        functionName: 'distribute_revenue',
        arguments: [developerAddress, amount.toString(), gameId],
        sourceAccount: sourceAccount,
        secretKey: secretKey,
      );

      if (result['success']) {
        AppLogger.info('Revenue distributed successfully', 'SorobanService');
      }

      return result;
    } catch (e) {
      AppLogger.error(
        'Failed to distribute developer revenue',
        'SorobanService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Record game completion and calculate rewards
  Future<Map<String, dynamic>> recordGameCompletion({
    required String contractId,
    required String playerAddress,
    required String gameId,
    required int playTime,
    required double score,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Recording game completion for player: $playerAddress',
        'SorobanService',
      );

      final result = await callContract(
        contractId: contractId,
        functionName: 'record_completion',
        arguments: [
          playerAddress,
          gameId,
          playTime.toString(),
          score.toString(),
        ],
        sourceAccount: sourceAccount,
        secretKey: secretKey,
      );

      if (result['success']) {
        AppLogger.info(
          'Game completion recorded successfully',
          'SorobanService',
        );
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to record game completion', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get player statistics from smart contract
  Future<Map<String, dynamic>> getPlayerStats({
    required String contractId,
    required String playerAddress,
  }) async {
    try {
      AppLogger.info(
        'Getting player stats for: $playerAddress',
        'SorobanService',
      );

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/contracts/$contractId/query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Player stats retrieved successfully', 'SorobanService');

        return {'success': true, 'stats': data['player_stats']};
      } else {
        throw Exception('Failed to get player stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to get player stats', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get game statistics from smart contract
  Future<Map<String, dynamic>> getGameStats({
    required String contractId,
    required String gameId,
  }) async {
    try {
      AppLogger.info('Getting game stats for: $gameId', 'SorobanService');

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/contracts/$contractId/game_stats/$gameId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Game stats retrieved successfully', 'SorobanService');

        return {'success': true, 'stats': data['game_stats']};
      } else {
        throw Exception('Failed to get game stats: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to get game stats', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a staking pool for developers
  Future<Map<String, dynamic>> createStakingPool({
    required String contractId,
    required String developerAddress,
    required double initialAmount,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Creating staking pool for developer: $developerAddress',
        'SorobanService',
      );

      final result = await callContract(
        contractId: contractId,
        functionName: 'create_staking_pool',
        arguments: [developerAddress, initialAmount.toString()],
        sourceAccount: sourceAccount,
        secretKey: secretKey,
      );

      if (result['success']) {
        AppLogger.info('Staking pool created successfully', 'SorobanService');
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to create staking pool', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stake tokens in a developer pool
  Future<Map<String, dynamic>> stakeTokens({
    required String contractId,
    required String developerAddress,
    required double amount,
    required String sourceAccount,
    required String secretKey,
  }) async {
    try {
      AppLogger.info(
        'Staking tokens in pool: $developerAddress',
        'SorobanService',
      );

      final result = await callContract(
        contractId: contractId,
        functionName: 'stake_tokens',
        arguments: [developerAddress, amount.toString()],
        sourceAccount: sourceAccount,
        secretKey: secretKey,
      );

      if (result['success']) {
        AppLogger.info('Tokens staked successfully', 'SorobanService');
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to stake tokens', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get contract information
  Future<Map<String, dynamic>> getContractInfo(String contractId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/contracts/$contractId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'contractInfo': data};
      } else {
        throw Exception('Failed to get contract info: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to get contract info', 'SorobanService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Close HTTP client
  void dispose() {
    _httpClient.close();
  }
}
