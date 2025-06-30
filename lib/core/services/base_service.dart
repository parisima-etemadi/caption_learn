import '../utils/logger.dart';

/// Base class for all services
abstract class BaseService {
  late final Logger logger;
  String get serviceName;
  
  BaseService() {
    logger = Logger(serviceName);
  }
}