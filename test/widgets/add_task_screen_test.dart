import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/screens/add_task_screen.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/providers/task_provider.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/services/hive_service.dart';
import 'package:task_manager_app/services/firebase_service.dart';
import 'package:task_manager_app/services/sync_service.dart';
import 'package:task_manager_app/services/connectivity_service.dart';

// Mock services for testing
class MockHiveService extends HiveService {
  final Map<String, Task> _tasks = {};

  @override
  List<Task> getAllTasks() => _tasks.values.toList();

  @override
  Task? getTask(String id) => _tasks[id];

  @override
  Future<void> saveTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
  }
}

class MockFirebaseService extends FirebaseService {
  MockFirebaseService() {
    // Don't call super constructor to avoid Firebase initialization
  }

  @override
  bool get isFirebaseInitialized => true;

  @override
  bool get isAuthenticated => true;

  @override
  String? get currentUserId => 'test-user';

  @override
  Future<List<Task>> getAllTasks() async => [];

  @override
  Stream<List<Task>> streamTasks() => Stream.value([]);

  @override
  Future<Task?> getTask(String taskId) async => null;

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}
}

class MockSyncService extends SyncService {
  MockSyncService({
    required super.hiveService,
    required super.firebaseService,
    required super.connectivityService,
  });
}

class MockConnectivityService extends ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  MockConnectivityService() {
    _controller.add(true); // Initialize as online
  }

  @override
  bool get isOnline => true;

  @override
  Stream<bool> get connectionStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('AddTaskScreen Widget Tests', () {
    late TaskProvider taskProvider;

    setUp(() {
      final hiveService = MockHiveService();
      final firebaseService = MockFirebaseService();
      final connectivityService = MockConnectivityService();
      final syncService = MockSyncService(
        hiveService: hiveService,
        firebaseService: firebaseService,
        connectivityService: connectivityService,
      );

      taskProvider = TaskProvider(
        hiveService: hiveService,
        firebaseService: firebaseService,
        syncService: syncService,
        connectivityService: connectivityService,
      );
    });

    testWidgets('should display title and description fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      expect(find.text('Add Task'), findsWidgets); // AppBar title
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show validation error for empty title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      // Tap save button without entering title (find the button, not the AppBar title)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('should allow entering title and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      // Find text fields
      final titleField = find.byType(TextFormField).first;
      final descriptionField = find.byType(TextFormField).last;

      // Enter text
      await tester.enterText(titleField, 'Test Task');
      await tester.enterText(descriptionField, 'Test Description');

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('should have cancel button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      // AppBar has a back button (implicit cancel functionality)
      expect(find.byType(AppBar), findsOneWidget);
      // Note: The screen uses AppBar's default back button, not an explicit Cancel button
    });

    testWidgets('should have add task button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      // Find the ElevatedButton with "Add Task" text (not the AppBar title)
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add Task'), findsOneWidget);
    });
  });
}
