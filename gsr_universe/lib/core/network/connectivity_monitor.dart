// Core Connectivity Monitor Service
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityMonitor {
  final Connectivity _connectivity;

  ConnectivityMonitor(this._connectivity);

  /// Helper to check connection instantly
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Listen for connection changes in real-time
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;
}
