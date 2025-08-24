import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/marketplace_item.dart';

class UserBehaviorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track when user views an item
  static Future<void> trackItemView(String itemId, MarketplaceItem item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('views')
          .collection('items')
          .doc(itemId)
          .set({
        'itemId': itemId,
        'category': item.type.toString(),
        'subcategory': item.serviceCategory?.toString() ?? item.accessoryCategory?.toString(),
        'brand': extractBrand(item.title),
        'model': extractModel(item.title),
        'priceRange': _getPriceRange(item.price),
        'viewedAt': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Tracked view for item: $itemId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking item view: $e');
      }
    }
  }

  /// Track when user searches
  static Future<void> trackSearch(String query, String? category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('searches')
          .collection('queries')
          .add({
        'query': query.toLowerCase().trim(),
        'category': category,
        'brand': extractBrand(query),
        'model': extractModel(query),
        'searchedAt': FieldValue.serverTimestamp(),
      });

      // Also update search frequency
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('search_terms')
          .collection('frequency')
          .doc(query.toLowerCase().trim())
          .set({
        'term': query.toLowerCase().trim(),
        'count': FieldValue.increment(1),
        'lastSearched': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Tracked search: $query');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking search: $e');
      }
    }
  }

  /// Get user preferences based on behavior
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Get most viewed categories
      final viewsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('views')
          .collection('items')
          .orderBy('viewedAt', descending: true)
          .limit(50)
          .get();

      // Get search history
      final searchSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('search_terms')
          .collection('frequency')
          .orderBy('count', descending: true)
          .limit(20)
          .get();

      // Analyze preferences
      final Map<String, int> categories = {};
      final Map<String, int> brands = {};
      final Map<String, int> priceRanges = {};
      final List<String> searchTerms = [];

      // Process views
      for (final doc in viewsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        final brand = data['brand'] as String?;
        final priceRange = data['priceRange'] as String?;
        final viewCount = data['viewCount'] as int? ?? 1;

        if (category != null) {
          categories[category] = (categories[category] ?? 0) + viewCount;
        }
        if (brand != null && brand.isNotEmpty) {
          brands[brand] = (brands[brand] ?? 0) + viewCount;
        }
        if (priceRange != null) {
          priceRanges[priceRange] = (priceRanges[priceRange] ?? 0) + viewCount;
        }
      }

      // Process searches
      for (final doc in searchSnapshot.docs) {
        final data = doc.data();
        final term = data['term'] as String?;
        if (term != null) {
          searchTerms.add(term);
        }
      }

      return {
        'categories': categories,
        'brands': brands,
        'priceRanges': priceRanges,
        'searchTerms': searchTerms,
        'preferredCategory': categories.isNotEmpty 
            ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'preferredBrand': brands.isNotEmpty 
            ? brands.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user preferences: $e');
      }
      return {};
    }
  }

  /// Extract brand from title/query
  static String extractBrand(String text) {
    final brands = [
      'BMW', 'Mercedes', 'Audi', 'Volkswagen', 'Ford', 'Toyota', 'Honda',
      'Nissan', 'Mazda', 'Hyundai', 'Kia', 'Renault', 'Peugeot', 'Citroen',
      'Skoda', 'Seat', 'Volvo', 'Lexus', 'Infiniti', 'Acura', 'Cadillac',
      'Chevrolet', 'GMC', 'Buick', 'Lincoln', 'Jaguar', 'Land Rover',
      'Porsche', 'Maserati', 'Ferrari', 'Lamborghini', 'Bentley',
      'Rolls-Royce', 'McLaren', 'Aston Martin', 'Tesla', 'Lucid',
      'Rivian', 'Genesis', 'Alfa Romeo', 'Fiat', 'Jeep', 'Ram',
      'Dodge', 'Chrysler', 'Mitsubishi', 'Subaru', 'Suzuki', 'Isuzu',
      'Dacia', 'Lada', 'UAZ', 'GAZ', 'ZAZ'
    ];

    final upperText = text.toUpperCase();
    for (final brand in brands) {
      if (upperText.contains(brand.toUpperCase())) {
        return brand;
      }
    }
    return '';
  }

  /// Extract model from title/query
  static String extractModel(String text) {
    final models = [
      'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'Series', 'Class',
      'Golf', 'Passat', 'Tiguan', 'Touareg', 'Polo', 'Jetta',
      'Focus', 'Fiesta', 'Mondeo', 'Kuga', 'Explorer', 'Mustang',
      'Corolla', 'Camry', 'RAV4', 'Highlander', 'Prius', 'Yaris',
      'Civic', 'Accord', 'CR-V', 'Pilot', 'Odyssey', 'Ridgeline'
    ];

    final upperText = text.toUpperCase();
    for (final model in models) {
      if (upperText.contains(model.toUpperCase())) {
        return model;
      }
    }
    return '';
  }

  /// Get price range category
  static String _getPriceRange(double price) {
    if (price < 5000) return 'under_5k';
    if (price < 10000) return '5k_10k';
    if (price < 20000) return '10k_20k';
    if (price < 50000) return '20k_50k';
    if (price < 100000) return '50k_100k';
    return 'over_100k';
  }

  /// Clear user behavior data
  static Future<void> clearBehaviorData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      
      // Delete views
      final viewsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('views')
          .collection('items')
          .get();

      for (final doc in viewsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete searches
      final searchesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('searches')
          .collection('queries')
          .get();

      for (final doc in searchesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete search terms
      final termsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('behavior')
          .doc('search_terms')
          .collection('frequency')
          .get();

      for (final doc in termsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('Cleared user behavior data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing behavior data: $e');
      }
    }
  }
}
