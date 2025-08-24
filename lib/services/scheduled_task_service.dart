import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_deactivation_service.dart';

class ScheduledTaskService {
  static Timer? _maintenanceTimer;
  static Timer? _notificationTimer;
  static bool _isInitialized = false;

  /// Initialize scheduled tasks when app starts
  static void initialize() {
    if (_isInitialized) return;
    
    print('🕐 Initializing scheduled task service...');
    
    // Run maintenance check every 6 hours
    _maintenanceTimer = Timer.periodic(
      const Duration(hours: 6),
      (timer) => _performMaintenance(),
    );
    
    // Check for expiring items every hour for notifications
    _notificationTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _checkExpiringItems(),
    );
    
    // Run initial maintenance check after 30 seconds
    Timer(const Duration(seconds: 30), _performMaintenance);
    
    _isInitialized = true;
    print('✅ Scheduled task service initialized');
  }

  /// Stop all scheduled tasks
  static void dispose() {
    _maintenanceTimer?.cancel();
    _notificationTimer?.cancel();
    _maintenanceTimer = null;
    _notificationTimer = null;
    _isInitialized = false;
    print('🛑 Scheduled task service disposed');
  }

  /// Perform marketplace maintenance
  static Future<void> _performMaintenance() async {
    try {
      print('🔧 Running scheduled marketplace maintenance...');
      await ItemDeactivationService.performScheduledMaintenance();
      print('✅ Scheduled maintenance completed successfully');
    } catch (e) {
      print('❌ Error in scheduled maintenance: $e');
    }
  }

  /// Check for items expiring soon and send notifications
  static Future<void> _checkExpiringItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final expiringCount = await ItemDeactivationService.getItemsExpiringSoonCount(user.uid);
      
      if (expiringCount > 0) {
        print('⚠️ User has $expiringCount items expiring soon');
        // TODO: Send push notification or in-app notification
        // This could be implemented with Firebase Cloud Messaging
      }
    } catch (e) {
      print('❌ Error checking expiring items: $e');
    }
  }

  /// Manual trigger for maintenance (useful for testing or force refresh)
  static Future<void> triggerMaintenanceNow() async {
    print('🔧 Manually triggering maintenance...');
    await _performMaintenance();
  }

  /// Check if service is running
  static bool get isRunning => _isInitialized && _maintenanceTimer != null;

  /// Get next maintenance time
  static Duration? get timeUntilNextMaintenance {
    if (!_isInitialized || _maintenanceTimer == null) return null;
    // This is an approximation since Timer doesn't expose remaining time
    return const Duration(hours: 6);
  }
}
