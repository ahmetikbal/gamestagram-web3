import 'package:flutter/services.dart';

class AudioService {
  static const MethodChannel _channel = MethodChannel('com.example.gamestagram/audio');

  /// Mutes the app's audio at the Android system level
  static Future<bool> muteApp() async {
    try {
      final bool result = await _channel.invokeMethod('muteApp');
      print('[AudioService] App muted: $result');
      return result;
    } on PlatformException catch (e) {
      print('[AudioService] Failed to mute app: ${e.message}');
      return false;
    }
  }

  /// Unmutes the app's audio at the Android system level
  static Future<bool> unmuteApp() async {
    try {
      final bool result = await _channel.invokeMethod('unmuteApp');
      print('[AudioService] App unmuted: $result');
      return result;
    } on PlatformException catch (e) {
      print('[AudioService] Failed to unmute app: ${e.message}');
      return false;
    }
  }

  /// Checks if the app is currently muted
  static Future<bool> isMuted() async {
    try {
      final bool result = await _channel.invokeMethod('isMuted');
      return result;
    } on PlatformException catch (e) {
      print('[AudioService] Failed to check mute status: ${e.message}');
      return false;
    }
  }
} 