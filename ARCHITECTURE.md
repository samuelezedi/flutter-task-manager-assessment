# Architecture Documentation

## Overview

The Task Management App follows a clean architecture pattern with clear separation of concerns. The app implements an offline-first architecture using Hive for local storage and Firebase Firestore for cloud synchronization.

## Architecture Layers

### 1. Data Layer

#### Models (`lib/models/`)
- **Task**: Core data model representing a task
  - Uses Hive annotations for local persistence
  - Includes sync metadata (isPendingSync, syncedAt)
  - Serializable to/from Firebase Firestore

#### Services (`lib/services/`)

**HiveService**
- Manages local database operations
- Provides CRUD operations for tasks
- Tracks pending sync status
- Responsibilities:
  - Initialize Hive boxes
  - Save/retrieve/delete tasks
  - Query pending sync tasks

**FirebaseService**
- Handles all Firebase operations
- Manages authentication
- Provides real-time data streams
- Responsibilities:
  - User authentication
  - Firestore CRUD operations
  - Real-time listeners

**ConnectivityService**
- Monitors network connectivity
- Provides connectivity status stream
- Responsibilities:
  - Detect online/offline status
  - Emit connectivity changes

**SyncService**
- Orchestrates data synchronization
- Implements conflict resolution
- Responsibilities:
  - Sync local changes to Firebase
  - Sync Firebase changes to local
  - Resolve conflicts between local and remote data

### 2. Business Logic Layer

#### Providers (`lib/providers/`)

**TaskProvider**
- Manages application state
- Implements business logic
- Coordinates between services
- Responsibilities:
  - Task CRUD operations
  - Optimistic UI updates
  - Auto-sync on connectivity restore
  - Real-time data merging

### 3. Presentation Layer

#### Screens (`lib/screens/`)

**HomeScreen**
- Displays list of tasks
- Filter functionality (All/Active/Completed)
- Floating action button for adding tasks

**AddTaskScreen**
- Form for creating new tasks
- Input validation

**TaskDetailScreen**
- View task details
- Edit task information
- Toggle completion status

#### Widgets (`lib/widgets/`)

**TaskListItem**
- Reusable task card widget
- Shows task status and sync indicator

**SyncIndicator**
- Displays connectivity status
- Shows pending sync count
- Manual sync button

## Data Flow

### Creating a Task

1. User fills form in `AddTaskScreen`
2. `TaskProvider.addTask()` is called
3. Task is saved to Hive immediately (optimistic update)
4. UI updates instantly
5. If online, `SyncService` syncs to Firebase in background
6. Task is marked as synced

### Editing a Task

1. User edits task in `TaskDetailScreen`
2. `TaskProvider.updateTask()` is called
3. Task updated in Hive with `isPendingSync = true`
4. UI updates immediately
5. Background sync to Firebase
6. Sync status updated

### Offline to Online Transition

1. `ConnectivityService` detects network restoration
2. `TaskProvider` automatically calls `performSync()`
3. `SyncService` syncs pending local changes to Firebase
4. `SyncService` downloads remote changes from Firebase
5. Conflicts are resolved using timestamp comparison
6. UI updates with merged data

### Conflict Resolution Strategy

**Last Write Wins (Timestamp-based)**
- Compare `updatedAt` timestamps
- If Firebase version is newer → Use Firebase version
- If local version is newer → Keep local, sync to Firebase
- If local has pending changes → Preserve local changes

**Implementation:**
```dart
if (firebaseTask.updatedAt.isAfter(localTask.updatedAt)) {
  // Firebase is newer, use it
  await hiveService.saveTask(firebaseTask);
} else {
  // Local is newer, keep it and sync
  await syncService.syncToFirebase();
}
```

## State Management

### Provider Pattern
- Uses `provider` package for state management
- `TaskProvider` extends `ChangeNotifier`
- UI widgets consume state via `Consumer<TaskProvider>`
- Automatic UI updates on state changes

### State Properties
- `tasks`: List of all tasks
- `isLoading`: Loading state indicator
- `isSyncing`: Sync operation in progress
- `isOnline`: Network connectivity status

## Offline-First Strategy

### Principles
1. **Always Available**: App works without internet
2. **Optimistic Updates**: UI updates immediately
3. **Background Sync**: Sync happens asynchronously
4. **Conflict Resolution**: Handles data conflicts gracefully

### Implementation
- All operations write to Hive first
- Tasks marked with `isPendingSync` flag
- Sync service processes pending tasks when online
- Visual indicators show sync status

## Error Handling

### Network Errors
- Gracefully handle Firebase connection failures
- Retry logic for failed syncs
- User-friendly error messages

### Data Errors
- Validate user input
- Handle corrupted local data
- Fallback to local data if Firebase fails

## Performance Optimizations

1. **Lazy Loading**: Tasks loaded on demand
2. **Efficient Queries**: Hive queries are fast
3. **Stream Management**: Proper disposal of streams
4. **Memory Management**: Close Hive boxes when done

## Security Considerations

1. **Firebase Rules**: User-specific data access
2. **Authentication**: Email/password authentication for user-based data segregation
3. **Data Validation**: Input sanitization
4. **Error Messages**: Don't expose sensitive information

## Testing Strategy

### Unit Tests
- Test individual services
- Test provider logic
- Test conflict resolution

### Widget Tests
- Test UI components
- Test user interactions
- Test state updates

### Integration Tests
- Test full sync flow
- Test offline/online transitions
- Test conflict scenarios

## Challenges and Solutions

### Challenge 1: Conflict Resolution
**Problem**: Multiple devices editing same task
**Solution**: Timestamp-based last-write-wins with pending sync tracking

### Challenge 2: Real-time Updates
**Problem**: Merging Firebase streams with local data
**Solution**: Intelligent merging logic that preserves local changes

### Challenge 3: Optimistic UI
**Problem**: Showing immediate feedback while syncing
**Solution**: Update local storage first, sync in background

### Challenge 4: Connectivity Monitoring
**Problem**: Detecting network state changes
**Solution**: ConnectivityService with stream-based updates

## Future Improvements

1. **Better Conflict Resolution**: 
   - Operational transformation
   - User choice in conflicts
   - Conflict resolution UI

2. **Performance**:
   - Pagination for large task lists
   - Image attachments
   - Search functionality

3. **Features**:
   - Task categories
   - Due dates
   - Reminders
   - Collaboration

4. **Testing**:
   - More comprehensive test coverage
   - E2E tests
   - Performance tests

