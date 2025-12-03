import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/services/hive_service.dart';

void main() {
  group('HiveService Tests', () {
    late HiveService hiveService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
    });

    setUp(() async {
      hiveService = HiveService();
      await hiveService.init();
      // Clear all tasks before each test
      await hiveService.deleteAllTasks();
    });

    tearDown(() async {
      await hiveService.deleteAllTasks();
      await hiveService.close();
    });

    test('should initialize successfully', () async {
      expect(hiveService, isNotNull);
      expect(hiveService.getAllTasks(), isEmpty);
    });

    test('should save and retrieve a task', () async {
      final task = Task(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      await hiveService.saveTask(task);
      final retrieved = hiveService.getTask('test-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.title, 'Test Task');
      expect(retrieved.description, 'Test Description');
    });

    test('should return null for non-existent task', () {
      final task = hiveService.getTask('non-existent');
      expect(task, isNull);
    });

    test('should save multiple tasks', () async {
      final tasks = [
        Task(id: 'task-1', title: 'Task 1'),
        Task(id: 'task-2', title: 'Task 2'),
        Task(id: 'task-3', title: 'Task 3'),
      ];

      await hiveService.saveTasks(tasks);
      final allTasks = hiveService.getAllTasks();

      expect(allTasks.length, 3);
      expect(allTasks.map((t) => t.id), containsAll(['task-1', 'task-2', 'task-3']));
    });

    test('should get all tasks', () async {
      await hiveService.saveTask(Task(id: 'task-1', title: 'Task 1'));
      await hiveService.saveTask(Task(id: 'task-2', title: 'Task 2'));

      final allTasks = hiveService.getAllTasks();
      expect(allTasks.length, 2);
    });

    test('should delete a task', () async {
      await hiveService.saveTask(Task(id: 'task-1', title: 'Task 1'));
      await hiveService.deleteTask('task-1');

      final task = hiveService.getTask('task-1');
      expect(task, isNull);
    });

    test('should delete all tasks', () async {
      await hiveService.saveTask(Task(id: 'task-1', title: 'Task 1'));
      await hiveService.saveTask(Task(id: 'task-2', title: 'Task 2'));

      await hiveService.deleteAllTasks();
      final allTasks = hiveService.getAllTasks();

      expect(allTasks, isEmpty);
    });

    test('should get pending sync tasks', () async {
      final task1 = Task(id: 'task-1', title: 'Task 1', isPendingSync: true);
      final task2 = Task(id: 'task-2', title: 'Task 2', isPendingSync: false);
      final task3 = Task(id: 'task-3', title: 'Task 3', isPendingSync: true);

      await hiveService.saveTask(task1);
      await hiveService.saveTask(task2);
      await hiveService.saveTask(task3);

      final pendingTasks = hiveService.getPendingSyncTasks();

      expect(pendingTasks.length, 2);
      expect(pendingTasks.map((t) => t.id), containsAll(['task-1', 'task-3']));
      expect(pendingTasks.every((t) => t.isPendingSync), isTrue);
    });

    test('should mark task as synced', () async {
      final task = Task(
        id: 'task-1',
        title: 'Task 1',
        isPendingSync: true,
      );

      await hiveService.saveTask(task);
      await hiveService.markTaskAsSynced('task-1');

      final updatedTask = hiveService.getTask('task-1');
      expect(updatedTask, isNotNull);
      expect(updatedTask!.isPendingSync, false);
      expect(updatedTask.syncedAt, isNotNull);
    });

    test('should handle marking non-existent task as synced', () async {
      // Should not throw an error
      await hiveService.markTaskAsSynced('non-existent');
    });

    test('should update existing task when saving with same ID', () async {
      final task1 = Task(id: 'task-1', title: 'Original Title');
      await hiveService.saveTask(task1);

      final task2 = Task(id: 'task-1', title: 'Updated Title');
      await hiveService.saveTask(task2);

      final allTasks = hiveService.getAllTasks();
      expect(allTasks.length, 1);
      expect(allTasks.first.title, 'Updated Title');
    });
  });
}
