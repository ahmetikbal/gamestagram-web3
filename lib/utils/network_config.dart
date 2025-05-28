import 'dart:io';

/// Network configuration utilities for handling SSL and connection issues
class NetworkConfig {
  /// Creates an HTTP client with relaxed SSL verification for development/testing
  /// Note: In production, proper SSL certificates should be used instead
  static HttpClient createHttpClient() {
    final client = HttpClient();
    
    // Set connection timeout
    client.connectionTimeout = const Duration(seconds: 10);
    
    // Set idle timeout
    client.idleTimeout = const Duration(seconds: 30);
    
    // For development: Allow self-signed certificates
    // WARNING: This should not be used in production without proper certificate validation
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Log the certificate issue for debugging
      print('SSL Certificate warning for $host:$port');
      print('Certificate subject: ${cert.subject}');
      print('Certificate issuer: ${cert.issuer}');
      
      // In a production app, you should implement proper certificate validation
      // For now, we'll allow connections to continue for better user experience
      return true;
    };
    
    return client;
  }
  
  /// Checks if an error is network-related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('handshakeexception') ||
           errorString.contains('tlsexception') ||
           errorString.contains('certificateexception') ||
           errorString.contains('timeoutexception') ||
           errorString.contains('connection') ||
           errorString.contains('network');
  }
  
  /// Gets a user-friendly error message for network errors
  static String getNetworkErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('handshakeexception') || 
        errorString.contains('tlsexception') ||
        errorString.contains('certificateexception')) {
      return 'SSL/Security certificate issue';
    } else if (errorString.contains('socketexception')) {
      if (errorString.contains('connection refused')) {
        return 'Connection refused by server';
      } else if (errorString.contains('connection reset')) {
        return 'Connection reset by server';
      } else if (errorString.contains('no route to host')) {
        return 'No route to host';
      } else {
        return 'Network connection error';
      }
    } else if (errorString.contains('timeoutexception')) {
      return 'Connection timeout';
    } else if (errorString.contains('formatexception')) {
      return 'Invalid server response';
    } else {
      return 'Network error: ${error.toString()}';
    }
  }
} 