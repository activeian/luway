import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ownership_verification_service.dart';

class OwnershipVerificationManager {
  static Timer? _periodicTimer;
  static bool _isInitialized = false;

  /// Initialize the ownership verification background service
  static void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;

    // Start checking immediately
    _checkVerifications();

    // Set up periodic checks every hour
    _periodicTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkVerifications(),
    );

    print('OwnershipVerificationManager: Initialized with hourly checks');
  }

  /// Stop the background service
  static void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isInitialized = false;
    print('OwnershipVerificationManager: Disposed');
  }

  /// Manual check trigger
  static Future<void> checkNow() async {
    await _checkVerifications();
  }

  /// Internal check method
  static Future<void> _checkVerifications() async {
    try {
      await OwnershipVerificationService.checkPendingVerifications();
      print('OwnershipVerificationManager: Completed verification check');
    } catch (e) {
      print(
          'OwnershipVerificationManager: Error during verification check: $e');
    }
  }

  /// Check if the service is running
  static bool get isRunning => _isInitialized && _periodicTimer != null;
}

/// Widget that ensures ownership verification is active when the app is running
class OwnershipVerificationWrapper extends StatefulWidget {
  final Widget child;

  const OwnershipVerificationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<OwnershipVerificationWrapper> createState() =>
      _OwnershipVerificationWrapperState();
}

class _OwnershipVerificationWrapperState
    extends State<OwnershipVerificationWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    OwnershipVerificationManager.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OwnershipVerificationManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App became active - restart verification checks
        OwnershipVerificationManager.initialize();
        // Check immediately when app resumes
        OwnershipVerificationManager.checkNow();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App going to background - stop periodic checks to save battery
        OwnershipVerificationManager.dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
