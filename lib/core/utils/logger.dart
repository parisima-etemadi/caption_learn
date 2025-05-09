enum LogLevel { debug, info, warning, error }

class Logger {
  final String tag;
  
  static LogLevel logLevel = LogLevel.info;
  
  const Logger(this.tag);
  
  void d(String message) {
    if (logLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message);
    }
  }
  
  void i(String message) {
    if (logLevel.index <= LogLevel.info.index) {
      _log('INFO', message);
    }
  }
  
  void w(String message) {
    if (logLevel.index <= LogLevel.warning.index) {
      _log('WARNING', message);
    }
  }
  
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