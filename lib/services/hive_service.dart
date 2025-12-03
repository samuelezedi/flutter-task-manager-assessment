import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

/// Service for managing local Hive database operations
class HiveService {
  static const String _tasksBoxName = 'tasks';
  Box<Task>? _tasksBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    // Only initialize if not already initialized (for testing)
    try {
      if (Hive.isBoxOpen(_tasksBoxName)) {
        _tasksBox = Hive.box<Task>(_tasksBoxName);
        return;
      }
    } catch (e) {
      // Box not open, continue with initialization
    }
    
    // Initialize Hive if not already done (for testing scenarios)
    // Try to initialize Flutter Hive, but catch errors for test environments
    try {
      await Hive.initFlutter();
    } catch (e) {
      // Hive might already be initialized (e.g., in tests with Hive.init())
      // or path_provider might not be available (e.g., in unit tests)
      // Check if we can proceed without initFlutter by trying to open a box
      try {
        // If Hive was initialized with Hive.init(), we can proceed
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(TaskAdapter());
        }
        _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
        return;
      } catch (e2) {
        // If we can't open a box either, rethrow the original error
        rethrow;
      }
    }
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }

    // Open tasks box
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
  }

  /// Get all tasks from local storage
  List<Task> getAllTasks() {
    if (_tasksBox == null) return [];
    return _tasksBox!.values.toList();
  }

  /// Get a task by ID
  Task? getTask(String id) {
    if (_tasksBox == null) return null;
    return _tasksBox!.get(id);
  }

  /// Save a task to local storage
  Future<void> saveTask(Task task) async {
    if (_tasksBox == null) return;
    await _tasksBox!.put(task.id, task);
  }

  /// Save multiple tasks
  Future<void> saveTasks(List<Task> tasks) async {
    if (_tasksBox == null) return;
    final Map<String, Task> tasksMap = {
      for (var task in tasks) task.id: task
    };
    await _tasksBox!.putAll(tasksMap);
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    if (_tasksBox == null) return;
    await _tasksBox!.delete(id);
  }

  /// Delete all tasks
  Future<void> deleteAllTasks() async {
    if (_tasksBox == null) return;
    await _tasksBox!.clear();
  }

  /// Get tasks that need to be synced
  List<Task> getPendingSyncTasks() {
    if (_tasksBox == null) return [];
    return _tasksBox!.values
        .where((task) => task.isPendingSync)
        .toList();
  }

  /// Mark task as synced
  Future<void> markTaskAsSynced(String id) async {
    if (_tasksBox == null) return;
    final task = _tasksBox!.get(id);
    if (task != null) {
      task.isPendingSync = false;
      task.syncedAt = DateTime.now();
      await task.save();
    }
  }

  /// Close boxes (cleanup)
  Future<void> close() async {
    await _tasksBox?.close();
  }
}

