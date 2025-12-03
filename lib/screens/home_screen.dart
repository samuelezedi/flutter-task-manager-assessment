import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';
import '../widgets/task_list_item.dart';
import '../widgets/sync_indicator.dart';

/// Home screen displaying list of tasks
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0 = All, 1 = Active, 2 = Completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          // Sync indicator and button
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              return SyncIndicator(
                isOnline: provider.isOnline,
                isSyncing: provider.isSyncing,
                pendingSyncCount: provider.pendingSyncCount,
                onSyncTap: () => provider.performSync(),
              );
            },
          ),
          // Sign out button
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'signout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  // Auth state listener in main.dart will handle navigation
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'signout',
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Task> displayTasks;
          switch (_selectedIndex) {
            case 1:
              displayTasks = provider.getTasksByStatus(false);
              break;
            case 2:
              displayTasks = provider.getTasksByStatus(true);
              break;
            default:
              displayTasks = provider.tasks;
          }

          return Column(
            children: [
              // Filter tabs - always visible
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterTab('All', 0),
                    _buildFilterTab('Active', 1),
                    _buildFilterTab('Completed', 2),
                  ],
                ),
              ),
              // Task list or empty state
              Expanded(
                child: displayTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedIndex == 1
                                  ? 'No active tasks'
                                  : _selectedIndex == 2
                                      ? 'No completed tasks'
                                      : 'No tasks yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add a task',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayTasks.length,
                        itemBuilder: (context, index) {
                          final task = displayTasks[index];
                          return TaskListItem(
                            task: task,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              );
                            },
                            onToggleComplete: () {
                              provider.toggleTaskCompletion(task);
                            },
                            onDelete: () {
                              _showDeleteConfirmation(context, provider, task);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TaskProvider provider,
    Task task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

