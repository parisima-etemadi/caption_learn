import 'package:flutter/material.dart';

/// Standardized snackbar helpers for consistent messaging
class AppSnackBar {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      Colors.green,
      Icons.check_circle,
      duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message,
      Colors.red,
      Icons.error,
      duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      Colors.orange,
      Icons.warning,
      duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      Colors.blue,
      Icons.info,
      duration,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Extension to make snackbar usage more convenient
extension BuildContextSnackBar on BuildContext {
  void showSuccessSnackBar(String message) => 
      AppSnackBar.showSuccess(this, message);
  
  void showErrorSnackBar(String message) => 
      AppSnackBar.showError(this, message);
  
  void showWarningSnackBar(String message) => 
      AppSnackBar.showWarning(this, message);
  
  void showInfoSnackBar(String message) => 
      AppSnackBar.showInfo(this, message);
}