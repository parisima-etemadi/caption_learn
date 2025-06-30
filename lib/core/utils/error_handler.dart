import 'package:flutter/material.dart';
import 'package:caption_learn/core/utils/firebase_auth_error_mapper.dart';
import 'package:caption_learn/core/utils/logger.dart';

/// A general error handler for the application
///
/// This class provides methods to handle different types of errors throughout the app
class ErrorHandler {
  final Logger _logger;
  final String _tag;

  ErrorHandler(this._tag) : _logger = Logger(_tag);

  /// Handles authentication errors
  String handleAuthError(dynamic error) {
    _logger.e('Authentication error', error);
    return FirebaseAuthErrorMapper.mapErrorToMessage(error);
  }

  /// Handles network errors
  String handleNetworkError(dynamic error) {
    _logger.e('Network error', error);
    
    // Parse common network errors
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Connection timed out. Please try again.';
    }
    
    return 'A network error occurred. Please try again.';
  }

  /// Handles database errors
  String handleDatabaseError(dynamic error) {
    _logger.e('Database error', error);
    return 'A database error occurred. Please try again later.';
  }

  /// Handles general errors
  String handleError(dynamic error) {
    _logger.e('General error', error);
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Show error message to user via SnackBar
  static void showError(BuildContext context, String message, {Color? backgroundColor}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
      ),
    );
  }
  
  /// Show warning message to user via SnackBar
  static void showWarning(BuildContext context, String message) {
    showError(context, message, backgroundColor: Colors.orange);
  }
  
  /// Show success message to user via SnackBar
  static void showSuccess(BuildContext context, String message) {
    showError(context, message, backgroundColor: Colors.green);
  }
}