import 'package:hive/hive.dart';

part 'task.g.dart';

/// Task model with Hive type adapter
/// Represents a task with title, description, completion status, and timestamps
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  DateTime? syncedAt; // Last sync time with Firebase

  @HiveField(7)
  bool isPendingSync; // True if changes need to be synced

  @HiveField(8)
  String? userId; // Firebase user ID

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncedAt,
    this.isPendingSync = false,
    this.userId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy of the task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    bool? isPendingSync,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      userId: userId ?? this.userId,
    );
  }

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  /// Create from Map (from Firebase)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      syncedAt: map['syncedAt'] != null
          ? DateTime.parse(map['syncedAt'] as String)
          : null,
      userId: map['userId'] as String?,
      isPendingSync: false, // Already synced if coming from Firebase
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted)';
  }
}

