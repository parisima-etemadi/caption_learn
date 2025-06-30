import '../utils/logger.dart';

/// Base class for all services with common functionality
abstract class BaseService {
  /// Logger instance for this service
  late final Logger logger;
  
  /// Service name used for logging
  String get serviceName;
  
  BaseService() {
    logger = Logger(serviceName);
  }
}