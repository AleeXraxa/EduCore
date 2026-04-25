import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Centralized service to monitor and verify internet connectivity.
class NetworkService {
  NetworkService._();
  
  static final Connectivity _connectivity = Connectivity();
  static final InternetConnection _internetChecker = InternetConnection();

  /// Quick check for active internet connection with actual reachability verification.
  static Future<bool> get hasConnection async {
    // 1. Check system level connectivity
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;
    
    // 2. Verify actual internet reachability (ping)
    return await _internetChecker.hasInternetAccess;
  }

  /// Streams connectivity changes for reactive UI.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged => 
      _connectivity.onConnectivityChanged;
}
