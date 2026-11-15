import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkAvailability { unknown, connected, disconnected }

class NetworkStatusService extends ChangeNotifier {
  NetworkStatusService._({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  static final NetworkStatusService instance = NetworkStatusService._();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkAvailability _availability = NetworkAvailability.unknown;
  bool _checking = false;

  NetworkAvailability get availability => _availability;
  bool get isDisconnected => _availability == NetworkAvailability.disconnected;
  bool get isChecking => _checking;

  Future<void> initialize() async {
    if (_subscription != null) return;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _applyResults,
      onError: (_) {},
    );
    await refresh();
  }

  Future<bool> refresh() async {
    _setChecking(true);
    try {
      final results = await _connectivity.checkConnectivity();
      _applyResults(results);
      return !isDisconnected;
    } catch (_) {
      return _availability != NetworkAvailability.disconnected;
    } finally {
      _setChecking(false);
    }
  }

  void reportRequestSucceeded() {
    _setAvailability(NetworkAvailability.connected);
  }

  void _applyResults(List<ConnectivityResult> results) {
    final hasNetwork = results.any((result) => result != ConnectivityResult.none);
    _setAvailability(
      hasNetwork
          ? NetworkAvailability.connected
          : NetworkAvailability.disconnected,
    );
  }

  void _setAvailability(NetworkAvailability value) {
    if (_availability == value) return;
    _availability = value;
    notifyListeners();
  }

  void _setChecking(bool value) {
    if (_checking == value) return;
    _checking = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
