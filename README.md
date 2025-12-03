# Task Management App

A Flutter application with offline-first architecture using Hive for local storage and Firebase Firestore for cloud synchronization.

## Features

- ✅ **Offline-First**: Works completely offline using Hive local database
- ✅ **Real-time Sync**: Automatic synchronization with Firebase Firestore when online
- ✅ **Optimistic UI**: Immediate UI updates while syncing in background
- ✅ **Conflict Resolution**: Handles conflicts when multiple devices edit the same task
- ✅ **Connectivity Monitoring**: Shows online/offline status and pending sync count
- ✅ **Task Management**: Create, update, delete, and toggle completion status
- ✅ **Filter Tasks**: View all, active, or completed tasks

## Architecture

### Services Layer
- **HiveService**: Manages local data persistence using Hive
- **FirebaseService**: Handles Firebase Firestore operations
- **ConnectivityService**: Monitors network connectivity status
- **SyncService**: Orchestrates bidirectional sync with conflict resolution

### State Management
- **TaskProvider**: Manages task state using Provider pattern
- Implements optimistic updates for better UX

### Data Model
- **Task**: Model with Hive type adapter for local storage
- Includes sync status tracking (isPendingSync, syncedAt)

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Firebase project (for cloud sync)
- Android Studio / Xcode (for mobile development)

### 1. Install Dependencies

```bash
cd task_manager_app
flutter pub get
```

### 2. Generate Hive Adapters

The Task model uses Hive code generation. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate `lib/models/task.g.dart` file.

### 3. Firebase Setup

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

This will create `lib/firebase_options.dart` automatically.

3. Enable Email/Password Authentication:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to **Authentication → Sign-in method**
   - Enable **Email/Password** sign-in provider
   - Save changes

#### Option B: Manual Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Add your app:
   - For Android: Add Android app in Firebase console
   - For iOS: Add iOS app in Firebase console

3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

4. Create `lib/firebase_options.dart`:
```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.tushop.taskManagerApp',
  );
}
```

5. Update `lib/main.dart` to use firebase_options:
```dart
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. Firebase Firestore Rules

Set up Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── task.dart            # Task model with Hive adapter
│   └── task.g.dart          # Generated Hive adapter
├── services/
│   ├── hive_service.dart     # Local storage service
│   ├── firebase_service.dart # Firebase operations
│   ├── connectivity_service.dart # Network monitoring
│   └── sync_service.dart    # Sync orchestration
├── providers/
│   └── task_provider.dart   # State management
├── screens/
│   ├── home_screen.dart     # Task list screen
│   ├── add_task_screen.dart # Add new task
│   └── task_detail_screen.dart # View/edit task
└── widgets/
    ├── task_list_item.dart  # Task list item widget
    └── sync_indicator.dart  # Sync status indicator
```

## Key Implementation Details

### Offline-First Design
- All operations work offline using Hive
- Tasks are marked with `isPendingSync` flag when modified offline
- Automatic sync when connectivity is restored

### Conflict Resolution
- Uses "last write wins" strategy based on `updatedAt` timestamp
- If Firebase version is newer, it replaces local version
- If local version is newer, it syncs to Firebase

### Optimistic UI Updates
- UI updates immediately when tasks are created/updated/deleted
- Background sync happens asynchronously
- Visual indicators show sync status

### Real-time Updates
- Listens to Firebase Firestore streams for real-time changes
- Merges remote changes with local data intelligently

## Testing

### Manual Testing Checklist

1. **Offline Functionality**
   - [ ] Turn off network, create a task → Should save locally
   - [ ] Turn off network, edit a task → Should update locally
   - [ ] Turn off network, delete a task → Should delete locally
   - [ ] Check pending sync indicator shows correct count

2. **Online Sync**
   - [ ] Create task offline, turn on network → Should sync automatically
   - [ ] Edit task offline, turn on network → Should sync changes
   - [ ] Manual sync button → Should sync pending changes

3. **Conflict Resolution**
   - [ ] Edit same task on two devices → Should resolve conflicts correctly
   - [ ] Check that newer changes win

4. **UI Features**
   - [ ] Filter tasks (All/Active/Completed)
   - [ ] Toggle task completion
   - [ ] View task details
   - [ ] Edit task details

### Automated Tests

Run tests:
```bash
flutter test
```

## Troubleshooting

### Hive Adapter Not Generated
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`
- Ensure `task.g.dart` exists in `lib/models/`

### Firebase Not Initialized
- Check `firebase_options.dart` exists
- Verify Firebase configuration files are in place
- Check Firebase project settings
- Ensure Email/Password authentication is enabled in Firebase Console (Authentication → Sign-in method)

### Sync Not Working
- Verify internet connection
- Check Firebase authentication status
- Review Firestore security rules
- Check console logs for errors

## Bonus Features Implemented

- ✅ Optimistic UI updates
- ✅ Firebase Authentication (email/password sign-in)
- ✅ Real-time sync indicators
- ✅ Conflict resolution UI feedback
- ✅ Comprehensive error handling

## License

This project is created for assessment purposes.
