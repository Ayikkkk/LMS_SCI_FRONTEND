// lib/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._private();
  static final NavigationService instance = NavigationService._private();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Queue of navigation actions to run once navigator is ready.
  final List<void Function(NavigatorState)> _pending = [];

  bool get isReady => navigatorKey.currentState != null;

  // Push an action immediately if ready, otherwise queue it.
  void runOrQueue(void Function(NavigatorState nav) action) {
    final navState = navigatorKey.currentState;
    if (navState != null) {
      try {
        action(navState);
      } catch (e) {
        // swallow errors to avoid crash during navigation transitions
        // (you can log here if you have a logger)
      }
    } else {
      _pending.add(action);
    }
  }

  // Should be called when MaterialApp is built and navigator becomes available.
  // Typically not required because navigatorKey.currentState will be non-null,
  // but we provide an explicit flush method to be safe.
  void flushPending() {
    final navState = navigatorKey.currentState;
    if (navState == null) return;
    for (final action in List<void Function(NavigatorState)>.from(_pending)) {
      try {
        action(navState);
      } catch (_) {}
    }
    _pending.clear();
  }
}
