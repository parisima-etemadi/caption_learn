/// Base exception class for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

/// Authentication-related exceptions  
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// Video processing exceptions
class VideoException extends AppException {
  const VideoException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'VideoException: $message';
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'StorageException: $message';
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'ValidationException: $message';
}