/// Custom exception for API errors with user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  /// Create a user-friendly exception from an HTTP status code.
  factory ApiException.fromStatus(int statusCode, {String? body}) {
    String message;
    switch (statusCode) {
      case 404:
        message = 'Endpoint not found. Is the backend up to date?';
        break;
      case 422:
        message = 'Invalid request format.';
        break;
      case 500:
        message = 'Server error. Please try again later.';
        break;
      case 503:
        message = 'Service unavailable. The backend may be starting up.';
        break;
      default:
        message = 'Request failed ($statusCode).';
    }
    return ApiException(message, statusCode: statusCode, body: body);
  }

  @override
  String toString() => message;
}

/// Exception for when the backend health check fails.
class BackendUnavailableException implements Exception {
  final String backendUrl;
  final String? detail;

  BackendUnavailableException(this.backendUrl, {this.detail});

  @override
  String toString() =>
      'Backend unavailable at $backendUrl${detail != null ? ': $detail' : ''}';
}
