import 'package:flutter/foundation.dart';

import 'listenable_subscription.dart';

extension ListenableListener<T extends Listenable> on T {
  ListenableSubscription<T> listen(void Function(T) callback) {
    return ListenableSubscription<T>(listenable: this, callback: callback);
  }
}
