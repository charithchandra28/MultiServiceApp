import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A class to manage connectivity changes.
class ConnectivityHandler {
  final Connectivity _connectivity = Connectivity();
  final StreamController<List<ConnectivityResult>> _controller =
  StreamController<List<ConnectivityResult>>.broadcast();

  ConnectivityHandler() {
    _connectivity.onConnectivityChanged.listen( (result) => _controller.add(result),
        onError: (error) => _controller.addError(error),);
  }

  /// A stream of connectivity results (WiFi, mobile, none).
  Stream<List<ConnectivityResult>> get connectivityStream => _controller.stream;



  /// Dispose the handler to avoid memory leaks.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
