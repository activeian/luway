import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'services/scheduled_task_service.dart';
import 'services/online_status_service.dart';
import 'services/notification_service.dart';
import 'services/price_monitoring_service.dart';
import 'services/ownership_verification_manager.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Hive
    print('Initializing Hive...');
    await Hive.initFlutter();
    print('Hive initialized successfully');

    // Initialize scheduled tasks for marketplace maintenance
    print('Initializing scheduled tasks...');
    ScheduledTaskService.initialize();
    print('Scheduled tasks initialized successfully');

    // Initialize online status service
    print('Initializing online status service...');
    OnlineStatusService.initializeOnlineStatus();
    print('Online status service initialized successfully');

    // Initialize notification service
    print('Initializing notification service...');
    await NotificationService.initialize();
    print('Notification service initialized successfully');

    // Start price monitoring
    print('Starting price monitoring...');
    PriceMonitoringService.startPriceMonitoring();
    print('Price monitoring started successfully');
  } catch (e) {
    print('Error during initialization: $e');
  }

  runApp(const LuWayApp());
}

class LuWayApp extends StatefulWidget {
  const LuWayApp({super.key});

  @override
  State<LuWayApp> createState() => _LuWayAppState();
}

class _LuWayAppState extends State<LuWayApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OnlineStatusService.cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground and interactive
        OnlineStatusService.setUserOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or not interactive
        OnlineStatusService.setUserOffline();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        OnlineStatusService.setUserOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'LuWay',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          home: OwnershipVerificationWrapper(
            child: const SplashScreen(),
          ),
        );
      },
    );
  }
}
