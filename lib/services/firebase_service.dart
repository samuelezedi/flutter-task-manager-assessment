import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

/// Service for managing Firebase Firestore operations
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if Firebase is initialized
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Sign in with email and password
  /// Returns true if successful, false otherwise
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Verify Firebase is initialized
      if (!isFirebaseInitialized) {
        debugPrint('Firebase is not initialized. Cannot sign in.');
        return false;
      }

      debugPrint('Attempting email/password sign-in...');

      // Attempt to sign in with email and password
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Firebase auth timeout',
                const Duration(seconds: 10),
              );
            },
          );

      if (userCredential.user != null) {
        debugPrint('Successfully signed in: ${userCredential.user!.email}');
        return true;
      }
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Firebase auth timeout: ${e.message}');
      debugPrint(
        'This may indicate network issues or Firebase service unavailability.',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error signing in: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Create a new user account with email and password
  /// Returns true if successful, false otherwise
  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Verify Firebase is initialized
      if (!isFirebaseInitialized) {
        debugPrint('Firebase is not initialized. Cannot create account.');
        return false;
      }

      debugPrint('Attempting to create account...');

      // Attempt to create user with email and password
      final userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Firebase auth timeout',
                const Duration(seconds: 10),
              );
            },
          );

      if (userCredential.user != null) {
        debugPrint(
          'Successfully created account: ${userCredential.user!.email}',
        );
        return true;
      }
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Firebase auth timeout: ${e.message}');
      debugPrint(
        'This may indicate network issues or Firebase service unavailability.',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error [${e.code}]: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error creating account: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get tasks collection reference for current user
  CollectionReference _getTasksCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  /// Retry a Firestore operation with exponential backoff
  /// Handles transient errors like 'unavailable'
  Future<T> _retryFirestoreOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        // Check if it's a retryable error
        final isRetryable =
            e.code == 'unavailable' ||
            e.code == 'deadline-exceeded' ||
            e.code == 'resource-exhausted' ||
            e.code == 'internal';

        if (!isRetryable || attempt == maxRetries - 1) {
          // Not retryable or last attempt, rethrow
          rethrow;
        }

        attempt++;
        if (kDebugMode) {
          debugPrint(
            'Firestore operation failed (attempt $attempt/$maxRetries): ${e.code}',
          );
          debugPrint('Retrying in ${delay.inSeconds} seconds...');
        }

        await Future.delayed(delay);
        // Exponential backoff: double the delay for next retry
        delay = Duration(seconds: delay.inSeconds * 2);
      } catch (e) {
        // Non-Firebase exceptions, don't retry
        rethrow;
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Create or update a task in Firestore
  Future<void> saveTask(Task task) async {
    try {
      await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        await tasksRef.doc(task.id).set(task.toMap());
      });
    } on FirebaseException catch (e) {
      debugPrint('Error saving task to Firebase [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error saving task to Firebase: $e');
      rethrow;
    }
  }

  /// Delete a task from Firestore
  Future<void> deleteTask(String taskId) async {
    try {
      await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        await tasksRef.doc(taskId).delete();
      });
    } on FirebaseException catch (e) {
      debugPrint('Error deleting task from Firebase [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error deleting task from Firebase: $e');
      rethrow;
    }
  }

  /// Get all tasks from Firestore
  Future<List<Task>> getAllTasks() async {
    try {
      return await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        final snapshot = await tasksRef.get();
        return snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } on FirebaseException catch (e) {
      debugPrint('Error getting tasks from Firebase [${e.code}]: ${e.message}');
      // Return empty list on error - app will continue with local data
      return [];
    } catch (e) {
      debugPrint('Error getting tasks from Firebase: $e');
      return [];
    }
  }

  /// Stream tasks from Firestore (real-time updates)
  Stream<List<Task>> streamTasks() {
    try {
      final tasksRef = _getTasksCollection();
      return tasksRef.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error streaming tasks from Firebase: $e');
      return Stream.value([]);
    }
  }

  /// Get a single task by ID
  Future<Task?> getTask(String taskId) async {
    try {
      return await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        final doc = await tasksRef.doc(taskId).get();
        if (doc.exists) {
          return Task.fromMap(doc.data()! as Map<String, dynamic>);
        }
        return null;
      });
    } on FirebaseException catch (e) {
      // Log but don't print for unavailable errors (they're transient)
      if (e.code != 'unavailable') {
        debugPrint(
          'Error getting task from Firebase [${e.code}]: ${e.message}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting task from Firebase: $e');
      return null;
    }
  }
}
