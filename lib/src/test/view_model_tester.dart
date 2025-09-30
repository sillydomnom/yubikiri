import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yubikiri/src/listenable/listenable.dart';

import '../yubikiri.dart';



/// Creates a [YubikiriTester] that emulates normal flutter widget behavior
///
/// On creation it will call init and didChangeDependencies. On the one side you are able to test if the model has the states you are expecting.
/// On the other side you are able to check how often your widget did rebuild.
///
/// If there are dependencies that are provided via the [BuildContext] you can add a [parentBuilder], with this you are able to add a BlocProvider for example.
///
/// ```dart
/// await testViewModel(
///   tester,
///   create: () => MyViewModel(),
///   parentBuilder: (context, child) => MyDependency(
///     child: child,
///   )
/// );
/// ```
Future<YubikiriTester<T, J>> testYubikiri<T extends Yubikiri<J>, J>(
  WidgetTester tester, {
  required T Function() create,
  Widget Function(BuildContext, Widget)? parentBuilder,
}) async {
  final viewModelTester = YubikiriTester<T, J>(viewModel: create());

  await viewModelTester.init(tester, parentBuilder: parentBuilder);
  return viewModelTester;
}

class YubikiriTester<T extends Yubikiri<J>, J> {
  final T viewModel;
  late _TestView _testView;
  final List<J> _modelChanges = [];

  final _RebuildCaller _rebuildCaller = _MockRebuildCaller();
  late WidgetTester _widgetTester;

  YubikiriTester({required this.viewModel});

  J get model => viewModel.model;
  List<J> get modelChanges => _modelChanges;

  /// clears up all saved states, e.g. all saved changes, rebuild calls
  void clear() {
    _modelChanges.clear();
    reset(_rebuildCaller);
  }

  /// checks how often a widget rebuilt was happening
  ///
  /// Because of flutters performance optimization it could happen that the number of rebuilds is less then you expect.
  /// It is recommended to use this in combination with [verifyNoMoreRebuilds] to check that there is no rebuild in the future.
  void verifyNRebuilds(int rebuildCount) {
    verify(() => _rebuildCaller.didRebuild()).called(rebuildCount);
    reset(_rebuildCaller);
  }

  /// makes sure that there is no rebuild happening later on
  Future<void> verifyNoMoreRebuilds() async {
    verifyNever(() => _rebuildCaller.didRebuild());

    await _widgetTester.pumpAndSettle();
    verifyNever(() => _rebuildCaller.didRebuild());

    reset(_rebuildCaller);
  }

  @internal
  Future<void> init(WidgetTester tester, {Widget Function(BuildContext, Widget)? parentBuilder}) async {
    _testView = _TestView<T, J>(viewModel, rebuildCaller: _rebuildCaller);
    _widgetTester = tester;

    viewModel.modelListenable.listen((valueListenable) => _modelChanges.add(valueListenable.value));
    await tester.pumpWidget(Builder(builder: (context) => parentBuilder?.call(context, _testView) ?? _testView));
  }
}

class _TestView<T extends Yubikiri<J>, J> extends YubikiriView<T, J> {
  final T viewModel;
  final _RebuildCaller? _rebuildCaller;

  const _TestView(this.viewModel, {_RebuildCaller? rebuildCaller}) : _rebuildCaller = rebuildCaller;

  @override
  Widget build(BuildContext context, model) {
    _rebuildCaller?.didRebuild();

    return SizedBox.shrink();
  }

  @override
  T createYubikiri() => viewModel;
}

abstract class _RebuildCaller {
  void didRebuild();
}

class _MockRebuildCaller extends Mock implements _RebuildCaller {}
