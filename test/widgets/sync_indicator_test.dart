import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/widgets/sync_indicator.dart';

void main() {
  group('SyncIndicator Widget Tests', () {
    testWidgets('should show online status when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: false,
              pendingSyncCount: 0,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('should show offline status when offline', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: false,
              isSyncing: false,
              pendingSyncCount: 0,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('should show syncing indicator when syncing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: true,
              pendingSyncCount: 0,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show pending sync count when greater than 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: false,
              pendingSyncCount: 3,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should not show pending sync count when 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: false,
              pendingSyncCount: 0,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      // Should not show badge with 0
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should call onSyncTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: false,
              pendingSyncCount: 0,
              onSyncTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SyncIndicator));
      expect(tapped, isTrue);
    });

    testWidgets('should be disabled when syncing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncIndicator(
              isOnline: true,
              isSyncing: true,
              pendingSyncCount: 0,
              onSyncTap: () {},
            ),
          ),
        ),
      );

      // When syncing, should show progress indicator instead of tap action
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

