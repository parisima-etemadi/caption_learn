import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'error_handler.dart';

/// Simple connectivity helper
class ConnectivityHelper {
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }
  
  static Future<bool> checkWithError(BuildContext context, [String? message]) async {
    final connected = await isConnected();
    if (!connected && context.mounted) {
      ErrorHandler.showError(context, message ?? 'No internet connection');
    }
    return connected;
  }
}