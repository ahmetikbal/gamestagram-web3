import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Real Launchtube service for fee sponsorship on Stellar testnet
class LaunchtubeService {
  static const String _launchtubeUrl = 'https://launchtube.stellar.org';

  LaunchtubeService();

  /// Initialize the Launchtube service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing Launchtube service...', 'LaunchtubeService');
      AppLogger.info(
        'Launchtube service initialized successfully',
        'LaunchtubeService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to initialize Launchtube service',
        'LaunchtubeService',
        e,
      );
      rethrow;
    }
  }

  /// Get fee sponsorship for a transaction
  Future<Map<String, dynamic>> getFeeSponsorship({
    required String sourceAccountId,
    required String transactionXdr,
  }) async {
    try {
      AppLogger.info(
        'Requesting fee sponsorship for account: $sourceAccountId',
        'LaunchtubeService',
      );

      final response = await http.post(
        Uri.parse('$_launchtubeUrl/sponsor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source_account_id': sourceAccountId,
          'transaction_xdr': transactionXdr,
          'network': 'testnet',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          'Fee sponsorship obtained successfully',
          'LaunchtubeService',
        );

        return {
          'success': true,
          'sponsored_xdr': data['sponsored_xdr'],
          'fee_amount': data['fee_amount'],
        };
      } else {
        AppLogger.error(
          'Failed to get fee sponsorship: ${response.statusCode}',
          'LaunchtubeService',
        );
        return {
          'success': false,
          'error': 'Failed to get fee sponsorship: ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.error('Failed to get fee sponsorship', 'LaunchtubeService', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get sponsorship status
  Future<Map<String, dynamic>> getSponsorshipStatus() async {
    try {
      final response = await http.get(Uri.parse('$_launchtubeUrl/status'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'available_funds': data['available_funds'],
          'daily_limit': data['daily_limit'],
          'used_today': data['used_today'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get sponsorship status: ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get sponsorship status',
        'LaunchtubeService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if sponsorship is available
  Future<bool> isSponsorshipAvailable() async {
    try {
      final status = await getSponsorshipStatus();
      return status['success'] && status['status'] == 'active';
    } catch (e) {
      AppLogger.error(
        'Failed to check sponsorship availability',
        'LaunchtubeService',
        e,
      );
      return false;
    }
  }

  /// Estimate transaction fee
  Future<Map<String, dynamic>> estimateTransactionFee({
    required String transactionXdr,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_launchtubeUrl/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_xdr': transactionXdr,
          'network': 'testnet',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'estimated_fee': data['estimated_fee'],
          'can_sponsor': data['can_sponsor'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to estimate fee: ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.error(
        'Failed to estimate transaction fee',
        'LaunchtubeService',
        e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }
}
