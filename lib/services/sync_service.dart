import 'package:flutter/foundation.dart';
import 'hive_service.dart';
import 'firebase_service.dart';
import 'connectivity_service.dart';

/// Service for syncing data between Hive (local) and Firebase (cloud)
/// Implements conflict resolution strategy
class SyncService {
  final HiveService _hiveService;
  final FirebaseService _firebaseService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;

  SyncService({
    required HiveService hiveService,
    required FirebaseService firebaseService,
    required ConnectivityService connectivityService,
  })  : _hiveService = hiveService,
        _firebaseService = firebaseService,
        _connectivityService = connectivityService;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Sync all pending tasks to Firebase
  /// Returns number of tasks synced
  Future<int> syncToFirebase() async {
    if (!_connectivityService.isOnline || !_firebaseService.isAuthenticated) {
      return 0;
    }

    if (_isSyncing) return 0;

    _isSyncing = true;
    int syncedCount = 0;

    try {
      final pendingTasks = _hiveService.getPendingSyncTasks();

      for (final task in pendingTasks) {
        try {
          // Check for conflicts
          final firebaseTask = await _firebaseService.getTask(task.id);

          if (firebaseTask != null) {
            // Conflict detected - resolve using "last write wins" strategy
            // In a production app, you might want more sophisticated conflict resolution
            if (firebaseTask.updatedAt.isAfter(task.updatedAt)) {
              // Firebase version is newer, keep it and update local
              await _hiveService.saveTask(firebaseTask);
              continue;
            }
            // Local version is newer or same, proceed with sync
          }

          // Save to Firebase
          await _firebaseService.saveTask(task);
          await _hiveService.markTaskAsSynced(task.id);
          syncedCount++;
        } catch (e) {
          debugPrint('Error syncing task ${task.id}: $e');
          // Continue with other tasks
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Sync from Firebase to local storage
  /// Downloads all tasks from Firebase and merges with local data
  Future<void> syncFromFirebase() async {
    if (!_connectivityService.isOnline || !_firebaseService.isAuthenticated) {
      return;
    }

    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final firebaseTasks = await _firebaseService.getAllTasks();
      final localTasks = _hiveService.getAllTasks();

      // Create a map of local tasks by ID
      final localTasksMap = {
        for (var task in localTasks) task.id: task
      };

      // Merge Firebase tasks with local tasks
      for (final firebaseTask in firebaseTasks) {
        final localTask = localTasksMap[firebaseTask.id];

        if (localTask == null) {
          // New task from Firebase, add to local
          await _hiveService.saveTask(firebaseTask);
        } else {
          // Task exists in both - resolve conflict
          if (localTask.isPendingSync) {
            // Local has pending changes, check timestamps
            if (firebaseTask.updatedAt.isAfter(localTask.updatedAt)) {
              // Firebase is newer, use Firebase version
              await _hiveService.saveTask(firebaseTask);
            }
            // Otherwise, keep local version (will be synced later)
          } else {
            // No local changes, use Firebase version
            await _hiveService.saveTask(firebaseTask);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing from Firebase: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform bidirectional sync
  Future<void> performFullSync() async {
    if (!_connectivityService.isOnline || !_firebaseService.isAuthenticated) {
      return;
    }

    // First sync local changes to Firebase
    await syncToFirebase();

    // Then sync Firebase changes to local
    await syncFromFirebase();
  }

  /// Delete task from both local and Firebase
  Future<void> deleteTask(String taskId) async {
    // Delete from local first (optimistic update)
    await _hiveService.deleteTask(taskId);

    // Delete from Firebase if online
    if (_connectivityService.isOnline && _firebaseService.isAuthenticated) {
      try {
        await _firebaseService.deleteTask(taskId);
      } catch (e) {
        debugPrint('Error deleting task from Firebase: $e');
        // Task is already deleted locally, mark for sync if needed
      }
    }
  }
}

