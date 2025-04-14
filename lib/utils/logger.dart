enum LogLevel { debug, info, warning, error }

/// A simple logger utility to handle logging consistently throughout the app
class Logger {
  final String tag;
  
  /// Log level to control which logs are displayed
  /// Set to LogLevel.debug for development, LogLevel.error for production
  static LogLevel logLevel = LogLevel.info;
  
  const Logger(this.tag);
  
  /// Log a debug message
  void d(String message) {
    if (logLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message);
    }
  }
  
  /// Log an info message
  void i(String message) {
    if (logLevel.index <= LogLevel.info.index) {
      _log('INFO', message);
    }
  }
  
  /// Log a warning message
  void w(String message) {
    if (logLevel.index <= LogLevel.warning.index) {
      _log('WARNING', message);
    }
  }
  
  /// Log an error message
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (logLevel.index <= LogLevel.error.index) {
      final errorMsg = error != null ? ': $error' : '';
      _log('ERROR', '$message$errorMsg');
      
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
  
  void _log(String level, String message) {
    print('[$level] [$tag] $message');
  }
} 