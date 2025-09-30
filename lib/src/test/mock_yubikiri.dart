import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

import '../yubikiri.dart';

class MockYubikiri<T> extends Mock implements Yubikiri<T> {
  MockYubikiri() {
    when(() => forceRefreshStream).thenAnswer((_) => StreamController().stream);
    when(() => modelListenable).thenAnswer((_) => ValueNotifier(model));
  }
}
