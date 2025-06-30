import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import '../utils/logger.dart';

/// Error boundary widget to catch and display errors gracefully
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final Function(Object error, StackTrace stackTrace)? onError;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  final Logger _logger = const Logger('ErrorBoundary');
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _DefaultErrorWidget(
        error: _error!,
        onRetry: _retry,
      );
    }

    return ErrorBoundaryWrapper(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _logger.e('Widget error caught by boundary', error, stackTrace);
    
    widget.onError?.call(error, stackTrace);
    
    if (mounted) {
      setState(() {
        _error = error;
      });
    }
  }

  void _retry() {
    if (mounted) {
      setState(() {
        _error = null;
      });
    }
  }
}

/// Wrapper that catches Flutter framework errors
class ErrorBoundaryWrapper extends StatelessWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          onError(error, stackTrace);
          return _DefaultErrorWidget(
            error: error,
            onRetry: () {
              // Trigger rebuild
              (context as Element).markNeedsBuild();
            },
          );
        }
      },
    );
  }
}

/// Default error widget with retry option
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorMessage(error),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}

/// Global error handler setup
class AppErrorHandler {
  static final Logger _logger = const Logger('AppErrorHandler');
  
  static void setup() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.e(
        'Flutter framework error',
        details.exception,
        details.stack,
      );
      
      // In debug mode, show the error
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
    
    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.e('Async error', error, stack);
      return true;
    };
  }
}