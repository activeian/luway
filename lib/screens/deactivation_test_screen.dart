import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/item_deactivation_service.dart';
import '../services/scheduled_task_service.dart';

const Color oliveColor = Color(0xFF808000);

class DeactivationTestScreen extends StatefulWidget {
  const DeactivationTestScreen({super.key});

  @override
  State<DeactivationTestScreen> createState() => _DeactivationTestScreenState();
}

class _DeactivationTestScreenState extends State<DeactivationTestScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  int _deactivatedItemsCount = 0;
  int _expiringSoonCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading counts...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final deactivatedItems = await ItemDeactivationService.getUserItemsInGracePeriod(user.uid);
        final expiringSoon = await ItemDeactivationService.getItemsExpiringSoonCount(user.uid);
        
        setState(() {
          _deactivatedItemsCount = deactivatedItems.length;
          _expiringSoonCount = expiringSoon;
          _statusMessage = 'Counts loaded successfully';
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'User not authenticated';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading counts: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Deactivation System Test',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deactivation System Status',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Scheduled Tasks: ${ScheduledTaskService.isRunning ? "Running" : "Stopped"}',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  Text(
                    'Deactivated Items: $_deactivatedItemsCount',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  Text(
                    'Expiring Soon: $_expiringSoonCount',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _loadCounts,
              child: const Text('Refresh Counts'),
            ),
            SizedBox(height: 16.h),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testExpireGracePeriod,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Expire Grace Period'),
            ),
            SizedBox(height: 16.h),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testAutoDeactivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Auto-Deactivate Old Items'),
            ),
            SizedBox(height: 16.h),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runFullMaintenance,
              style: ElevatedButton.styleFrom(
                backgroundColor: oliveColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Run Full Maintenance'),
            ),
            SizedBox(height: 24.h),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error') 
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  border: Border.all(
                    color: _statusMessage.contains('Error') 
                        ? Colors.red
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') 
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testExpireGracePeriod() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing grace period expiration...';
    });

    try {
      await ItemDeactivationService.expireGracePeriodItems();
      setState(() {
        _statusMessage = 'Grace period expiration test completed successfully';
        _isLoading = false;
      });
      
      // Refresh counts
      await _loadCounts();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in grace period test: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAutoDeactivate() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing auto-deactivation of old items...';
    });

    try {
      await ItemDeactivationService.autoDeactivateExpiredItems();
      setState(() {
        _statusMessage = 'Auto-deactivation test completed successfully';
        _isLoading = false;
      });
      
      // Refresh counts
      await _loadCounts();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in auto-deactivation test: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runFullMaintenance() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running full maintenance...';
    });

    try {
      await ScheduledTaskService.triggerMaintenanceNow();
      setState(() {
        _statusMessage = 'Full maintenance completed successfully';
        _isLoading = false;
      });
      
      // Refresh counts
      await _loadCounts();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error in full maintenance: $e';
        _isLoading = false;
      });
    }
  }
}
