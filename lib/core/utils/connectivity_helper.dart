import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'error_handler.dart';

/// Utility class for network connectivity operations
class ConnectivityHelper {
  /// Check if device is connected to internet
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty && 
           connectivityResult.first != ConnectivityResult.none;
  }
  
  /// Check connectivity and show error if offline
  static Future<bool> checkConnectivityWithError(BuildContext context, {String? errorMessage}) async {
    final isConnected = await ConnectivityHelper.isConnected();
    
    if (!isConnected && context.mounted) {
      ErrorHandler.showError(
        context, 
        errorMessage ?? 'No internet connection. Please check your network and try again.'
      );
    }
    
    return isConnected;
  }
}