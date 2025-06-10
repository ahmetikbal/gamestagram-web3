import 'package:flutter/services.dart';
import '../../utils/logger.dart';

class AudioService {
  static const MethodChannel _channel = MethodChannel('com.example.gamestagram/audio');

  /// Mutes the app's audio at the Android system level
  static Future<bool> muteApp() async {
    try {
      final bool result = await _channel.invokeMethod('muteApp');
      AppLogger.debug('App muted: $result', 'AudioService');
      return result;
    } on PlatformException catch (e) {
      AppLogger.debug('Failed to mute app: ${e.message}', 'AudioService');
      return false;
    }
  }

  /// Unmutes the app's audio at the Android system level
  static Future<bool> unmuteApp() async {
    try {
      final bool result = await _channel.invokeMethod('unmuteApp');
      AppLogger.debug('App unmuted: $result', 'AudioService');
      return result;
    } on PlatformException catch (e) {
      AppLogger.debug('Failed to unmute app: ${e.message}', 'AudioService');
      return false;
    }
  }

  /// Checks if the app is currently muted
  static Future<bool> isMuted() async {
    try {
      final bool result = await _channel.invokeMethod('isMuted');
      return result;
    } on PlatformException catch (e) {
      AppLogger.debug('Failed to check mute status: ${e.message}', 'AudioService');
      return false;
    }
  }
} 