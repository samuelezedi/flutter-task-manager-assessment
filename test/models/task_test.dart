import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('should create a task with default values', () {
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
      );

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.description, '');
      expect(task.isCompleted, false);
      expect(task.isPendingSync, false);
      expect(task.syncedAt, isNull);
      expect(task.userId, isNull);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('should create a task with all parameters', () {
      final now = DateTime.now();
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
        isPendingSync: true,
        userId: 'user-123',
      );

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.isCompleted, true);
      expect(task.isPendingSync, true);
      expect(task.syncedAt, now);
      expect(task.userId, 'user-123');
    });

    test('should create a copy with updated fields', () {
      final original = Task(
        id: 'original-id',
        title: 'Original Title',
        description: 'Original Description',
        isCompleted: false,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isCompleted: true,
      );

      expect(updated.id, 'original-id');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original Description');
      expect(updated.isCompleted, true);
      expect(updated.isPendingSync, false);
    });

    test('should convert to map correctly', () {
      final now = DateTime.now();
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
        userId: 'user-123',
      );

      final map = task.toMap();

      expect(map['id'], 'test-id');
      expect(map['title'], 'Test Task');
      expect(map['description'], 'Test Description');
      expect(map['isCompleted'], true);
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
      expect(map['syncedAt'], now.toIso8601String());
      expect(map['userId'], 'user-123');
    });

    test('should create from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'title': 'Test Task',
        'description': 'Test Description',
        'isCompleted': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncedAt': now.toIso8601String(),
        'userId': 'user-123',
      };

      final task = Task.fromMap(map);

      expect(task.id, 'test-id');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.isCompleted, true);
      expect(task.syncedAt, now);
      expect(task.userId, 'user-123');
      expect(task.isPendingSync, false); // Should be false when from Firebase
    });

    test('should handle missing optional fields in fromMap', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'title': 'Test Task',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final task = Task.fromMap(map);

      expect(task.description, '');
      expect(task.isCompleted, false);
      expect(task.syncedAt, isNull);
      expect(task.userId, isNull);
    });

    test('should return correct string representation', () {
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        isCompleted: true,
      );

      final str = task.toString();
      expect(str, contains('test-id'));
      expect(str, contains('Test Task'));
      expect(str, contains('true'));
    });
  });
}
