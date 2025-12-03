import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing task state and business logic
class TaskProvider with ChangeNotifier {
  final HiveService _hiveService;
  final FirebaseService _firebaseService;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isOnline = false;

  TaskProvider({
    required HiveService hiveService,
    required FirebaseService firebaseService,
    required SyncService syncService,
    required ConnectivityService connectivityService,
  })  : _hiveService = hiveService,
        _firebaseService = firebaseService,
        _syncService = syncService,
        _connectivityService = connectivityService {
    _init();
  }

  /// Initialize provider
  Future<void> _init() async {
    // Listen to connectivity changes
    _connectivityService.connectionStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();

      // Auto-sync when coming back online
      if (isOnline) {
        performSync();
      }
    });

    // Listen to Firebase real-time updates
    if (_firebaseService.isAuthenticated) {
      _firebaseService.streamTasks().listen((firebaseTasks) {
        // Merge with local tasks (async operation, intentionally unawaited)
        unawaited(_mergeTasks(firebaseTasks));
      });
    }

    // Load initial tasks
    await loadTasks();
  }

  /// Get all tasks
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// Get tasks filtered by completion status
  List<Task> getTasksByStatus(bool completed) {
    return _tasks.where((task) => task.isCompleted == completed).toList();
  }

  /// Get pending sync count
  int get pendingSyncCount => _tasks.where((t) => t.isPendingSync).length;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Check if syncing
  bool get isSyncing => _isSyncing;

  /// Check if online
  bool get isOnline => _isOnline;

  /// Load tasks from local storage
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = _hiveService.getAllTasks();
      _isOnline = _connectivityService.isOnline;
      
      // If online, sync with Firebase
      if (_isOnline && _firebaseService.isAuthenticated) {
        await _syncService.syncFromFirebase();
        _tasks = _hiveService.getAllTasks();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      // Error is logged but app continues with local data
      // In a production app, you might want to show an error to the user
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new task
  Future<void> addTask(String title, String description) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      isPendingSync: true,
      userId: _firebaseService.currentUserId,
    );

    // Optimistic update - save locally immediately
    await _hiveService.saveTask(task);
    _tasks = _hiveService.getAllTasks();
    notifyListeners();

    // Sync to Firebase if online
    if (_isOnline && _firebaseService.isAuthenticated) {
      try {
        await _syncService.syncToFirebase();
        await loadTasks(); // Reload to get updated sync status
      } catch (e) {
        debugPrint('Error syncing new task: $e');
        // Task is already saved locally, will sync later
        // User can continue working offline
      }
    }
  }

  /// Update a task
  Future<void> updateTask(Task task) async {
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );

    // Optimistic update
    await _hiveService.saveTask(updatedTask);
    _tasks = _hiveService.getAllTasks();
    notifyListeners();

    // Sync to Firebase if online
    if (_isOnline && _firebaseService.isAuthenticated) {
      try {
        await _syncService.syncToFirebase();
        await loadTasks();
      } catch (e) {
        debugPrint('Error syncing updated task: $e');
        // Task is already updated locally, will sync later
        // User can continue working offline
      }
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );

    await updateTask(updatedTask);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    // Optimistic update - remove from local list immediately
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    notifyListeners();

    // Delete from storage and Firebase
    await _syncService.deleteTask(taskId);
    _tasks = _hiveService.getAllTasks();
    notifyListeners();
  }

  /// Perform manual sync
  Future<void> performSync() async {
    if (!_isOnline || !_firebaseService.isAuthenticated) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncService.performFullSync();
      _tasks = _hiveService.getAllTasks();
    } catch (e) {
      debugPrint('Error performing sync: $e');
      // Sync failed but local data is intact
      // User can try again later or continue working offline
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Merge Firebase tasks with local tasks
  Future<void> _mergeTasks(List<Task> firebaseTasks) async {
    final localTasksMap = {
      for (var task in _tasks) task.id: task
    };

    // Create a map of Firebase tasks by ID for quick lookup
    final firebaseTasksMap = {
      for (var task in firebaseTasks) task.id: task
    };

    // Process Firebase tasks (add/update)
    for (final firebaseTask in firebaseTasks) {
      final localTask = localTasksMap[firebaseTask.id];
      if (localTask == null || !localTask.isPendingSync) {
        // No local changes, use Firebase version
        await _hiveService.saveTask(firebaseTask);
      }
    }

    // Handle deletions: remove local tasks that don't exist in Firebase
    // But only if they don't have pending sync (which means they're new local tasks)
    for (final localTask in _tasks) {
      if (!firebaseTasksMap.containsKey(localTask.id)) {
        // Task exists locally but not in Firebase
        // Only delete if it's already synced (not a new local task)
        if (!localTask.isPendingSync) {
          // Task was deleted on another device, remove it locally
          await _hiveService.deleteTask(localTask.id);
        }
      }
    }

    _tasks = _hiveService.getAllTasks();
    notifyListeners();
  }
}

