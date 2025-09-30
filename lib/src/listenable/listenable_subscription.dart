import 'package:flutter/foundation.dart';

/// A wrapper for [ValueListenable] listeners
///
/// The API for [ValueListenable]s is quite hard to use as a listener is not able to be changed.
/// Therefore a Subscription can be invoked to take care of the lifecycle of a listener.
///
/// **Make sure to [dispose] the listener if it is not needed anymore**
class ListenableSubscription<T extends Listenable> {
  final T _listenable;
  final void Function(T) _callback;

  ListenableSubscription({required T listenable, required void Function(T) callback})
      : _listenable = listenable,
        _callback = callback {
    _listenable.addListener(_onValue);
  }

  void _onValue() {
    _callback.call(_listenable);
  }

  void dispose() {
    _listenable.removeListener(_onValue);
  }
}
