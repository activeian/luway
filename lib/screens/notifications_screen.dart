import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../models/marketplace_item.dart';
import 'marketplace_item_detail_screen.dart';
import 'chat_screen.dart';

const Color oliveColor = Color(0xFF808000);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _showClearAllDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Color(0xFFB3B760),
            ));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              return _buildNotificationCard(notification.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Notifications will appear here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      String notificationId, Map<String, dynamic> data) {
    final isRead = data['read'] as bool? ?? false;
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final timestamp = data['timestamp'] as Timestamp?;
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : oliveColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : oliveColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _handleNotificationTap(notificationId, notificationData),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on notification type
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: oliveColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (timestamp != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'favorite_added':
        return Icons.favorite;
      case 'price_update':
        return Icons.trending_down;
      case 'daily_summary':
        return Icons.analytics;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'favorite_added':
        return Colors.red;
      case 'price_update':
        return Colors.orange;
      case 'daily_summary':
        return oliveColor;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  Future<void> _handleNotificationTap(
      String notificationId, Map<String, dynamic> data) async {
    // Mark as read
    await NotificationService.markNotificationAsRead(notificationId);

    // Navigate based on type
    switch (data['type']) {
      case 'message':
        if (data['conversationId'] != null) {
          // Mark messages as read immediately for better UX
          final senderId = data['senderId'] ?? '';
          if (senderId.isNotEmpty) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
            if (currentUserId.isNotEmpty) {
              ChatService.markMessagesAsRead(currentUserId, senderId);
            }
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatConversationScreen(
                  conversationId: data['conversationId'],
                  receiverId: data['senderId'] ?? '',
                  carBrand: data['carBrand'] ?? 'Chat',
                ),
              ),
            );
          }
        }
        break;

      case 'favorite_added':
      case 'price_update':
        if (data['itemId'] != null) {
          try {
            final itemDoc = await FirebaseFirestore.instance
                .collection('marketplace')
                .doc(data['itemId'])
                .get();

            if (itemDoc.exists && mounted) {
              final item = MarketplaceItem.fromJson(
                itemDoc.id,
                itemDoc.data() as Map<String, dynamic>,
              );
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MarketplaceItemDetailScreen(item: item),
                  ),
                );
              }
            }
          } catch (e) {
            print('❌ Error loading marketplace item: $e');
          }
        }
        break;

      case 'daily_summary':
        // Navigate to analytics or favorites screen
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications'),
        content:
            const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.clearAllNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications have been deleted'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
