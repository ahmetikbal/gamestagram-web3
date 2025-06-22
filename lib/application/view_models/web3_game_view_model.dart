import 'package:flutter/foundation.dart';
import '../../data/models/game_model.dart';
import '../../data/models/user_model.dart';
import '../../services/web3_game_service.dart';
import '../../services/stellar_service.dart';
import '../../utils/logger.dart';

/// ViewModel for handling Web3 game interactions and state
class Web3GameViewModel extends ChangeNotifier {
  final Web3GameService _gameService = Web3GameService();
  final StellarService _stellarService = StellarService();

  List<GameModel> _games = [];
  GameModel? _currentGame;
  String? _currentSessionId;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentRewards;
  List<Map<String, dynamic>> _transactionHistory = [];
  Map<String, double> _walletBalance = {};

  // Game session tracking
  DateTime? _sessionStartTime;
  bool _isSessionActive = false;

  // Getters
  List<GameModel> get games => _games;
  GameModel? get currentGame => _currentGame;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentRewards => _currentRewards;
  List<Map<String, dynamic>> get transactionHistory => _transactionHistory;
  Map<String, double> get walletBalance => _walletBalance;
  bool get isSessionActive => _isSessionActive;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Load initial games
  Future<void> loadInitialGames() async {
    try {
      _setLoading(true);
      _clearError();

      // In a real app, this would load from a backend API
      // For now, we'll create sample games with Web3 features
      _games = _createSampleGames();

      AppLogger.info(
        'Initial games loaded: ${_games.length}',
        'Web3GameViewModel',
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load games: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Start a game session
  Future<bool> startGameSession({
    required GameModel game,
    required UserModel player,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      AppLogger.info(
        'Starting game session for: ${game.title}',
        'Web3GameViewModel',
      );

      final result = await _gameService.startGameSession(
        gameId: game.id,
        player: player,
        gameUrl: game.gameUrl ?? '',
      );

      if (result['success']) {
        _currentGame = game;
        _currentSessionId = result['sessionId'];
        _sessionStartTime = DateTime.now();
        _isSessionActive = true;

        AppLogger.info(
          'Game session started: ${result['sessionId']}',
          'Web3GameViewModel',
        );
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to start game session: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete a game session
  Future<bool> completeGameSession({
    required UserModel player,
    required double score,
    required int achievementsUnlocked,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentGame == null ||
          _currentSessionId == null ||
          _sessionStartTime == null) {
        _setError('No active game session');
        return false;
      }

      final playTimeMinutes =
          DateTime.now().difference(_sessionStartTime!).inMinutes;

      AppLogger.info(
        'Completing game session: ${_currentGame!.title}',
        'Web3GameViewModel',
      );

      final result = await _gameService.completeGameSession(
        gameId: _currentGame!.id,
        player: player,
        playTimeMinutes: playTimeMinutes,
        score: score,
        achievementsUnlocked: ['achievement_$achievementsUnlocked'],
      );

      if (result['success']) {
        _currentRewards = result['rewards'];
        _isSessionActive = false;

        // Update game statistics
        _updateGameStats(_currentGame!.id, playTimeMinutes, score);

        AppLogger.info(
          'Game session completed with rewards: $_currentRewards',
          'Web3GameViewModel',
        );
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to complete game session: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a premium game
  Future<bool> purchaseGame({
    required GameModel game,
    required UserModel player,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      AppLogger.info('Purchasing game: ${game.title}', 'Web3GameViewModel');

      final result = await _gameService.purchaseGame(
        game: game,
        player: player,
      );

      if (result['success']) {
        // Update game ownership status
        final gameIndex = _games.indexWhere((g) => g.id == game.id);
        if (gameIndex != -1) {
          _games[gameIndex] = _games[gameIndex].copyWith(
            isOwnedByCurrentUser: true,
          );
        }

        // Refresh wallet balance
        await refreshWalletBalance(player);

        AppLogger.info('Game purchased successfully', 'Web3GameViewModel');
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to purchase game: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get player statistics
  Future<Map<String, dynamic>> getPlayerStats(UserModel player) async {
    try {
      _setLoading(true);
      _clearError();

      final stats = await _gameService.getPlayerStats(player: player);

      if (stats['success']) {
        AppLogger.info('Player stats retrieved', 'Web3GameViewModel');
        return stats['stats'] as Map<String, dynamic>;
      } else {
        _setError(stats['error'] as String);
        return {};
      }
    } catch (e) {
      _setError('Failed to get player stats: ${e.toString()}');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  /// Get game statistics
  Future<Map<String, dynamic>> getGameStats(String gameId) async {
    try {
      _setLoading(true);
      _clearError();

      final stats = await _gameService.getGameStats(gameId: gameId);

      if (stats['success']) {
        AppLogger.info('Game stats retrieved', 'Web3GameViewModel');
        return stats['stats'] as Map<String, dynamic>;
      } else {
        _setError(stats['error'] as String);
        return {};
      }
    } catch (e) {
      _setError('Failed to get game stats: ${e.toString()}');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  /// Stake tokens in a developer pool
  Future<bool> stakeTokens({
    required UserModel player,
    required String developerAddress,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      AppLogger.info('Staking tokens: $amount', 'Web3GameViewModel');

      final result = await _gameService.stakeTokens(
        player: player,
        developerAddress: developerAddress,
        amount: amount,
      );

      if (result['success']) {
        // Refresh wallet balance
        await refreshWalletBalance(player);

        AppLogger.info('Tokens staked successfully', 'Web3GameViewModel');
        notifyListeners();
        return true;
      } else {
        _setError(result['error'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to stake tokens: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get transaction history
  Future<void> getTransactionHistory(UserModel player) async {
    try {
      _setLoading(true);
      _clearError();

      _transactionHistory = await _gameService.getTransactionHistory(
        player: player,
      );

      AppLogger.info(
        'Transaction history loaded: ${_transactionHistory.length}',
        'Web3GameViewModel',
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to get transaction history: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh wallet balance
  Future<void> refreshWalletBalance(UserModel player) async {
    try {
      if (player.stellarWalletAddress != null) {
        _walletBalance = await _stellarService.getAccountBalance(
          player.stellarWalletAddress!,
        );
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to refresh wallet balance',
        'Web3GameViewModel',
        e,
      );
    }
  }

  /// Check fee sponsorship availability
  Future<Map<String, dynamic>> checkSponsorshipAvailability(
    String userAccount,
  ) async {
    try {
      return await _gameService.checkSponsorshipAvailability(
        userAccount: userAccount,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to check sponsorship availability',
        'Web3GameViewModel',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// End current game session
  void endGameSession() {
    _isSessionActive = false;
    _sessionStartTime = null;
    _currentSessionId = null;
    _currentGame = null;
    notifyListeners();
  }

  /// Clear current rewards
  void clearRewards() {
    _currentRewards = null;
    notifyListeners();
  }

  /// Update game statistics locally
  void _updateGameStats(String gameId, int playTime, double score) {
    final gameIndex = _games.indexWhere((g) => g.id == gameId);
    if (gameIndex != -1) {
      final game = _games[gameIndex];
      _games[gameIndex] = game.copyWith(
        playCount: game.playCount + 1,
        totalPlayTime: game.totalPlayTime + playTime,
        averageRating:
            ((game.averageRating * game.ratingCount) + score) /
            (game.ratingCount + 1),
        ratingCount: game.ratingCount + 1,
      );
    }
  }

  /// Create sample games with Web3 features
  List<GameModel> _createSampleGames() {
    return [
      GameModel(
        id: 'game_1',
        title: 'Crypto Runner',
        description: 'Run through the blockchain and collect XLM tokens!',
        imageUrl:
            'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Crypto+Runner',
        gameUrl: 'https://example.com/crypto-runner',
        genre: 'Arcade',
        developerId: 'dev_1',
        developerName: 'Blockchain Studios',
        developerWalletAddress:
            'GDEV123456789012345678901234567890123456789012345678901234567890',
        smartContractAddress:
            'CONTRACT_CRYPTO_RUNNER_123456789012345678901234567890123456789012345678901234567890',
        gameTokenAddress:
            'GAME_CRYPTO_RUNNER_123456789012345678901234567890123456789012345678901234567890',
        supportedTokens: ['XLM', 'GAME'],
        isNFTEnabled: true,
        nftCollectionAddress:
            'NFT_CRYPTO_RUNNER_123456789012345678901234567890123456789012345678901234567890',
        isFreeToPlay: true,
        tags: ['Arcade', 'Blockchain', 'Runner'],
        difficulty: 'Easy',
        estimatedPlayTime: 5,
        ageRating: 'E',
        version: '1.0.0',
        releaseDate: DateTime.now().subtract(const Duration(days: 30)),
        platform: 'HTML5',
        hasMultiplayer: false,
        hasLeaderboard: true,
      ),
      GameModel(
        id: 'game_2',
        title: 'Stellar Defender',
        description: 'Defend the Stellar network from malicious attacks!',
        imageUrl:
            'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Stellar+Defender',
        gameUrl: 'https://example.com/stellar-defender',
        genre: 'Strategy',
        developerId: 'dev_2',
        developerName: 'Stellar Games',
        developerWalletAddress:
            'GDEV234567890123456789012345678901234567890123456789012345678901',
        smartContractAddress:
            'CONTRACT_STELLAR_DEFENDER_123456789012345678901234567890123456789012345678901234567890',
        gameTokenAddress:
            'GAME_STELLAR_DEFENDER_123456789012345678901234567890123456789012345678901234567890',
        supportedTokens: ['XLM', 'GAME'],
        isNFTEnabled: true,
        nftCollectionAddress:
            'NFT_STELLAR_DEFENDER_123456789012345678901234567890123456789012345678901234567890',
        isFreeToPlay: false,
        price: 0.05,
        tags: ['Strategy', 'Defense', 'Blockchain'],
        difficulty: 'Medium',
        estimatedPlayTime: 15,
        ageRating: 'E10+',
        version: '1.2.0',
        releaseDate: DateTime.now().subtract(const Duration(days: 15)),
        platform: 'HTML5',
        hasMultiplayer: true,
        hasLeaderboard: true,
      ),
      GameModel(
        id: 'game_3',
        title: 'Token Tycoon',
        description: 'Build your crypto empire and become a token tycoon!',
        imageUrl:
            'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Token+Tycoon',
        gameUrl: 'https://example.com/token-tycoon',
        genre: 'Simulation',
        developerId: 'dev_3',
        developerName: 'Crypto Simulations',
        developerWalletAddress:
            'GDEV345678901234567890123456789012345678901234567890123456789012',
        smartContractAddress:
            'CONTRACT_TOKEN_TYCOON_123456789012345678901234567890123456789012345678901234567890',
        gameTokenAddress:
            'GAME_TOKEN_TYCOON_123456789012345678901234567890123456789012345678901234567890',
        supportedTokens: ['XLM', 'GAME'],
        isNFTEnabled: true,
        nftCollectionAddress:
            'NFT_TOKEN_TYCOON_123456789012345678901234567890123456789012345678901234567890',
        isFreeToPlay: false,
        price: 0.1,
        tags: ['Simulation', 'Business', 'Blockchain'],
        difficulty: 'Hard',
        estimatedPlayTime: 30,
        ageRating: 'T',
        version: '2.0.0',
        releaseDate: DateTime.now().subtract(const Duration(days: 7)),
        platform: 'HTML5',
        hasMultiplayer: true,
        hasLeaderboard: true,
      ),
    ];
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    AppLogger.error('Web3GameViewModel error: $error', 'Web3GameViewModel');
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
