import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/marketplace_item.dart';
import 'notification_service.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for favorite status
  static final Map<String, bool> _favoriteCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 3); // Cache for 3 minutes
  
  // Check if cache is valid for an item
  static bool _isCacheValid(String itemId) {
    final timestamp = _cacheTimestamps[itemId];
    return timestamp != null && 
           DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Add item to favorites
  static Future<bool> addToFavorites(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .set({
        'itemId': itemId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Add to global favorites collection for notifications
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'itemId': itemId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update cache
      _favoriteCache[itemId] = true;
      _cacheTimestamps[itemId] = DateTime.now();

      // Send notification to item owner
      try {
        final itemDoc = await _firestore.collection('marketplace').doc(itemId).get();
        if (itemDoc.exists) {
          final itemData = itemDoc.data()!;
          final itemOwnerId = itemData['sellerId'];
          
          // Don't send notification if user favorites their own item
          if (itemOwnerId != user.uid) {
            final userDoc = await _firestore.collection('users').doc(user.uid).get();
            final userName = userDoc.data()?['nickname'] ?? 
                            userDoc.data()?['displayName'] ?? 
                            'Un utilizator';

            await NotificationService.sendFavoriteAddedNotification(
              itemOwnerId: itemOwnerId,
              favoritedByName: userName,
              itemTitle: itemData['title'] ?? 'Anunț',
              itemId: itemId,
            );
          }
        }
      } catch (e) {
        print('❌ Error sending favorite notification: $e');
      }

      if (kDebugMode) {
        print('Item $itemId added to favorites');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to favorites: $e');
      }
      return false;
    }
  }

  /// Remove item from favorites
  static Future<bool> removeFromFavorites(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .delete();

      // Update cache
      _favoriteCache[itemId] = false;
      _cacheTimestamps[itemId] = DateTime.now();

      if (kDebugMode) {
        print('Item $itemId removed from favorites');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from favorites: $e');
      }
      return false;
    }
  }

  /// Check if item is in favorites
  static Future<bool> isFavorite(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check cache first
      if (_isCacheValid(itemId)) {
        return _favoriteCache[itemId] ?? false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .get();

      final isFav = doc.exists;
      
      // Cache the result
      _favoriteCache[itemId] = isFav;
      _cacheTimestamps[itemId] = DateTime.now();
      
      return isFav;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking favorite status: $e');
      }
      return false;
    }
  }

  /// Get user's favorite items
  static Future<List<String>> getUserFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()['itemId'] as String).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user favorites: $e');
      }
      return [];
    }
  }

  /// Get favorite items with details
  static Future<List<MarketplaceItem>> getFavoriteItems() async {
    try {
      final favoriteIds = await getUserFavorites();
      if (favoriteIds.isEmpty) return [];

      final List<MarketplaceItem> favoriteItems = [];

      // Get items in batches (Firestore 'in' query limit is 10)
      for (int i = 0; i < favoriteIds.length; i += 10) {
        final batch = favoriteIds.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection('marketplace')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final item = MarketplaceItem.fromJson(doc.id, doc.data());
            favoriteItems.add(item);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing favorite item ${doc.id}: $e');
            }
          }
        }
      }

      return favoriteItems;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorite items: $e');
      }
      return [];
    }
  }

  /// Toggle favorite status
  static Future<bool> toggleFavorite(String itemId) async {
    final isFav = await isFavorite(itemId);
    if (isFav) {
      return await removeFromFavorites(itemId);
    } else {
      return await addToFavorites(itemId);
    }
  }

  /// Get favorites count for user
  static Future<int> getFavoritesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorites count: $e');
      }
      return 0;
    }
  }
}
