import 'package:flutter/material.dart';

/// Generic async widget that handles loading, error, and success states
class AsyncWidget<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final Widget Function(Object error)? errorBuilder;
  final Widget? loadingWidget;
  final bool showRetry;

  const AsyncWidget({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const _DefaultLoadingWidget();
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error!) ?? 
              _DefaultErrorWidget(
                error: snapshot.error!,
                showRetry: showRetry,
                onRetry: () {
                  // Trigger rebuild by creating new future
                  (context as Element).markNeedsBuild();
                },
              );
        }

        if (snapshot.hasData) {
          return builder(snapshot.data as T);
        }

        return const _DefaultEmptyWidget();
      },
    );
  }
}

/// Stream version for real-time data
class AsyncStreamWidget<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(T data) builder;
  final Widget Function(Object error)? errorBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const AsyncStreamWidget({
    super.key,
    required this.stream,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const _DefaultLoadingWidget();
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error!) ?? 
              _DefaultErrorWidget(
                error: snapshot.error!,
                showRetry: false,
              );
        }

        if (snapshot.hasData) {
          return builder(snapshot.data as T);
        }

        return emptyWidget ?? const _DefaultEmptyWidget();
      },
    );
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final bool showRetry;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.showRetry = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
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

class _DefaultEmptyWidget extends StatelessWidget {
  const _DefaultEmptyWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}