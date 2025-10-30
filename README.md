# Yubikiri

[![pub.dev](https://img.shields.io/pub/v/yubikiri?logo=dart&logoColor=blue)](https://pub.dev/packages/yubikiri)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> **Yubikiri** (指切り) - meaning "pinky promise" in Japanese, representing the promise the view model made with the view over the model.

An architecture package that simplifies state management by providing an easy-to-use MVVM (Model-View-ViewModel) solution based on ValueNotifiers for Flutter applications. Its focus is easy usability and quick convertibility. You don't have to rebuild your whole application, but can go step by step.

This package is heavily inspired by this [Flutter Architecture guide](https://docs.flutter.dev/app-architecture/guide). Therefore it works best when paired in this way. It is recommended to let UI functionality be placed in the Yubikiri (View Model) and move functionality up if needed by multiple Yubikiris. Therefore it worked best in the past to create Use Cases to manage shared functionality. 

## Features

- 🏗️ **Clean MVVM Architecture** - Separate your business logic from UI with a clear, structured approach
- 🔄 **Reactive State Management** - Built on top of ValueNotifiers for efficient, automatic UI updates
- 🎯 **Lifecycle Aware** - Proper handling of widget lifecycle events (`init`, `didChangeDependencies`, `dispose`, `didUpdateWidget`)
- 🧪 **Testing First** - Comprehensive testing utilities with mock support and rebuild verification
- ⚡ **Performance Optimized** - Smart rebuilds only when model actually changes, with list comparison support
- 🔧 **Developer Friendly** - Intuitive API with excellent error handling and documentation

## Installation

Add `yubikiri` to your `pubspec.yaml`:

```yaml
dependencies:
  yubikiri: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Create a Model (optional)

Creating a model is not necessarily needed you can also go to step 2 if your data is compromised of simple data. Your model can also be a `bool` or an `int` as well. 
Model creation can also be simplified by making it freezed. 

**⚠️ It is mostly recommended to build your model in a way that makes sense for the view. If you have domain models it might be better to just provide the data of the domain model your view really needs.**

```dart
import 'package:yubikiri/yubikiri.dart';

class CounterModel extends YubikiriModel {
  final int count;
  final String status;

  const CounterModel({
    required this.count,
    required this.status,
  });

  @override
  List<Object?> get props => [count, status];

  CounterModel copyWith({
    int? count,
    String? status,
  }) {
    return CounterModel(
      count: count ?? this.count,
      status: status ?? this.status,
    );
  }
}
```

### 2. Create a ViewModel

ViewModels main responsibilities are: 
- managing dependencies (retrieving them via providers or GetIt)
- managing your application state

⚠️ It is possible to also forceRefresh your view but it is generally not recommended, try to only rebuild your view if it is really needed. 

```dart
class CounterYubikiri extends Yubikiri<CounterModel> {
  CounterYubikiri() : super(const CounterModel(count: 0, status: 'Ready'));

  void increment() {
    updateModel(model.copyWith(
      count: model.count + 1,
      status: 'Incremented',
    ));
  }

  void decrement() {
    updateModel(model.copyWith(
      count: model.count - 1,
      status: 'Decremented',
    ));
  }

  @override
  void init(BuildContext context) {
    super.init(context);
    // Initialize any dependencies, listeners, or services here
    print('CounterYubikiri initialized');
  }

  @override
  void dispose(BuildContext context) {
    // Clean up resources here
    print('CounterYubikiri disposed');
    super.dispose(context);
  }
}
```

### 3. Create a View

In your view your build function will always be called when the model is update and you can also act on functions on your view model. 

```dart
class CounterView extends YubikiriView<CounterYubikiri, CounterModel> {
  const CounterView({super.key});

  @override
  CounterYubikiri createYubikiri() => CounterViewModel();

  @override
  void onModelChange(BuildContext context, CounterModel oldModel, CounterModel newModel) {
    // React to model changes (optional)
    if (newModel.count > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Count is getting high!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, CounterYubikiri viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yubikiri Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Status: ${viewModel.model.status}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Text(
              '${viewModel.model.count}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: viewModel.decrement,
                  tooltip: 'Decrement',
                  child: const Icon(Icons.remove),
                ),
                FloatingActionButton(
                  onPressed: viewModel.increment,
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Advanced Usage

### Force Refresh

Sometimes you need to force a widget rebuild without changing the model:

```dart
class MyViewModel extends Yubikiri<MyModel> {
  void refreshView() {
    // Forces the view to rebuild even if model hasn't changed
    forceReloadView();
  }
}
```

### Working with Lists

Yubikiri automatically handles list comparison for optimal performance:

```dart
class TodoListModel extends YubikiriModel {
  final List<Todo> todos;

  const TodoListModel({required this.todos});

  @override
  List<Object?> get props => [todos];
}

class TodoListViewModel extends Yubikiri<TodoListModel> {
  TodoListViewModel() : super(const TodoListModel(todos: []));

  void addTodo(String title) {
    final newTodos = [...model.todos, Todo(title: title)];
    updateModel(TodoListModel(todos: newTodos));
    // Yubikiri will automatically compare lists and only rebuild if different
  }
}
```

### Widget properties

You can also provide properties from your widget to the view model, there are just some minor key details to keep in mind. 

```dart
class MyView extends YubikiriView<MyYubikiri, MyModel> {
  final String title; 

  @override
  Widget build(BuildContext context, MyYubikiri yubikiri) {}

  MyYubikiri createYubikiri => MyYubikiri(title: title); 
}
```

And now retrieve it from the View: 

```dart
class MyYubikiri extends Yubikiri<MyModel> {
  String title;
  
  const MyYubikiri({required this.title}) : super(MyModel(description: '$title desc'));

  // You have to react on widget updates otherwise you don't get notified that your property changed
  @override
  void didUpdateWidget(covariant MyView oldView, covariant MyView newView) {
    super.didUpdateWidget(oldView, newView);

    if (oldView.title != newView.title) {
      title = newView.title;
      doStuffWithNewTitle();
    }
  }
} 
```

## Testing

Yubikiri provides excellent testing utilities:

### Basic ViewModel Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yubikiri/test.dart';

void main() {
  group('CounterYubikiri', () {
    testWidgets('should increment count', (tester) async {
      final viewModelTester = await testYubikiri<CounterYubikiri, CounterModel>(
        tester,
        create: () => CounterYubikiri(),
      );

      // Initial state
      expect(viewModelTester.model.count, 0);
      expect(viewModelTester.model.status, 'Ready');

      // Perform action
      viewModelTester.viewModel.increment();
      await tester.pump();

      // Verify results
      expect(viewModelTester.model.count, 1);
      expect(viewModelTester.model.status, 'Incremented');

      // Verify rebuild occurred
      viewModelTester.verifyNRebuilds(1);
    });

    testWidgets('should track model changes', (tester) async {
      final viewModelTester = await testYubikiri<CounterYubikiri, CounterModel>(
        tester,
        create: () => CounterYubikiri(),
      );

      viewModelTester.viewModel.increment();
      viewModelTester.viewModel.increment();
      viewModelTester.viewModel.decrement();
      await tester.pumpAndSettle();

      // Check all model changes were recorded
      expect(viewModelTester.modelChanges.length, 3);
      expect(viewModelTester.modelChanges.map((m) => m.count), [1, 2, 1]);
    });
  });
}
```

### Testing with Dependencies

```dart
testWidgets('should work with context dependencies', (tester) async {
  final viewModelTester = await testYubikiri<MyViewModel, MyModel>(
    tester,
    create: () => MyViewModel(),
    parentBuilder: (context, child) => Provider<MyService>(
      create: (_) => MockMyService(),
      child: child,
    ),
  );

  // Your test logic here
});
```

### Verifying Rebuilds

```dart
testWidgets('should not rebuild when model is the same', (tester) async {
  final viewModelTester = await testYubikiri<CounterYubikiri, CounterModel>(
    tester,
    create: () => CounterYubikiri(),
  );

  // Update with same model
  viewModelTester.viewModel.updateModel(
    const CounterModel(count: 0, status: 'Ready')
  );
  await tester.pump();

  // Should not cause rebuild
  await viewModelTester.verifyNoMoreRebuilds();
});
```

## Architecture Principles

### MVVM Pattern

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │───▶│   ViewModel     │───▶│     Model       │
│  (YubikiriView) │    │   (Yubikiri)    │    │ (YubikiriModel) │
│                 │◀───│                 │    │                 │
│ - UI Components │    │ - Business Logic│    │ - Data State    │
│ - User Events   │    │ - State Mgmt    │    │ - Immutable     │
│ - Presentation  │    │ - Lifecycle     │    │ - Equatable     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Benefits

1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data
2. **Testability**: Easy to unit test ViewModels in isolation
3. **Maintainability**: Changes in one layer don't affect others
4. **Reusability**: ViewModels can be reused across different views
5. **Performance**: Efficient rebuilds only when necessary

## Best Practices

### 1. Model Design

```dart
// ✅ Good - Immutable model with copyWith
class UserModel extends YubikiriModel {
  final String name;
  final int age;
  final bool isActive;

  const UserModel({
    required this.name,
    required this.age,
    required this.isActive,
  });

  @override
  List<Object?> get props => [name, age, isActive];

  UserModel copyWith({
    String? name,
    int? age,
    bool? isActive,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ❌ Avoid - Mutable model
class BadUserModel {
  String name;
  int age;

  BadUserModel({required this.name, required this.age});
}
```

### 2. ViewModel Organization

```dart
class UserProfileViewModel extends Yubikiri<UserProfileModel> {
  final UserService _userService;
  final Logger _logger;

  UserProfileViewModel({
    required UserService userService,
    required Logger logger,
  }) : _userService = userService,
       _logger = logger,
       super(UserProfileModel.loading());

  // Public methods for UI interactions
  Future<void> loadUser(String userId) async {
    try {
      updateModel(model.copyWith(isLoading: true));
      final user = await _userService.getUser(userId);
      updateModel(UserProfileModel.success(user));
    } catch (e) {
      _logger.error('Failed to load user: $e');
      updateModel(UserProfileModel.error(e.toString()));
    }
  }

  void updateUserName(String newName) {
    if (newName.isEmpty) return;

    final updatedUser = model.user?.copyWith(name: newName);
    if (updatedUser != null) {
      updateModel(model.copyWith(user: updatedUser));
    }
  }

  // Private helper methods
  void _handleError(String error) {
    updateModel(model.copyWith(error: error, isLoading: false));
  }
}
```

### 3. View Implementation

```dart
class UserProfileView extends YubikiriView<UserProfileViewModel, UserProfileModel> {
  final String userId;

  const UserProfileView({required this.userId, super.key});

  @override
  UserProfileViewModel createYubikiri() => UserProfileViewModel(
    userService: GetIt.instance<UserService>(),
    logger: GetIt.instance<Logger>(),
  );

  @override
  void onModelChange(BuildContext context, UserProfileModel oldModel, UserProfileModel newModel) {
    // Handle side effects
    if (oldModel.error == null && newModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${newModel.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, UserProfileViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, UserProfileViewModel viewModel) {
    final model = viewModel.model;

    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (model.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${model.error}'),
            ElevatedButton(
              onPressed: () => viewModel.loadUser(userId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (model.user == null) {
      return const Center(child: Text('No user data'));
    }

    return _buildUserProfile(context, viewModel, model.user!);
  }
}
```

## Migration Guide

### From StatefulWidget

```dart
// Before (StatefulWidget)
class CounterPage extends StatefulWidget {
  @override
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$_counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: _increment,
        child: Icon(Icons.add),
      ),
    );
  }
}

// After (Yubikiri)
class CounterModel extends YubikiriModel {
  final int count;
  const CounterModel({required this.count});

  @override
  List<Object?> get props => [count];

  CounterModel copyWith({int? count}) =>
    CounterModel(count: count ?? this.count);
}

class CounterYubikiri extends Yubikiri<CounterModel> {
  CounterYubikiri() : super(const CounterModel(count: 0));

  void increment() {
    updateModel(model.copyWith(count: model.count + 1));
  }
}

class CounterPage extends YubikiriView<CounterYubikiri, CounterModel> {
  @override
  CounterYubikiri createYubikiri() => CounterViewModel();

  @override
  Widget build(BuildContext context, CounterYubikiri viewModel) {
    return Scaffold(
      body: Center(child: Text('${viewModel.model.count}')),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### From BLoC

```dart
// Before (with Bloc)
class CounterPage extends StatelessWidget {

  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CounterBloc, int>(
        builder: (context, state) => Center(child: Text('$state'))
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _increment,
        child: Icon(Icons.add),
      ),
    );   
  }
}

// After (Yubikiri still using BLoC in background)
class CounterModel extends YubikiriModel {
  final int count;
  const CounterModel({required this.count});

  @override
  List<Object?> get props => [count];

  CounterModel copyWith({int? count}) =>
    CounterModel(count: count ?? this.count);
}

class CounterYubikiri extends Yubikiri<CounterModel> {
  final CounterBloc bloc;

  CounterYubikiri() : super(const CounterModel(count: 0));

  @override
  void didChangeDependencies(BuildContext context) {
    super.didChangeDependencies(context);
    final bloc = BlocProvider.of<CounterBloc>(context);
    bloc.listen((state) => updateModel(CounterModel(count: state)));
  }

  void increment() {
    bloc.add(Increment());
  }
}

class CounterPage extends YubikiriView<CounterYubikiri, CounterModel> {
  @override
  CounterYubikiri createYubikiri() => CounterViewModel();

  @override
  Widget build(BuildContext context, CounterYubikiri viewModel) {
    return Scaffold(
      body: Center(child: Text('${viewModel.model.count}')),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## API Reference

### Core Classes

#### `Yubikiri<T>`

The base ViewModel class that manages state and lifecycle.

**Methods:**
- `updateModel(T newModel)` - Updates the model and triggers UI rebuild if changed
- `forceReloadView()` - Forces UI rebuild without model change
- `init(BuildContext context)` - Called when widget is first created
- `didChangeDependencies(BuildContext context)` - Called when dependencies change
- `didUpdateWidget(covariant YubikiriView oldView, covariant YubikiriView newView)` - Called when the widget was updated
- `dispose(BuildContext context)` - Called when widget is disposed

**Properties:**
- `model` - Current model instance
- `modelListenable` - ValueListenable for the current model

#### `YubikiriView<T, J>`

The base View widget that displays UI and handles user interactions.

**Methods:**
- `createYubikiri()` - Creates the ViewModel instance (has to be overridden)
- `build(BuildContext context, T viewModel)` - Builds the UI (has to be overridden)
- `onModelChange(BuildContext context, J oldModel, J newModel)` - Called when model changes

#### `YubikiriModel`

Base class for models with built-in equality comparison.

```dart
abstract class YubikiriModel extends Equatable {}
```

### Testing Utilities

#### `testYubikiri<T, J>()`

Creates a test environment for ViewModels.

```dart
Future<YubikiriTester<T, J>> testYubikiri<T extends Yubikiri<J>, J>(
  WidgetTester tester, {
  required T Function() create,
  Widget Function(BuildContext, Widget)? parentBuilder,
})
```

#### `YubikiriTester<T, J>`

Testing utility class with methods:
- `model` - Current model state
- `modelChanges` - List of all model changes
- `verifyNRebuilds(int count)` - Verify number of rebuilds occurred
- `verifyNoMoreRebuilds()` - Ensure no additional rebuilds happen
- `clear()` - Reset test state

<!-- ## Examples

Check out the [example](example/) directory for complete working examples:

- **Counter App** - Basic increment/decrement functionality
- **Todo List** - CRUD operations with lists
- **User Profile** - Async operations and error handling
- **Shopping Cart** - Complex state management
- **Theme Switcher** - Context-dependent updates -->

<!-- ## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository:
```bash
git clone https://github.com/your-username/yubikiri.git
cd yubikiri
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run tests:
```bash
flutter test
```

4. Run analysis:
```bash
flutter analyze
``` -->

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://pub.dev/documentation/yubikiri)
- 🐛 [Issue Tracker](https://github.com/your-username/yubikiri/issues)
- 💬 [Discussions](https://github.com/your-username/yubikiri/discussions)

---

Made with ❤️ by Dominik Schumann @ MaibornWolff
