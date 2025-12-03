import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility class for handling and displaying errors in a user-friendly way
class ErrorHandler {
  /// Get user-friendly error message from Firebase Auth exceptions
  static String getAuthErrorMessage(FirebaseAuthException e) {
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
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Get user-friendly error message from Firestore exceptions
  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'resource-exhausted':
        return 'Service is busy. Please try again in a moment.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'not-found':
        return 'The requested item was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'failed-precondition':
        return 'Operation cannot be completed. Please try again.';
      case 'aborted':
        return 'Operation was cancelled. Please try again.';
      case 'out-of-range':
        return 'Invalid data provided. Please check your input.';
      case 'unimplemented':
        return 'This feature is not available yet.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'data-loss':
        return 'Data error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Get user-friendly error message from generic exceptions
  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Show error snackbar to user
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar to user
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error dialog to user
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

