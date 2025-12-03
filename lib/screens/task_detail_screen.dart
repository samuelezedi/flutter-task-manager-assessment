import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

/// Screen for viewing and editing task details
class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController.text = _task.title;
    _descriptionController.text = _task.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final updatedTask = _task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await provider.updateTask(updatedTask);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _task = updatedTask;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error updating task';
        if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _titleController.text = _task.title;
      _descriptionController.text = _task.description;
    });
  }

  void _toggleComplete() {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    provider.toggleTaskCompletion(_task);
    setState(() {
      _task = _task.copyWith(isCompleted: !_task.isCompleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isSaving ? null : _cancelEdit,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Completion status
            Card(
              child: SwitchListTile(
                title: const Text('Completed'),
                value: _task.isCompleted,
                onChanged: _isEditing ? null : (value) => _toggleComplete(),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            TextFormField(
              controller: _titleController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            // Task metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Created',
                      DateFormat('MMM dd, yyyy HH:mm').format(_task.createdAt),
                    ),
                    _buildInfoRow(
                      'Last Updated',
                      DateFormat('MMM dd, yyyy HH:mm').format(_task.updatedAt),
                    ),
                    if (_task.syncedAt != null)
                      _buildInfoRow(
                        'Last Synced',
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(_task.syncedAt!),
                      ),
                    if (_task.isPendingSync)
                      Row(
                        children: [
                          Icon(Icons.sync, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Pending sync',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

