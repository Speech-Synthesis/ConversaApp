import 'dart:async';
import 'dart:io';

/// Utility class for retry logic with exponential backoff
class RetryHelper {
  /// Retry a future operation with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (error) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Check if we've exhausted retry attempts
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }
  }

  /// Check if an error is retryable (network/timeout errors)
  static bool isRetryableError(dynamic error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }
}
