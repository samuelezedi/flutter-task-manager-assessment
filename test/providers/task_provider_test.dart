import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/providers/task_provider.dart';
import 'package:task_manager_app/services/hive_service.dart';
import 'package:task_manager_app/services/firebase_service.dart';
import 'package:task_manager_app/services/sync_service.dart';
import 'package:task_manager_app/services/connectivity_service.dart';

// Mock services
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
  bool _isAuthenticated = true;
  String? _userId = 'test-user';

  MockFirebaseService() {
    // Don't call super constructor to avoid Firebase initialization
  }

  void setAuthenticated(bool value) => _isAuthenticated = value;

  @override
  bool get isFirebaseInitialized => true;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get currentUserId => _userId;

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
  final HiveService _hiveService;
  
  MockSyncService({
    required HiveService hiveService,
    required super.firebaseService,
    required super.connectivityService,
  }) : _hiveService = hiveService,
       super(hiveService: hiveService);

  @override
  Future<void> syncFromFirebase() async {}

  @override
  Future<int> syncToFirebase() async => 0;

  @override
  Future<void> performFullSync() async {}

  @override
  Future<void> deleteTask(String taskId) async {
    await _hiveService.deleteTask(taskId);
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
  group('TaskProvider Tests', () {
    late TaskProvider taskProvider;
    late MockHiveService mockHiveService;
    late MockFirebaseService mockFirebaseService;
    late MockSyncService mockSyncService;
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockHiveService = MockHiveService();
      mockFirebaseService = MockFirebaseService();
      mockConnectivityService = MockConnectivityService();
      mockSyncService = MockSyncService(
        hiveService: mockHiveService,
        firebaseService: mockFirebaseService,
        connectivityService: mockConnectivityService,
      );

      taskProvider = TaskProvider(
        hiveService: mockHiveService,
        firebaseService: mockFirebaseService,
        syncService: mockSyncService,
        connectivityService: mockConnectivityService,
      );
    });

    test('should initialize with empty tasks', () async {
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.isLoading, false);
      expect(taskProvider.isSyncing, false);
    });

    test('should add a new task', () async {
      await taskProvider.addTask('Test Task', 'Test Description');

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, 'Test Task');
      expect(taskProvider.tasks.first.description, 'Test Description');
      expect(taskProvider.tasks.first.isPendingSync, true);
    });

    test('should update a task', () async {
      final task = Task(id: 'task-1', title: 'Original Title');
      await mockHiveService.saveTask(task);
      await taskProvider.loadTasks();

      final updatedTask = task.copyWith(title: 'Updated Title');
      await taskProvider.updateTask(updatedTask);

      expect(taskProvider.tasks.first.title, 'Updated Title');
      expect(taskProvider.tasks.first.isPendingSync, true);
    });

    test('should toggle task completion', () async {
      final task = Task(id: 'task-1', title: 'Task', isCompleted: false);
      await mockHiveService.saveTask(task);
      await taskProvider.loadTasks();

      await taskProvider.toggleTaskCompletion(task);

      expect(taskProvider.tasks.first.isCompleted, true);
    });

    test('should delete a task', () async {
      final task = Task(id: 'task-1', title: 'Task');
      await mockHiveService.saveTask(task);
      await taskProvider.loadTasks();

      expect(taskProvider.tasks.length, 1);

      await taskProvider.deleteTask('task-1');

      expect(taskProvider.tasks, isEmpty);
    });

    test('should filter tasks by completion status', () async {
      await mockHiveService.saveTask(Task(id: 'task-1', title: 'Task 1', isCompleted: false));
      await mockHiveService.saveTask(Task(id: 'task-2', title: 'Task 2', isCompleted: true));
      await mockHiveService.saveTask(Task(id: 'task-3', title: 'Task 3', isCompleted: false));
      await taskProvider.loadTasks();

      final activeTasks = taskProvider.getTasksByStatus(false);
      final completedTasks = taskProvider.getTasksByStatus(true);

      expect(activeTasks.length, 2);
      expect(completedTasks.length, 1);
      expect(activeTasks.map((t) => t.id), containsAll(['task-1', 'task-3']));
      expect(completedTasks.map((t) => t.id), contains('task-2'));
    });

    test('should return correct pending sync count', () async {
      await mockHiveService.saveTask(Task(id: 'task-1', title: 'Task 1', isPendingSync: true));
      await mockHiveService.saveTask(Task(id: 'task-2', title: 'Task 2', isPendingSync: false));
      await mockHiveService.saveTask(Task(id: 'task-3', title: 'Task 3', isPendingSync: true));
      await taskProvider.loadTasks();

      expect(taskProvider.pendingSyncCount, 2);
    });

    test('should return unmodifiable task list', () {
      expect(() => taskProvider.tasks.add(Task(id: 'test', title: 'Test')), throwsA(isA<UnsupportedError>()));
    });
  });
}

