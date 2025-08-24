import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class DailySummaryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send daily summary notifications to all users
  static Future<void> sendDailySummaryToAllUsers() async {
    print('📊 Sending daily summary notifications...');
    
    try {
      // Get all users
      final usersQuery = await _firestore.collection('users').get();
      
      for (final userDoc in usersQuery.docs) {
        await _sendDailySummaryToUser(userDoc.id);
      }
      
      print('✅ Daily summary notifications sent to all users');
    } catch (e) {
      print('❌ Error sending daily summaries: $e');
    }
  }

  static Future<void> _sendDailySummaryToUser(String userId) async {
    try {
      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get user's marketplace items
      final userItemsQuery = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .get();

      if (userItemsQuery.docs.isEmpty) {
        print('📝 No items for user $userId');
        return;
      }

      final itemIds = userItemsQuery.docs.map((doc) => doc.id).toList();
      final itemTitles = userItemsQuery.docs.map((doc) => doc.data()['title'] as String).toList();

      // Get today's favorites for user's items
      int totalFavorites = 0;
      List<String> favoritedItems = [];

      for (int i = 0; i < itemIds.length; i++) {
        final itemId = itemIds[i];
        final itemTitle = itemTitles[i];
        
        final favoritesQuery = await _firestore
            .collection('favorites')
            .where('itemId', isEqualTo: itemId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        if (favoritesQuery.docs.isNotEmpty) {
          totalFavorites += favoritesQuery.docs.length;
          favoritedItems.add(itemTitle);
        }
      }

      // Send notification only if there are favorites
      if (totalFavorites > 0) {
        await NotificationService.sendDailySummaryNotification(
          userId: userId,
          totalFavorites: totalFavorites,
          itemTitles: favoritedItems,
        );
        
        print('📊 Daily summary sent to user $userId: $totalFavorites favorites');
      } else {
        print('📝 No favorites today for user $userId');
      }
    } catch (e) {
      print('❌ Error sending daily summary to user $userId: $e');
    }
  }

  // Get daily stats for a user
  static Future<Map<String, dynamic>> getDailyStatsForUser(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get user's items
      final userItemsQuery = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .get();

      final itemIds = userItemsQuery.docs.map((doc) => doc.id).toList();

      // Get today's views
      int totalViews = 0;
      int totalFavorites = 0;
      int totalMessages = 0;

      for (final itemId in itemIds) {
        // Views
        final viewsQuery = await _firestore
            .collection('item_views')
            .where('itemId', isEqualTo: itemId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        totalViews += viewsQuery.docs.length;

        // Favorites
        final favoritesQuery = await _firestore
            .collection('favorites')
            .where('itemId', isEqualTo: itemId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        totalFavorites += favoritesQuery.docs.length;
      }

      // Get today's messages received
      final messagesQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      for (final convDoc in messagesQuery.docs) {
        final messagesSubQuery = await convDoc.reference
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .get();
        totalMessages += messagesSubQuery.docs.length;
      }

      return {
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
        'totalMessages': totalMessages,
        'date': startOfDay,
      };
    } catch (e) {
      print('❌ Error getting daily stats: $e');
      return {};
    }
  }

  // Get weekly summary for a user
  static Future<Map<String, dynamic>> getWeeklySummaryForUser(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Get user's items
      final userItemsQuery = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .get();

      final itemIds = userItemsQuery.docs.map((doc) => doc.id).toList();

      int totalViews = 0;
      int totalFavorites = 0;
      Map<String, int> dailyViews = {};
      Map<String, int> dailyFavorites = {};

      for (final itemId in itemIds) {
        // Get weekly views
        final viewsQuery = await _firestore
            .collection('item_views')
            .where('itemId', isEqualTo: itemId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfWeek))
            .get();

        for (final viewDoc in viewsQuery.docs) {
          totalViews++;
          final timestamp = (viewDoc.data()['timestamp'] as Timestamp).toDate();
          final dayKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          dailyViews[dayKey] = (dailyViews[dayKey] ?? 0) + 1;
        }

        // Get weekly favorites
        final favoritesQuery = await _firestore
            .collection('favorites')
            .where('itemId', isEqualTo: itemId)
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfWeek))
            .get();

        for (final favDoc in favoritesQuery.docs) {
          totalFavorites++;
          final timestamp = (favDoc.data()['timestamp'] as Timestamp).toDate();
          final dayKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          dailyFavorites[dayKey] = (dailyFavorites[dayKey] ?? 0) + 1;
        }
      }

      return {
        'totalViews': totalViews,
        'totalFavorites': totalFavorites,
        'dailyViews': dailyViews,
        'dailyFavorites': dailyFavorites,
        'weekStart': startOfWeek,
        'weekEnd': endOfWeek,
      };
    } catch (e) {
      print('❌ Error getting weekly summary: $e');
      return {};
    }
  }

  // Schedule daily summary (this would typically be called by a server-side cron job)
  static Future<void> scheduleDailySummary() async {
    print('⏰ Scheduling daily summary...');
    
    // Save schedule to Firestore for server processing
    await _firestore.collection('scheduled_tasks').add({
      'type': 'daily_summary',
      'scheduledFor': FieldValue.serverTimestamp(),
      'executed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Daily summary scheduled');
  }
}
