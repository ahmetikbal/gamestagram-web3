import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
/// Automatically disables logging in release mode for better performance
class AppLogger {
  static const String _tag = 'Gamestagram';
  
  /// Log debug information - only shows in debug mode
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] DEBUG: $message');
    }
  }
  
  /// Log info messages - only shows in debug mode
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }
  
  /// Log warnings - only shows in debug mode
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }
  
  /// Log errors - always shows even in release mode for critical issues
  static void error(String message, [String? tag, Object? error]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
      if (error != null) {
        print('Error details: $error');
      }
    }
  }
} 