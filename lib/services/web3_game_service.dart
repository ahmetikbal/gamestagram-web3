import 'dart:convert';
import 'dart:math';
import '../data/models/game_model.dart';
import '../data/models/user_model.dart';
import 'stellar_service.dart';
import 'soroban_service.dart';
import 'launchtube_service.dart';
import '../utils/logger.dart';

/// Service for handling Web3 game interactions and blockchain operations
class Web3GameService {
  final StellarService _stellarService = StellarService();
  final SorobanService _sorobanService = SorobanService();
  final LaunchtubeService _launchtubeService = LaunchtubeService();

  // Platform wallet for collecting fees and distributing rewards
  static const String _platformWalletAddress =
      'GPLATFORM123456789012345678901234567890123456789012345678901234567890';
  static const String _platformSecretKey =
      'SAMPLE_SECRET_KEY_FOR_PLATFORM_WALLET';

  // Smart contract addresses (in a real app, these would be deployed contracts)
  static const String _gameRewardsContract =
      'CONTRACT_GAME_REWARDS_123456789012345678901234567890123456789012345678901234567890';
  static const String _developerPaymentsContract =
      'CONTRACT_DEV_PAYMENTS_123456789012345678901234567890123456789012345678901234567890';

  /// Start a game session and record it on blockchain
  Future<Map<String, dynamic>> startGameSession({
    required String gameId,
    required UserModel player,
    required String gameUrl,
  }) async {
    try {
      AppLogger.info(
        'Starting game session for player: ${player.username}',
        'Web3GameService',
      );

      // Record game start in smart contract
      final sessionResult = await _sorobanService.callContract(
        contractId: _gameRewardsContract,
        functionName: 'start_game_session',
        arguments: [
          player.stellarWalletAddress!,
          gameId,
          DateTime.now().millisecondsSinceEpoch.toString(),
        ],
        sourceAccount: _platformWalletAddress,
        secretKey: _platformSecretKey,
      );

      if (!sessionResult['success']) {
        return {
          'success': false,
          'message': 'Failed to start game session on blockchain',
        };
      }

      AppLogger.info('Game session started successfully', 'Web3GameService');

      return {
        'success': true,
        'sessionId': sessionResult['result']['session_id'],
        'gameUrl': gameUrl,
        'startTime': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('Failed to start game session', 'Web3GameService', e);
      return {
        'success': false,
        'message': 'Failed to start game session: ${e.toString()}',
      };
    }
  }

  /// Complete a game session and award rewards
  Future<Map<String, dynamic>> completeGameSession({
    required String gameId,
    required UserModel player,
    required int playTimeMinutes,
    required double score,
    List<String> achievementsUnlocked = const [],
  }) async {
    try {
      AppLogger.info(
        'Completing game session for: ${player.username}',
        'Web3GameService',
      );

      final sessionId = _generateSessionId();
      final rewards = _calculateRewards(
        playTimeMinutes,
        score,
        achievementsUnlocked,
      );

      // Award tokens to player (mock implementation)
      final awardResult = await _stellarService.sendPayment(
        fromAccountId: _platformWalletAddress,
        toAccountId: player.stellarWalletAddress ?? '',
        amount: rewards['xlmReward'] ?? 0.0,
        secretKey: _platformSecretKey,
        memo: 'Game reward: $gameId',
      );

      if (!awardResult['success']) {
        return {'success': false, 'message': 'Failed to award tokens'};
      }

      // Issue GAME tokens if available (mock implementation)
      if ((rewards['gameTokenReward'] ?? 0) > 0) {
        // For now, just log the token issuance
        AppLogger.info(
          'Would issue ${rewards['gameTokenReward']} GAME tokens',
          'Web3GameService',
        );
      }

      AppLogger.info('Game session completed successfully', 'Web3GameService');

      return {
        'success': true,
        'sessionId': sessionId,
        'playTime': playTimeMinutes,
        'score': score,
        'achievementsUnlocked': achievementsUnlocked,
        'rewards': rewards,
        'transactionHash': awardResult['transactionHash'],
      };
    } catch (e) {
      AppLogger.error('Failed to complete game session', 'Web3GameService', e);
      return {
        'success': false,
        'message': 'Failed to complete game session: ${e.toString()}',
      };
    }
  }

  /// Purchase a premium game
  Future<Map<String, dynamic>> purchaseGame({
    required GameModel game,
    required UserModel player,
  }) async {
    try {
      AppLogger.info(
        'Processing game purchase for: ${game.title}',
        'Web3GameService',
      );

      if (game.isFreeToPlay || game.price == null || game.price! <= 0) {
        return {'success': false, 'message': 'Game is free to play'};
      }

      // Check if player has sufficient balance
      final balance = await _stellarService.getAccountBalance(
        player.stellarWalletAddress ?? '',
      );
      final xlmBalance = balance['XLM'] ?? 0.0;

      if (xlmBalance < game.price!) {
        return {'success': false, 'message': 'Insufficient XLM balance'};
      }

      // Calculate platform fee (5%)
      final platformFee = game.price! * 0.05;
      final developerPayment = game.price! - platformFee;

      // Send payment to developer (mock implementation)
      final paymentResult = await _stellarService.sendPayment(
        fromAccountId: player.stellarWalletAddress ?? '',
        toAccountId: game.developerWalletAddress ?? '',
        amount: developerPayment,
        secretKey:
            'mock_secret_key', // In real implementation, get from secure storage
        memo: 'Game purchase: ${game.title}',
      );

      if (!paymentResult['success']) {
        return {
          'success': false,
          'message': 'Payment failed: ${paymentResult['error']}',
        };
      }

      // Send platform fee to platform wallet (mock implementation)
      await _stellarService.sendPayment(
        fromAccountId: player.stellarWalletAddress ?? '',
        toAccountId: _platformWalletAddress,
        amount: platformFee,
        secretKey: 'mock_secret_key',
        memo: 'Platform fee: ${game.title}',
      );

      AppLogger.info('Game purchase completed successfully', 'Web3GameService');

      return {
        'success': true,
        'gameId': game.id,
        'amount': game.price!,
        'developerPayment': developerPayment,
        'platformFee': platformFee,
        'transactionHash': paymentResult['transactionHash'],
      };
    } catch (e) {
      AppLogger.error('Failed to purchase game', 'Web3GameService', e);
      return {'success': false, 'message': 'Purchase failed: ${e.toString()}'};
    }
  }

  /// Distribute revenue to game developer
  Future<Map<String, dynamic>> distributeDeveloperRevenue({
    required String developerAddress,
    required String gameId,
    required double amount,
  }) async {
    try {
      AppLogger.info(
        'Distributing revenue to developer: $developerAddress',
        'Web3GameService',
      );

      final result = await _sorobanService.distributeDeveloperRevenue(
        contractId: _developerPaymentsContract,
        developerAddress: developerAddress,
        amount: amount,
        gameId: gameId,
        sourceAccount: _platformWalletAddress,
        secretKey: _platformSecretKey,
      );

      if (result['success']) {
        AppLogger.info(
          'Developer revenue distributed successfully',
          'Web3GameService',
        );
      }

      return result;
    } catch (e) {
      AppLogger.error(
        'Failed to distribute developer revenue',
        'Web3GameService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get player statistics from blockchain
  Future<Map<String, dynamic>> getPlayerStats({
    required UserModel player,
  }) async {
    try {
      AppLogger.info(
        'Getting player stats for: ${player.username}',
        'Web3GameService',
      );

      // Mock implementation - in real app, this would call Soroban contract
      final mockStats = {
        'totalGamesPlayed': 25,
        'totalPlayTime': 180, // minutes
        'totalEarnings': 1.5, // XLM
        'achievementsUnlocked': 8,
        'averageScore': 85.5,
      };

      AppLogger.info('Player stats retrieved successfully', 'Web3GameService');

      return {'success': true, 'stats': mockStats};
    } catch (e) {
      AppLogger.error('Failed to get player stats', 'Web3GameService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get game statistics from blockchain
  Future<Map<String, dynamic>> getGameStats({required String gameId}) async {
    try {
      AppLogger.info('Getting game stats for: $gameId', 'Web3GameService');

      // Mock implementation - in real app, this would call Soroban contract
      final mockStats = {
        'totalPlayers': 150,
        'totalPlayTime': 1200, // minutes
        'totalRevenue': 5.25, // XLM
        'averageRating': 4.2,
        'totalDownloads': 200,
      };

      AppLogger.info('Game stats retrieved successfully', 'Web3GameService');

      return {'success': true, 'stats': mockStats};
    } catch (e) {
      AppLogger.error('Failed to get game stats', 'Web3GameService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stake tokens in a developer pool
  Future<Map<String, dynamic>> stakeTokens({
    required UserModel player,
    required String developerAddress,
    required double amount,
  }) async {
    try {
      AppLogger.info(
        'Staking tokens for player: ${player.username}',
        'Web3GameService',
      );

      // Mock implementation - in real app, this would call Soroban contract
      await Future.delayed(const Duration(milliseconds: 500));

      AppLogger.info('Tokens staked successfully', 'Web3GameService');

      return {
        'success': true,
        'amount': amount,
        'developerAddress': developerAddress,
        'transactionHash': 'mock_stake_transaction_hash',
      };
    } catch (e) {
      AppLogger.error('Failed to stake tokens', 'Web3GameService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get transaction history for a user
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    required UserModel player,
  }) async {
    try {
      AppLogger.info(
        'Getting transaction history for: ${player.username}',
        'Web3GameService',
      );

      // Mock implementation - in real app, this would call Stellar service
      await Future.delayed(const Duration(milliseconds: 300));

      final mockTransactions = [
        {
          'hash': 'mock_tx_hash_1',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
          'fee': 0.00001,
          'memo': 'Game reward: puzzle_game_1',
          'operations': 1,
        },
        {
          'hash': 'mock_tx_hash_2',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'fee': 0.00001,
          'memo': 'Game purchase: arcade_game_2',
          'operations': 1,
        },
      ];

      return mockTransactions;
    } catch (e) {
      AppLogger.error(
        'Failed to get transaction history',
        'Web3GameService',
        e,
      );
      return [];
    }
  }

  /// Calculate rewards based on game performance
  Map<String, double> _calculateRewards(
    int playTimeMinutes,
    double score,
    List<String> achievementsUnlocked,
  ) {
    // Base reward for playing
    double baseReward = 0.001; // 0.001 XLM base reward

    // Time-based reward (up to 0.005 XLM for 30+ minutes)
    double timeReward = min(playTimeMinutes / 6.0, 0.005);

    // Score-based reward (up to 0.01 XLM for perfect score)
    double scoreReward = (score / 100.0) * 0.01;

    // Achievement reward (0.001 XLM per achievement)
    double achievementReward = achievementsUnlocked.length * 0.001;

    // Total XLM reward
    double totalXlmReward =
        baseReward + timeReward + scoreReward + achievementReward;

    // GAME token reward (1 GAME token per 0.01 XLM earned)
    double gameTokenReward = (totalXlmReward / 0.01).floorToDouble();

    return {
      'xlmReward': totalXlmReward,
      'gameTokenReward': gameTokenReward,
      'baseReward': baseReward,
      'timeReward': timeReward,
      'scoreReward': scoreReward,
      'achievementReward': achievementReward,
    };
  }

  /// Get fee sponsorship for a transaction
  Future<Map<String, dynamic>> getFeeSponsorship({
    required String transactionXdr,
    required String userAccount,
  }) async {
    try {
      return await _launchtubeService.getFeeSponsorship(
        sourceAccountId: userAccount,
        transactionXdr: transactionXdr,
      );
    } catch (e) {
      AppLogger.error('Failed to get fee sponsorship', 'Web3GameService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check fee sponsorship availability
  Future<Map<String, dynamic>> checkSponsorshipAvailability({
    required String userAccount,
  }) async {
    try {
      AppLogger.info(
        'Checking sponsorship availability for: $userAccount',
        'Web3GameService',
      );

      final isAvailable = await _launchtubeService.isSponsorshipAvailable();
      return {
        'success': true,
        'isAvailable': isAvailable,
        'userAccount': userAccount,
      };
    } catch (e) {
      AppLogger.error(
        'Failed to check sponsorship availability',
        'Web3GameService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  String _generateSessionId() {
    // Implementation of _generateSessionId method
    // This is a placeholder and should be replaced with the actual implementation
    return 'mock_session_id';
  }
}
