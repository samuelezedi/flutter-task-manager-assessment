import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

/// Service for managing Firebase Firestore operations
class FirebaseService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore get _firestoreInstance {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase is not initialized');
    }
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  FirebaseAuth get _authInstance {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase is not initialized');
    }
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  /// Check if Firebase is initialized
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current user ID
  String? get currentUserId {
    if (!isFirebaseInitialized) return null;
    try {
      return _authInstance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    if (!isFirebaseInitialized) return false;
    try {
      return _authInstance.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with email and password
  /// Returns null if successful, error message string if failed
  /// Provides user-friendly error messages
  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Verify Firebase is initialized
      if (!isFirebaseInitialized) {
        debugPrint('Firebase is not initialized. Cannot sign in.');
        return 'Firebase is not initialized. Please check your configuration.';
      }

      debugPrint('Attempting email/password sign-in...');

      // Attempt to sign in with email and password
      final userCredential = await _authInstance
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
        return null; // Success
      }
      return 'Sign in failed. Please try again.';
    } on TimeoutException catch (e) {
      debugPrint('Firebase auth timeout: ${e.message}');
      debugPrint(
        'This may indicate network issues or Firebase service unavailability.',
      );
      return 'Connection timeout. Please check your internet connection and try again.';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error [${e.code}]: ${e.message}');
      // Return user-friendly error message
      return _getAuthErrorMessage(e);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error signing in: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Create a new user account with email and password
  /// Returns null if successful, error message string if failed
  /// Provides user-friendly error messages
  Future<String?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Verify Firebase is initialized
      if (!isFirebaseInitialized) {
        debugPrint('Firebase is not initialized. Cannot create account.');
        return 'Firebase is not initialized. Please check your configuration.';
      }

      debugPrint('Attempting to create account...');

      // Attempt to create user with email and password
      final userCredential = await _authInstance
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
        return null; // Success
      }
      return 'Account creation failed. Please try again.';
    } on TimeoutException catch (e) {
      debugPrint('Firebase auth timeout: ${e.message}');
      debugPrint(
        'This may indicate network issues or Firebase service unavailability.',
      );
      return 'Connection timeout. Please check your internet connection and try again.';
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase auth error [${e.code}]: ${e.message}');
      // Return user-friendly error message
      return _getAuthErrorMessage(e);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error creating account: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get current user email
  String? get currentUserEmail => _authInstance.currentUser?.email;

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authInstance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Get user-friendly error message from FirebaseAuthException
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication failed: ${e.message ?? "Unknown error"}. Please try again.';
    }
  }

  /// Get tasks collection reference for current user
  CollectionReference _getTasksCollection() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestoreInstance
        .collection('users')
        .doc(userId)
        .collection('tasks');
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
  /// Throws exception with user-friendly message on error
  Future<void> saveTask(Task task) async {
    try {
      await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        await tasksRef.doc(task.id).set(task.toMap());
      });
    } on FirebaseException catch (e) {
      debugPrint('Error saving task to Firebase [${e.code}]: ${e.message}');
      throw Exception(_getFirestoreErrorMessage(e));
    } catch (e) {
      debugPrint('Error saving task to Firebase: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to save task. Please try again.');
    }
  }

  /// Delete a task from Firestore
  /// Throws exception with user-friendly message on error
  Future<void> deleteTask(String taskId) async {
    try {
      await _retryFirestoreOperation(() async {
        final tasksRef = _getTasksCollection();
        await tasksRef.doc(taskId).delete();
      });
    } on FirebaseException catch (e) {
      debugPrint('Error deleting task from Firebase [${e.code}]: ${e.message}');
      throw Exception(_getFirestoreErrorMessage(e));
    } catch (e) {
      debugPrint('Error deleting task from Firebase: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to delete task. Please try again.');
    }
  }

  /// Get user-friendly error message from FirebaseException
  String _getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Please check your account permissions.';
      case 'unavailable':
        return 'Service temporarily unavailable. Your changes are saved locally and will sync when connection is restored.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'resource-exhausted':
        return 'Service is busy. Please try again in a moment.';
      case 'unauthenticated':
        return 'Please sign in to sync your tasks.';
      case 'not-found':
        return 'Task not found. It may have been deleted.';
      default:
        return 'Sync failed: ${e.message ?? "Unknown error"}. Your changes are saved locally.';
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
