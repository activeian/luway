import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Track when a user views a marketplace item
  static Future<void> trackItemView({
    required String itemId,
    required String itemOwnerId,
    String? viewerUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      viewerUserId ??= FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      print('🎯 ViewTrackingService: Tracking view');
      print('📦 Item ID: $itemId');
      print('👤 Owner ID: $itemOwnerId');
      print('👁️ Viewer ID: $viewerUserId');
      
      // Don't track views from the item owner
      if (viewerUserId == itemOwnerId) {
        print('🚫 Skipping view tracking - owner viewing own item');
        return;
      }
      
      final viewData = {
        'itemId': itemId,
        'itemOwnerId': itemOwnerId,
        'viewerUserId': viewerUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isAuthenticated': viewerUserId != 'anonymous',
        ...?additionalData,
      };
      
      print('💾 Saving view data: $viewData');
      
      // Add to views collection
      await _firestore.collection('item_views').add(viewData);
      print('✅ View record saved to item_views collection');
      
      // Update item's view count
      await _firestore.collection('marketplace_items').doc(itemId).update({
        'totalViews': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Marketplace item view count updated');
      
      // Update daily view count for the item owner's analytics
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('user_analytics')
          .doc(itemOwnerId)
          .collection('daily_views')
          .doc(dateKey)
          .set({
        'date': dateKey,
        'totalViews': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ Daily analytics updated for date: $dateKey');
      
      // Track recent activity for the item owner
      await _trackViewActivity(itemId, itemOwnerId, viewerUserId);
      print('✅ View activity tracked');
      
      print('🎉 View tracking completed successfully!');
      
    } catch (e) {
      print('❌ Error tracking item view: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    }
  }
  
  /// Get total views for a specific item
  static Future<int> getItemViewCount(String itemId) async {
    try {
      final doc = await _firestore.collection('marketplace_items').doc(itemId).get();
      return doc.data()?['totalViews'] ?? 0;
    } catch (e) {
      print('Error getting item view count: $e');
      return 0;
    }
  }
  
  /// Get total views for all user's items
  static Future<int> getUserTotalViews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('marketplace_items')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      int totalViews = 0;
      for (final doc in querySnapshot.docs) {
        totalViews += (doc.data()['totalViews'] ?? 0) as int;
      }
      
      return totalViews;
    } catch (e) {
      print('Error getting user total views: $e');
      return 0;
    }
  }
  
  /// Get view analytics for a user (last 30 days)
  static Future<Map<String, int>> getUserViewAnalytics(String userId) async {
    try {
      final Map<String, int> analytics = {};
      final now = DateTime.now();
      
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        final doc = await _firestore
            .collection('user_analytics')
            .doc(userId)
            .collection('daily_views')
            .doc(dateKey)
            .get();
        
        analytics[dateKey] = doc.data()?['totalViews'] ?? 0;
      }
      
      return analytics;
    } catch (e) {
      print('Error getting user view analytics: $e');
      return {};
    }
  }
  
  /// Get recent viewers for a specific item
  static Future<List<Map<String, dynamic>>> getItemRecentViewers(String itemId, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('item_views')
          .where('itemId', isEqualTo: itemId)
          .where('isAuthenticated', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final viewers = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final viewerUserId = data['viewerUserId'];
        
        // Get viewer info
        final userDoc = await _firestore.collection('users').doc(viewerUserId).get();
        final userData = userDoc.data() ?? {};
        
        viewers.add({
          'viewerId': viewerUserId,
          'viewerName': userData['displayName'] ?? 'Anonymous User',
          'viewerAvatar': userData['photoURL'],
          'timestamp': data['timestamp'],
        });
      }
      
      return viewers;
    } catch (e) {
      print('Error getting item recent viewers: $e');
      return [];
    }
  }
  
  /// Track user profile views
  static Future<void> trackProfileView({
    required String profileOwnerId,
    String? viewerUserId,
  }) async {
    try {
      viewerUserId ??= FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      
      // Don't track self-views
      if (viewerUserId == profileOwnerId) return;
      
      await _firestore.collection('profile_views').add({
        'profileOwnerId': profileOwnerId,
        'viewerUserId': viewerUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isAuthenticated': viewerUserId != 'anonymous',
      });
      
      // Update user's profile view count
      await _firestore.collection('users').doc(profileOwnerId).update({
        'profileViews': FieldValue.increment(1),
      });
      
    } catch (e) {
      print('Error tracking profile view: $e');
    }
  }
  
  /// Get view statistics for user's items
  static Future<Map<String, dynamic>> getItemViewStatistics(String userId) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('marketplace_items')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      int totalItems = itemsSnapshot.docs.length;
      int totalViews = 0;
      int itemsWithViews = 0;
      String mostViewedItemId = '';
      int maxViews = 0;
      
      for (final doc in itemsSnapshot.docs) {
        final data = doc.data();
        final views = (data['totalViews'] ?? 0) as int;
        totalViews += views;
        
        if (views > 0) {
          itemsWithViews++;
        }
        
        if (views > maxViews) {
          maxViews = views;
          mostViewedItemId = doc.id;
        }
      }
      
      return {
        'totalItems': totalItems,
        'totalViews': totalViews,
        'itemsWithViews': itemsWithViews,
        'averageViewsPerItem': totalItems > 0 ? (totalViews / totalItems).round() : 0,
        'mostViewedItemId': mostViewedItemId,
        'mostViewedItemViews': maxViews,
      };
    } catch (e) {
      print('Error getting item view statistics: $e');
      return {};
    }
  }
  
  /// Track activity for recent activity feed
  static Future<void> _trackViewActivity(String itemId, String itemOwnerId, String viewerUserId) async {
    try {
      // Get item info for activity description
      final itemDoc = await _firestore.collection('marketplace_items').doc(itemId).get();
      final itemData = itemDoc.data();
      
      if (itemData == null) return;
      
      await _firestore.collection('marketplace_activity').add({
        'userId': itemOwnerId,
        'action': 'item_viewed',
        'details': '${itemData['title']} received a new view',
        'itemId': itemId,
        'viewerUserId': viewerUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking view activity: $e');
    }
  }
  
  /// Get trending items based on recent views
  static Future<List<String>> getTrendingItems({int limit = 10, int daysBack = 7}) async {
    try {
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: daysBack))
      );
      
      final querySnapshot = await _firestore
          .collection('item_views')
          .where('timestamp', isGreaterThan: cutoffDate)
          .get();
      
      // Count views per item
      final Map<String, int> itemViewCounts = {};
      
      for (final doc in querySnapshot.docs) {
        final itemId = doc.data()['itemId'] as String;
        itemViewCounts[itemId] = (itemViewCounts[itemId] ?? 0) + 1;
      }
      
      // Sort by view count and return top items
      final sortedItems = itemViewCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedItems
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting trending items: $e');
      return [];
    }
  }
}
