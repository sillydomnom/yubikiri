import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'listenable/listenable.dart';
import 'yubikiri.dart';
import 'test/test_yubikiri_provider.dart';

/// A data driven Widget that has the need to be regularly rebuilt
///
/// This widget is useful for you if you want to manage the state of your view in a simple way.
/// To use this, you would want to create an [Yubikiri] and a model.
///
/// **It is intended to use a simple type or a [YubikiriModel] as the model type.**
///
/// This widget is designed to be a normal widget that will rebuild itself if the model of the ViewModel is changed.
/// During development you can simply access the viewModel with the current model in the [build] function and the build function will be recalled when the ViewModel changes.
///
/// Example:
/// ```dart
/// class MyView extends MduView<MyViewModel, MyModel> {
///   @override
///   Widget build(BuildContext context, MyViewModel viewModel) {
///     return Text(viewModel.model.foo);
///   }
///
///   MyViewModel initViewModel() => MyViewModel();
/// }
/// ```
abstract class YubikiriView<T extends Yubikiri<J>, J> extends StatefulWidget {
  const YubikiriView({super.key});

  @protected
  T createYubikiri();

  @override
  @internal
  @mustCallSuper
  State<YubikiriView> createState() => _YubikiriViewState<T, J>();
  
  @mustCallSuper
  void onModelChange(BuildContext context, J oldModel, J newModel) {}

  Widget build(BuildContext context, T viewModel);
}

class _YubikiriViewState<T extends Yubikiri<J>, J> extends State<YubikiriView> {
  late J model;
  late T _yubikiri;

  late ListenableSubscription _modelSubscription;
  late StreamSubscription<void> _forceSubscription;

  _YubikiriViewState();

  @override
  void initState() {
    super.initState();

    final testViewModelExists = TestYubikiriProvider.exists<T>(context);

    if (testViewModelExists) {
      return;
    }

    _initViewModel();
  }

  @override
  void didUpdateWidget(covariant YubikiriView<Yubikiri, dynamic> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _yubikiri.didUpdateWidget(oldWidget, widget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final testProvider = TestYubikiriProvider.maybeOf<T>(context);

    if (testProvider == null) {
      _yubikiri.didChangeDependencies(context);
      return;
    }

    _yubikiri = testProvider.yubikiri;
    model = _yubikiri.model;

    _modelSubscription = _yubikiri.modelListenable.listen((modelListenable) {
      widget.onModelChange(context, this.model, modelListenable.value);
      setState(() {
        this.model = modelListenable.value;
      });
    });

    _forceSubscription = _yubikiri.forceRefreshStream.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();

    _modelSubscription.dispose();
    _forceSubscription.cancel();
    _yubikiri.dispose(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, _yubikiri);
  }

  void _initViewModel() {
    _yubikiri = widget.createYubikiri() as T;
    _yubikiri.init(context);

    model = _yubikiri.model;

    _modelSubscription = _yubikiri.modelListenable.listen((modelListenable) {
      widget.onModelChange(context, this.model, modelListenable.value);
      setState(() {
        this.model = modelListenable.value;
      });
    });

    _forceSubscription = _yubikiri.forceRefreshStream.listen((_) => setState(() {}));
  }
}
