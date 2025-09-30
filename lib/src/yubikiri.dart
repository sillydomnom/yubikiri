import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'yubikiri_model.dart';
import 'yubikiri_view.dart';

export 'yubikiri_model.dart';
export 'yubikiri_view.dart';

/// A representation of the data management of a [YubikiriView]
/// This way, each [YubikiriView] has one model at one time.
///
/// **It is intended to use a simple type or a [YubikiriModel] as the model type.**
///
/// This way, there are only two possibilities left, when a singular [YubikiriView] will be rebuilt:
/// - Either when [updateModel] is called
/// - Or when flutter decides that this widget should be rebuilt (e.g. screen size changes, language change)
///
/// There are currently three lifecycle functions:
/// - [init] which should be used when you want to do some initial retrieval (e.g. adding listeners, retrieving GetIt dependencies)
/// - [didChangeDependencies] which should be used when retrieving context dependencies (e.g. Provider, ChangeNotifier, Theme, Localization)
/// - [dispose] which is needed to do cleanUp Tasks
///
/// Example:
/// ```dart
/// class MyViewModel extends MduViewModel<MyModel> {
///   // initial Model state
///   MyViewModel() : super(MyModel(foo: 'bar'));
///
///   @override
///   init(BuildContext context) {
///     final dependency = GetIt.I.get<MyDependency>();
///     updateModel(MyModel(foo: dependency.foo));
///   }
///
///   @override
///   didChangeDependencies(BuildContext context) {
///     final provider = Provider.of<MyProvider>(context);
///     updateModel(MyModel(foo: provider.foo));
///   }
/// }
/// ```
abstract class Yubikiri<T> {
  Yubikiri(T model) : _modelNotifier = ValueNotifier(model);

  // Model Management

  final ValueNotifier<T> _modelNotifier;
  ValueListenable<T> get modelListenable => _modelNotifier;

  T get model => _modelNotifier.value;

  final StreamController<void> _forceRefreshStreamController = StreamController();
  Stream<void> get forceRefreshStream => _forceRefreshStreamController.stream;

  /// updates the current model for the [YubikiriView] and will rebuilt the view
  ///
  /// For performance optimization a rebuilt won't happen when [newModel] did not change.
  @protected
  void updateModel(T newModel) {
    if (model == newModel || (model is List && listEquals(model as List, newModel as List))) {
      return;
    }

    _modelNotifier.value = newModel;
  }

  @protected
  void forceReloadView() {
    _forceRefreshStreamController.add(null);
  }

  // Widget Lifecycle

  @mustCallSuper
  void init(BuildContext context) {}

  @mustCallSuper
  void dispose(BuildContext context) {
    _modelNotifier.dispose();
  }

  @mustCallSuper
  void didChangeDependencies(BuildContext context) {}

  @mustCallSuper
  void didUpdateWidget(covariant YubikiriView oldView, covariant YubikiriView newView) {}
}
