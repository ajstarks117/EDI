import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStateProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() async {
    try {
      final results = await Connectivity().checkConnectivity();
      state = !results.contains(ConnectivityResult.none);
    } catch (_) {
      state = true;
    }
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      state = !results.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
