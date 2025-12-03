import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/widgets/task_list_item.dart';

void main() {
  group('TaskListItem Widget Tests', () {
    testWidgets('should display task title', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets('should display task description when present', (WidgetTester tester) async {
      final task = Task(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('should not display description when empty', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task', description: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Description should not be visible
      expect(find.text(''), findsNothing);
    });

    testWidgets('should show completed task with strikethrough', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Completed Task', isCompleted: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Completed Task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('should show pending sync indicator when task is pending sync', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task', isPendingSync: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pending sync'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('should not show pending sync indicator when task is synced', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task', isPendingSync: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pending sync'), findsNothing);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      final task = Task(id: 'test-1', title: 'Test Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () => tapped = true,
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Task'));
      expect(tapped, isTrue);
    });

    testWidgets('should call onToggleComplete when checkbox is tapped', (WidgetTester tester) async {
      bool toggled = false;
      final task = Task(id: 'test-1', title: 'Test Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () => toggled = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      expect(toggled, isTrue);
    });

    testWidgets('should call onDelete when delete button is tapped', (WidgetTester tester) async {
      bool deleted = false;
      final task = Task(id: 'test-1', title: 'Test Task');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleted, isTrue);
    });

    testWidgets('should show checkbox as checked for completed task', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task', isCompleted: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('should show checkbox as unchecked for incomplete task', (WidgetTester tester) async {
      final task = Task(id: 'test-1', title: 'Test Task', isCompleted: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskListItem(
              task: task,
              onTap: () {},
              onToggleComplete: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });
  });
}
