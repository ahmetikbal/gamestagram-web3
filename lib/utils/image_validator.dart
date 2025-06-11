import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Utility class for validating image URLs and asset paths before displaying them
/// Optimized for performance with concurrent validation and aggressive caching
class ImageValidator {
  static final Map<String, bool> _validationCache = {};
  static const int _maxConcurrentValidations = 3; // Limit concurrent network requests
  static const Duration _networkTimeout = Duration(seconds: 8); // Increased timeout for slower networks
  
  /// Validates if an image URL or asset path can be loaded successfully
  /// Returns true if the image is valid and can be loaded
  static Future<bool> validateImage(String imageUrl) async {
    // Check cache first to avoid repeated validation
    if (_validationCache.containsKey(imageUrl)) {
      return _validationCache[imageUrl]!;
    }
    
    bool isValid = false;
    
    try {
      if (imageUrl.startsWith('images/')) {
        // Validate local asset (fast, synchronous check)
        isValid = await _validateAsset('assets/$imageUrl');
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        // Validate network image with faster timeout
        isValid = await _validateNetworkImage(imageUrl);
      } else {
        // Invalid URL format
        isValid = false;
      }
    } catch (e) {
      // Fail silently for performance, just mark as invalid
      isValid = false;
    }
    
    // Cache the result
    _validationCache[imageUrl] = isValid;
    return isValid;
  }
  
  /// Validates a local asset by checking if it exists in the asset bundle
  static Future<bool> _validateAsset(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Validates a network image with optimized timeout and error handling
  static Future<bool> _validateNetworkImage(String imageUrl) async {
    try {
      // Use HEAD request first to check if image exists without downloading content
      final response = await http.head(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'GameStagram/1.0',
        },
      ).timeout(_networkTimeout);
      
      // Check if response is successful and content type is an image
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        return contentType.startsWith('image/');
      }
      
      return false;
    } catch (e) {
      // If HEAD fails, try GET with timeout as fallback
      try {
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {
            'User-Agent': 'GameStagram/1.0',
          },
        ).timeout(Duration(seconds: 5)); // Shorter timeout for fallback
        
        if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        return contentType.startsWith('image/');
      }
      
      return false;
    } catch (e) {
      return false; // Fail silently for performance
      }
    }
  }
  
  /// Efficiently validates multiple images with controlled concurrency
  /// This prevents overwhelming the network and reduces lag
  static Future<Map<String, bool>> validateBatchConcurrent(List<String> imageUrls) async {
    final results = <String, bool>{};
    
    // Process in chunks to control concurrency
    for (int i = 0; i < imageUrls.length; i += _maxConcurrentValidations) {
      final chunk = imageUrls.skip(i).take(_maxConcurrentValidations).toList();
      
      // Process this chunk concurrently
      final futures = chunk.map((url) async {
        final isValid = await validateImage(url);
        results[url] = isValid;
        return MapEntry(url, isValid);
      });
      
      await Future.wait(futures);
    }
    
    return results;
  }
  
  /// Pre-validates images and returns only the valid ones
  /// This is more efficient than validating each game individually
  static Future<List<String>> getValidImages(List<String> imageUrls) async {
    final validationResults = await validateBatchConcurrent(imageUrls);
    return imageUrls.where((url) => validationResults[url] == true).toList();
  }
  
  /// Clears the validation cache (useful for testing or memory management)
  static void clearCache() {
    _validationCache.clear();
  }
  
  /// Quick cache check without validation
  static bool? getCachedResult(String imageUrl) {
    return _validationCache[imageUrl];
  }
  
  /// Pre-warms the cache with known good images
  static void prewarmCache(Map<String, bool> knownResults) {
    _validationCache.addAll(knownResults);
  }
} 