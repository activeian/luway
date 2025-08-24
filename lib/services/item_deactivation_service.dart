import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_item.dart';

class ItemDeactivationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deactivate an item and set 30-day grace period
  static Future<bool> deactivateItem(String itemId, {String? reason}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final graceExpiry = now.add(const Duration(days: 30));

      await _firestore.collection('marketplace').doc(itemId).update({
        'isActive': false,
        'deactivatedAt': Timestamp.fromDate(now),
        'graceExpiresAt': Timestamp.fromDate(graceExpiry),
        'isExpired': false,
        'updatedAt': Timestamp.fromDate(now),
        'deactivationReason': reason,
      });

      print('✅ Item $itemId deactivated with 30-day grace period until ${graceExpiry.toIso8601String()}');
      return true;
    } catch (e) {
      print('❌ Error deactivating item $itemId: $e');
      return false;
    }
  }

  /// Reactivate an item within grace period
  static Future<bool> reactivateItem(String itemId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First check if item can be reactivated
      final doc = await _firestore.collection('marketplace').doc(itemId).get();
      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data()!;
      final item = MarketplaceItem.fromJson(itemId, data);

      if (!item.canBeReactivated) {
        throw Exception('Item cannot be reactivated - grace period has expired');
      }

      final now = DateTime.now();

      await _firestore.collection('marketplace').doc(itemId).update({
        'isActive': true,
        'deactivatedAt': null,
        'graceExpiresAt': null,
        'isExpired': false,
        'updatedAt': Timestamp.fromDate(now),
        'reactivatedAt': Timestamp.fromDate(now),
      });

      print('✅ Item $itemId reactivated successfully');
      return true;
    } catch (e) {
      print('❌ Error reactivating item $itemId: $e');
      return false;
    }
  }

  /// Check and expire items that have passed the 30-day grace period
  static Future<void> expireGracePeriodItems() async {
    try {
      final now = DateTime.now();
      
      // Query for items in grace period that have expired
      final expiredQuery = await _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: false)
          .where('graceExpiresAt', isLessThan: Timestamp.fromDate(now))
          .where('isExpired', isEqualTo: false)
          .get();

      if (expiredQuery.docs.isEmpty) {
        print('📅 No items to expire');
        return;
      }

      print('⏰ Found ${expiredQuery.docs.length} items to expire');

      // Update expired items
      WriteBatch batch = _firestore.batch();
      
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {
          'isExpired': true,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      print('✅ Expired ${expiredQuery.docs.length} items that passed grace period');
    } catch (e) {
      print('❌ Error expiring grace period items: $e');
    }
  }

  /// Get items that are in grace period for a user
  static Future<List<MarketplaceItem>> getUserItemsInGracePeriod(String userId) async {
    try {
      final query = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .where('isActive', isEqualTo: false)
          .where('isExpired', isEqualTo: false)
          .get();

      List<MarketplaceItem> items = [];
      final now = DateTime.now();

      for (final doc in query.docs) {
        final data = doc.data();
        final item = MarketplaceItem.fromJson(doc.id, data);
        
        // Only include items still in grace period
        if (item.graceExpiresAt != null && item.graceExpiresAt!.isAfter(now)) {
          items.add(item);
        }
      }

      return items;
    } catch (e) {
      print('❌ Error getting grace period items: $e');
      return [];
    }
  }

  /// Get count of items that will expire soon (within 7 days)
  static Future<int> getItemsExpiringSoonCount(String userId) async {
    try {
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      final query = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .where('isActive', isEqualTo: false)
          .where('isExpired', isEqualTo: false)
          .where('graceExpiresAt', isLessThan: Timestamp.fromDate(weekFromNow))
          .where('graceExpiresAt', isGreaterThan: Timestamp.fromDate(now))
          .get();

      return query.docs.length;
    } catch (e) {
      print('❌ Error getting expiring soon count: $e');
      return 0;
    }
  }

  /// Auto-deactivate items based on certain criteria (e.g., expired cars)
  static Future<void> autoDeactivateExpiredItems() async {
    try {
      // Example: Auto-deactivate cars that haven't been updated in 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      
      final oldItemsQuery = await _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: 'car')
          .where('updatedAt', isLessThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      if (oldItemsQuery.docs.isEmpty) {
        print('📅 No old items to auto-deactivate');
        return;
      }

      print('⏰ Found ${oldItemsQuery.docs.length} old items to auto-deactivate');

      // Auto-deactivate old items
      for (final doc in oldItemsQuery.docs) {
        await deactivateItem(doc.id, reason: 'Auto-deactivated due to inactivity (6+ months)');
      }

      print('✅ Auto-deactivated ${oldItemsQuery.docs.length} old items');
    } catch (e) {
      print('❌ Error auto-deactivating items: $e');
    }
  }

  /// Schedule automatic checks (to be called periodically)
  static Future<void> performScheduledMaintenance() async {
    print('🔧 Starting scheduled marketplace maintenance...');
    
    // Expire items that have passed grace period
    await expireGracePeriodItems();
    
    // Auto-deactivate very old items
    await autoDeactivateExpiredItems();
    
    print('✅ Scheduled marketplace maintenance completed');
  }
}
