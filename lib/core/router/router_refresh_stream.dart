import 'dart:async';
import 'package:flutter/material.dart';

/// A [ChangeNotifier] that triggers whenever the given [stream] emits.
/// Useful for [GoRouter]'s refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
