import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification Testing'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Status',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _status,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    if (_isLoading) ...[
                      SizedBox(height: 12.h),
                      LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Test Buttons
            _buildTestButton(
              icon: Icons.message,
              title: 'Test Message Notification',
              subtitle: 'Send test message to yourself',
              color: Colors.blue,
              onPressed: _testMessageNotification,
            ),

            SizedBox(height: 12.h),

            _buildTestButton(
              icon: Icons.favorite,
              title: 'Test Favorite Notification',
              subtitle: 'Simulate favorite added to item',
              color: Colors.red,
              onPressed: _testFavoriteNotification,
            ),

            SizedBox(height: 12.h),

            _buildTestButton(
              icon: Icons.trending_down,
              title: 'Test Price Update',
              subtitle: 'Simulate price change notification',
              color: Colors.orange,
              onPressed: _testPriceUpdateNotification,
            ),

            SizedBox(height: 12.h),

            _buildTestButton(
              icon: Icons.analytics,
              title: 'Test Daily Summary',
              subtitle: 'Send daily summary notification',
              color: const Color(0xFF808000),
              onPressed: _testDailySummaryNotification,
            ),

            SizedBox(height: 20.h),

            // FCM Token Info
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Token Info',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    StreamBuilder<int>(
                      stream: NotificationService.getUnreadNotificationsCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return Text(
                          'Unread notifications: $unreadCount',
                          style: TextStyle(fontSize: 14.sp),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: _showFCMToken,
                      child: const Text('Show FCM Token'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _refreshFCMToken,
                      child: const Text('Refresh Token'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Server Tests
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Tests',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: _testServerConnection,
                      child: const Text('Test Server Connection'),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: _triggerPendingNotifications,
                      child: const Text('Trigger Pending Notifications'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testMessageNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing message notification...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await NotificationService.sendMessageNotification(
        receiverId: user.uid,
        senderName: 'Test User',
        message: 'This is a test message notification from LuWay testing system.',
        conversationId: 'test_conversation_id',
        carBrand: 'Test Car',
      );

      setState(() {
        _status = '✅ Message notification queued successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFavoriteNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing favorite notification...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await NotificationService.sendFavoriteAddedNotification(
        itemOwnerId: user.uid,
        favoritedByName: 'Test User',
        itemTitle: 'BMW X5 2023',
        itemId: 'test_item_id',
      );

      setState(() {
        _status = '✅ Favorite notification queued successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPriceUpdateNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing price update notification...';
    });

    try {
      await NotificationService.sendPriceUpdateNotification(
        itemId: 'test_item_id',
        itemTitle: 'Mercedes C-Class 2022',
        oldPrice: 35000.0,
        newPrice: 32000.0,
      );

      setState(() {
        _status = '✅ Price update notification queued successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDailySummaryNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing daily summary notification...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await NotificationService.sendDailySummaryNotification(
        userId: user.uid,
        totalFavorites: 5,
        itemTitles: ['BMW X5', 'Mercedes C-Class', 'Audi A4'],
      );

      setState(() {
        _status = '✅ Daily summary notification queued successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        setState(() {
          _status = '❌ No FCM token found for user';
        });
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM Token'),
          content: SelectableText(
            fcmToken,
            style: const TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _status = '❌ Error getting FCM token: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshFCMToken() async {
    setState(() {
      _isLoading = true;
      _status = 'Refreshing FCM token...';
    });

    try {
      final token = await NotificationService.getCurrentFCMToken();
      if (token != null) {
        setState(() {
          _status = '✅ FCM token refreshed: ${token.substring(0, 20)}...';
        });
      } else {
        setState(() {
          _status = '❌ Failed to get FCM token';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error refreshing token: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing server connection...';
    });

    // This would require http package to test server endpoints
    // For now, just simulate the test
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _status = '⚠️ Server test requires manual verification at http://localhost:3000/health';
      _isLoading = false;
    });
  }

  Future<void> _triggerPendingNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Triggering pending notifications...';
    });

    // This would require http package to call server endpoint
    // For now, just simulate the trigger
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _status = '⚠️ Manual trigger needed: POST http://localhost:3000/send-pending';
      _isLoading = false;
    });
  }
}
