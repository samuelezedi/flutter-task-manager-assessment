import 'package:flutter/material.dart';
import '../models/task.dart';

/// Widget for displaying a task in the list
class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            if (task.isPendingSync)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 12, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Pending sync',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          color: Colors.red,
        ),
        onTap: onTap,
      ),
    );
  }
}

