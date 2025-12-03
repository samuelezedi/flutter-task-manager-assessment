import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/services/hive_service.dart';
import 'package:task_manager_app/services/firebase_service.dart';
import 'package:task_manager_app/services/connectivity_service.dart';
import 'package:task_manager_app/services/sync_service.dart';

// Mock classes for testing
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

  @override
  List<Task> getPendingSyncTasks() {
    return _tasks.values.where((t) => t.isPendingSync).toList();
  }

  @override
  Future<void> markTaskAsSynced(String id) async {
    final task = _tasks[id];
    if (task != null) {
      _tasks[id] = task.copyWith(
        isPendingSync: false,
        syncedAt: DateTime.now(),
      );
    }
  }
}

class MockFirebaseService extends FirebaseService {
  final Map<String, Task> _tasks = {};
  bool _isAuthenticated = true;

  MockFirebaseService() {
    // Don't call super constructor to avoid Firebase initialization
  }

  void setAuthenticated(bool value) => _isAuthenticated = value;

  @override
  bool get isFirebaseInitialized => true;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get currentUserId => _isAuthenticated ? 'test-user' : null;

  @override
  Future<Task?> getTask(String taskId) async {
    return _tasks[taskId];
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return _tasks.values.toList();
  }

  @override
  Future<void> saveTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.remove(taskId);
  }

  @override
  Stream<List<Task>> streamTasks() {
    return Stream.value(_tasks.values.toList());
  }

  void addTask(Task task) {
    _tasks[task.id] = task;
  }
}

class MockConnectivityService extends ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  MockConnectivityService() {
    _controller.add(_isOnline); // Initialize stream
  }

  void setOnline(bool value) {
    _isOnline = value;
    _controller.add(_isOnline);
  }

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get connectionStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;
    late MockHiveService mockHiveService;
    late MockFirebaseService mockFirebaseService;
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockHiveService = MockHiveService();
      mockFirebaseService = MockFirebaseService();
      mockConnectivityService = MockConnectivityService();

      syncService = SyncService(
        hiveService: mockHiveService,
        firebaseService: mockFirebaseService,
        connectivityService: mockConnectivityService,
      );
    });

    group('Conflict Resolution', () {
      test('should use Firebase version when Firebase is newer', () async {
        final now = DateTime.now();
        final localTask = Task(
          id: 'task-1',
          title: 'Local Title',
          updatedAt: now.subtract(const Duration(hours: 1)),
          isPendingSync: true,
        );

        final firebaseTask = Task(
          id: 'task-1',
          title: 'Firebase Title',
          updatedAt: now,
        );

        await mockHiveService.saveTask(localTask);
        mockFirebaseService.addTask(firebaseTask);

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 0); // Should not sync, Firebase version kept
        final savedTask = mockHiveService.getTask('task-1');
        expect(savedTask?.title, 'Firebase Title');
      });

      test('should use local version when local is newer', () async {
        final now = DateTime.now();
        final localTask = Task(
          id: 'task-1',
          title: 'Local Title (Newer)',
          updatedAt: now,
          isPendingSync: true,
        );

        final firebaseTask = Task(
          id: 'task-1',
          title: 'Firebase Title (Older)',
          updatedAt: now.subtract(const Duration(hours: 1)),
        );

        await mockHiveService.saveTask(localTask);
        mockFirebaseService.addTask(firebaseTask);

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 1); // Should sync local version
        final firebaseTaskAfter = await mockFirebaseService.getTask('task-1');
        expect(firebaseTaskAfter?.title, 'Local Title (Newer)');
      });

      test('should sync new task when no conflict exists', () async {
        final task = Task(
          id: 'task-1',
          title: 'New Task',
          isPendingSync: true,
        );

        await mockHiveService.saveTask(task);

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 1);
        final firebaseTask = await mockFirebaseService.getTask('task-1');
        expect(firebaseTask, isNotNull);
        expect(firebaseTask?.title, 'New Task');
      });
    });

    group('Sync To Firebase', () {
      test('should not sync when offline', () async {
        mockConnectivityService.setOnline(false);
        final task = Task(id: 'task-1', title: 'Task', isPendingSync: true);
        await mockHiveService.saveTask(task);

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 0);
      });

      test('should not sync when not authenticated', () async {
        mockFirebaseService.setAuthenticated(false);
        final task = Task(id: 'task-1', title: 'Task', isPendingSync: true);
        await mockHiveService.saveTask(task);

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 0);
      });

      test('should sync multiple pending tasks', () async {
        final tasks = [
          Task(id: 'task-1', title: 'Task 1', isPendingSync: true),
          Task(id: 'task-2', title: 'Task 2', isPendingSync: true),
          Task(id: 'task-3', title: 'Task 3', isPendingSync: false),
        ];

        for (final task in tasks) {
          await mockHiveService.saveTask(task);
        }

        final syncedCount = await syncService.syncToFirebase();

        expect(syncedCount, 2);
      });

      test('should mark tasks as synced after successful sync', () async {
        final task = Task(id: 'task-1', title: 'Task', isPendingSync: true);
        await mockHiveService.saveTask(task);

        await syncService.syncToFirebase();

        final savedTask = mockHiveService.getTask('task-1');
        expect(savedTask?.isPendingSync, false);
        expect(savedTask?.syncedAt, isNotNull);
      });
    });

    group('Sync From Firebase', () {
      test('should download new tasks from Firebase', () async {
        final firebaseTask = Task(id: 'task-1', title: 'Firebase Task');
        mockFirebaseService.addTask(firebaseTask);

        await syncService.syncFromFirebase();

        final localTask = mockHiveService.getTask('task-1');
        expect(localTask, isNotNull);
        expect(localTask?.title, 'Firebase Task');
      });

      test('should not overwrite local pending changes', () async {
        final now = DateTime.now();
        final localTask = Task(
          id: 'task-1',
          title: 'Local Task',
          updatedAt: now,
          isPendingSync: true,
        );

        final firebaseTask = Task(
          id: 'task-1',
          title: 'Firebase Task',
          updatedAt: now.subtract(const Duration(hours: 1)),
        );

        await mockHiveService.saveTask(localTask);
        mockFirebaseService.addTask(firebaseTask);

        await syncService.syncFromFirebase();

        final savedTask = mockHiveService.getTask('task-1');
        expect(savedTask?.title, 'Local Task'); // Local should be preserved
      });

      test('should update local task when Firebase is newer and no pending changes', () async {
        final now = DateTime.now();
        final localTask = Task(
          id: 'task-1',
          title: 'Local Task',
          updatedAt: now.subtract(const Duration(hours: 1)),
          isPendingSync: false,
        );

        final firebaseTask = Task(
          id: 'task-1',
          title: 'Firebase Task (Newer)',
          updatedAt: now,
        );

        await mockHiveService.saveTask(localTask);
        mockFirebaseService.addTask(firebaseTask);

        await syncService.syncFromFirebase();

        final savedTask = mockHiveService.getTask('task-1');
        expect(savedTask?.title, 'Firebase Task (Newer)');
      });
    });

    group('Delete Task', () {
      test('should delete task from local storage', () async {
        final task = Task(id: 'task-1', title: 'Task');
        await mockHiveService.saveTask(task);

        await syncService.deleteTask('task-1');

        final localTask = mockHiveService.getTask('task-1');
        expect(localTask, isNull);
      });

      test('should delete task from Firebase when online', () async {
        final task = Task(id: 'task-1', title: 'Task');
        mockFirebaseService.addTask(task);

        await syncService.deleteTask('task-1');

        final firebaseTask = await mockFirebaseService.getTask('task-1');
        expect(firebaseTask, isNull);
      });
    });
  });
}
