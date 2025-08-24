import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class PriceMonitoringService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Monitor price changes for marketplace items
  static Future<void> startPriceMonitoring() async {
    print('💰 Starting price monitoring service...');
    
    _firestore.collection('marketplace').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleItemUpdate(change);
        }
      }
    });
  }

  static Future<void> _handleItemUpdate(DocumentChange change) async {
    try {
      final newData = change.doc.data() as Map<String, dynamic>?;
      if (newData == null) return;

      final itemId = change.doc.id;
      
      // Get the previous version from a price history collection
      final historyDoc = await _firestore
          .collection('price_history')
          .doc(itemId)
          .get();

      if (!historyDoc.exists) {
        // First time, just save current price
        await _savePriceHistory(itemId, newData);
        return;
      }

      final historyData = historyDoc.data()!;
      final oldPrice = historyData['lastPrice'] as double?;
      final newPrice = (newData['price'] as num?)?.toDouble();

      if (oldPrice != null && newPrice != null && oldPrice != newPrice) {
        print('💰 Price change detected for item $itemId: $oldPrice → $newPrice');
        
        // Send notifications to users who favorited this item
        await NotificationService.sendPriceUpdateNotification(
          itemId: itemId,
          itemTitle: newData['title'] ?? 'Unknown Item',
          oldPrice: oldPrice,
          newPrice: newPrice,
        );

        // Update price history
        await _savePriceHistory(itemId, newData);
      }
    } catch (e) {
      print('❌ Error handling item update: $e');
    }
  }

  static Future<void> _savePriceHistory(String itemId, Map<String, dynamic> itemData) async {
    try {
      await _firestore.collection('price_history').doc(itemId).set({
        'lastPrice': itemData['price'],
        'lastUpdate': FieldValue.serverTimestamp(),
        'title': itemData['title'],
      });
    } catch (e) {
      print('❌ Error saving price history: $e');
    }
  }

  // Get price history for an item
  static Future<List<Map<String, dynamic>>> getPriceHistory(String itemId) async {
    try {
      final historyQuery = await _firestore
          .collection('price_history')
          .doc(itemId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return historyQuery.docs.map((doc) => {
        'price': doc.data()['price'],
        'timestamp': doc.data()['timestamp'],
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('❌ Error getting price history: $e');
      return [];
    }
  }
}
