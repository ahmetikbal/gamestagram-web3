import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'logger.dart';

/// Performance monitoring utility to track frame rates and identify bottlenecks
class PerformanceMonitor {
  static bool _isMonitoring = false;
  static int _frameCount = 0;
  static int _droppedFrames = 0;
  static DateTime _lastReportTime = DateTime.now();
  static const Duration _reportInterval = Duration(seconds: 5);
  
  /// Start monitoring frame performance
  static void startMonitoring() {
    if (_isMonitoring || !kDebugMode) return;
    
    _isMonitoring = true;
    _frameCount = 0;
    _droppedFrames = 0;
    _lastReportTime = DateTime.now();
    
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    AppLogger.info('Performance monitoring started', 'PerformanceMonitor');
  }
  
  /// Stop monitoring frame performance
  static void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    AppLogger.info('Performance monitoring stopped', 'PerformanceMonitor');
  }
  
  /// Frame timing callback
  static void _onFrameTimings(List<FrameTiming> timings) {
    if (!_isMonitoring) return;
    
    for (final timing in timings) {
      _frameCount++;
      
      // Check for dropped frames (>16.67ms for 60fps)
      final frameDuration = timing.totalSpan;
      if (frameDuration > const Duration(milliseconds: 16, microseconds: 670)) {
        _droppedFrames++;
        
        // Log severe frame drops (>33ms)
        if (frameDuration > const Duration(milliseconds: 33)) {
          AppLogger.warning(
            'Severe frame drop: ${frameDuration.inMilliseconds}ms', 
            'PerformanceMonitor'
          );
        }
      }
    }
    
    // Report every 5 seconds
    if (DateTime.now().difference(_lastReportTime) >= _reportInterval) {
      _reportPerformance();
    }
  }
  
  /// Report current performance metrics
  static void _reportPerformance() {
    if (_frameCount == 0) return;
    
    final double dropRate = (_droppedFrames / _frameCount) * 100;
    final double fps = _frameCount / _reportInterval.inSeconds;
    
    AppLogger.info(
      'Performance Report: ${fps.toStringAsFixed(1)} FPS, ${dropRate.toStringAsFixed(1)}% dropped frames',
      'PerformanceMonitor'
    );
    
    // Warn if performance is poor
    if (dropRate > 10) {
      AppLogger.warning(
        'Poor performance detected: ${dropRate.toStringAsFixed(1)}% frame drops',
        'PerformanceMonitor'
      );
    }
    
    // Reset counters
    _frameCount = 0;
    _droppedFrames = 0;
    _lastReportTime = DateTime.now();
  }
  
  /// Get current performance stats
  static Map<String, dynamic> getCurrentStats() {
    if (_frameCount == 0) return {};
    
    final double dropRate = (_droppedFrames / _frameCount) * 100;
    final double fps = _frameCount / DateTime.now().difference(_lastReportTime).inSeconds;
    
    return {
      'fps': fps,
      'frameDropRate': dropRate,
      'frameCount': _frameCount,
      'droppedFrames': _droppedFrames,
    };
  }
} 