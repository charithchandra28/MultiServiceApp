import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/connectivity_handler.dart';




class InternetConnectivityBloc   {
  final ConnectivityHandler connectivityHandler;
  final String apiDomain;
  final int maxRetries;
  final Duration retryBaseDelay;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final StreamController<bool> _internetAvailabilityController = StreamController.broadcast();

  InternetConnectivityBloc({
    required this.connectivityHandler,
    this.apiDomain = 'google.com',
    this.maxRetries = 3,
    this.retryBaseDelay = const Duration(seconds: 2),
  }) {
    _connectivitySubscription = connectivityHandler.connectivityStream.listen(_handleConnectivityChange, onError: (error) => _internetAvailabilityController.add(false),);
  }

  /// Stream indicating whether the internet is available.
  Stream<bool> get internetAvailabilityStream => _internetAvailabilityController.stream;

  /// Handles connectivity changes.
  Future<void> _handleConnectivityChange(List<ConnectivityResult> result) async {
    if ( result.isEmpty || result[0] == ConnectivityResult.none) {
      _internetAvailabilityController.add(false);
    } else {
      final hasInternet = await _checkInternetConnectionWithRetries();
      _internetAvailabilityController.add(hasInternet);
    }
  }



  Future<bool> _checkInternetConnectionWithRetries() async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await InternetAddress.lookup(apiDomain);
        return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      } catch (_) {
        if (attempt == maxRetries - 1) return false;
        await Future.delayed(retryBaseDelay * (attempt + 1));
      }
    }
    return false;
  }





  /// Dispose resources.
  void dispose() {
    _connectivitySubscription.cancel();
    _internetAvailabilityController.close();
  }
}
