import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ex1/blocs/connectivity_handler.dart';




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
    _connectivitySubscription = connectivityHandler.connectivityStream.listen(_handleConnectivityChange);
  }

  /// Stream indicating whether the internet is available.
  Stream<bool> get internetAvailabilityStream => _internetAvailabilityController.stream;

  /// Handles connectivity changes.
  Future<void> _handleConnectivityChange(List<ConnectivityResult> result) async {
    if ( result.isEmpty || result[0] == ConnectivityResult.none) {
      _internetAvailabilityController.add(false);
    } else {
      final hasInternet = await _checkInternetConnection();
      _internetAvailabilityController.add(hasInternet);
    }
  }

  /// Verifies internet connectivity using a DNS lookup.
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(apiDomain);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retry logic for transient failures.
  Future<T> retryWithBackoff<T>(Future<T> Function() action) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {

        return await action();

      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(retryBaseDelay * (1 << (attempt - 1))); // Exponential backoff
      }
    }
    throw Exception('Max retries reached');
  }

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription.cancel();
    _internetAvailabilityController.close();
  }
}
