import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;

  /// Stream of connectivity status
  Stream<bool> get connectionStream => _connectionController!.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    _connectionController = StreamController<bool>.broadcast();
    
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _hasInternetConnection(result);
    _connectionController!.add(_isOnline);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = _hasInternetConnection(results);
        
        // Only emit if status changed
        if (wasOnline != _isOnline) {
          _connectionController!.add(_isOnline);
        }
      },
    );
  }

  /// Check if any connectivity result indicates internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionController?.close();
  }
}

