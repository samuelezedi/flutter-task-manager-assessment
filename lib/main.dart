import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/hive_service.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('Note: Make sure to configure Firebase properly');
    debugPrint('App will continue with limited Firebase functionality');
  }

  // Initialize services
  final hiveService = HiveService();
  await hiveService.init();

  final firebaseService = FirebaseService();
  final connectivityService = ConnectivityService();
  await connectivityService.init();

  final syncService = SyncService(
    hiveService: hiveService,
    firebaseService: firebaseService,
    connectivityService: connectivityService,
  );

  runApp(
    MyApp(
      hiveService: hiveService,
      firebaseService: firebaseService,
      connectivityService: connectivityService,
      syncService: syncService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final HiveService hiveService;
  final FirebaseService firebaseService;
  final ConnectivityService connectivityService;
  final SyncService syncService;

  const MyApp({
    super.key,
    required this.hiveService,
    required this.firebaseService,
    required this.connectivityService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(
            hiveService: hiveService,
            firebaseService: firebaseService,
            syncService: syncService,
            connectivityService: connectivityService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: AuthWrapper(
          firebaseService: firebaseService,
          hiveService: hiveService,
          firebaseServiceForProvider: firebaseService,
          connectivityService: connectivityService,
          syncService: syncService,
        ),
      ),
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatelessWidget {
  final FirebaseService firebaseService;
  final HiveService hiveService;
  final FirebaseService firebaseServiceForProvider;
  final ConnectivityService connectivityService;
  final SyncService syncService;

  const AuthWrapper({
    super.key,
    required this.firebaseService,
    required this.hiveService,
    required this.firebaseServiceForProvider,
    required this.connectivityService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated, show home screen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // If user is not authenticated, show login screen
        return LoginScreen(firebaseService: firebaseService);
      },
    );
  }
}
