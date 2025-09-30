import 'package:flutter/material.dart';

import '../yubikiri.dart';

/// A Provider class that is able to inject a mocked [Yubikiri] into a View
///
/// To use this, you just have to wrap this class around the View you want to test and a dd a viewModel.
/// From this point on, the View will only reference the Mock.
///
/// ```dart
/// late MyViewModel _myViewModel
///
/// Future<void> pumpWidget(WidgetTester tester) {
///   _myViewModel = MockMyViewModel();
///
///   await tester.pumpApp(
///     TestViewModelProvider<MyViewModel>(
///       viewModel: _myViewModel,
///       child: MyView(),
///     )
///   )
/// }
/// ```
class TestYubikiriProvider<T extends Yubikiri> extends InheritedWidget {
  final T yubikiri;

  const TestYubikiriProvider({super.key, required super.child, required this.yubikiri});

  static TestYubikiriProvider<T>? maybeOf<T extends Yubikiri>(BuildContext context) {
    try {
      return context.dependOnInheritedWidgetOfExactType<TestYubikiriProvider<T>>();
    } catch (_) {
      return null;
    }
  }

  static bool exists<T extends Yubikiri>(BuildContext context) {
    final providerElement = context.getElementForInheritedWidgetOfExactType<TestYubikiriProvider<T>>();

    context.findAncestorWidgetOfExactType<TestYubikiriProvider<T>>();
    return providerElement != null;
  }

  @override
  bool updateShouldNotify(covariant TestYubikiriProvider oldWidget) => oldWidget.yubikiri != this.yubikiri;
}
