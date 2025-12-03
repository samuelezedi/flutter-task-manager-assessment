import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/screens/add_task_screen.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/providers/task_provider.dart';
import 'package:task_manager_app/services/hive_service.dart';
import 'package:task_manager_app/services/firebase_service.dart';
import 'package:task_manager_app/services/sync_service.dart';
import 'package:task_manager_app/services/connectivity_service.dart';

// Mock services for testing
class MockHiveService extends HiveService {}
class MockFirebaseService extends FirebaseService {
  @override
  bool get isAuthenticated => true;
  @override
  String? get currentUserId => 'test-user';
}
class MockSyncService extends SyncService {
  MockSyncService({
    required super.hiveService,
    required super.firebaseService,
    required super.connectivityService,
  });
}
class MockConnectivityService extends ConnectivityService {
  @override
  bool get isOnline => true;
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

    testWidgets('should display title and description fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show validation error for empty title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const AddTaskScreen(),
          ),
        ),
      );

      // Tap save button without entering title
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('should allow entering title and description', (WidgetTester tester) async {
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

      expect(find.text('Cancel'), findsOneWidget);
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

      expect(find.text('Add Task'), findsOneWidget);
    });
  });
}

