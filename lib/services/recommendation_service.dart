import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/marketplace_item.dart';
import '../services/country_service.dart';
import '../services/user_behavior_service.dart';
import 'dart:math' as math;

class RecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for recommendations
  static List<MarketplaceItem>? _cachedRecommendations;
  static List<MarketplaceItem>? _cachedTrending;
  static DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5); // Cache for 5 minutes
  
  // Check if cache is valid
  static bool _isCacheValid() {
    return _lastCacheTime != null && 
           DateTime.now().difference(_lastCacheTime!) < _cacheTimeout;
  }

  /// Get personalized recommendations for home screen
  /// 70-80% similar products + 20-30% related products
  static Future<List<MarketplaceItem>> getHomeRecommendations({
    int limit = 20,
    double similarityThreshold = 0.75, // 75% similar, 25% related
  }) async {
    try {
      // Check cache first
      if (_isCacheValid() && _cachedRecommendations != null) {
        print('RecommendationService: Returning cached recommendations');
        return _cachedRecommendations!.take(limit).toList();
      }
      
      print('RecommendationService: Starting to get home recommendations...');
      
      // Get user's country for location-based filtering
      final country = await CountryService.detectCurrentCountry();
      final countryCode = country?.code ?? 'RO'; // Default to Romania
      print('RecommendationService: User country: $countryCode');

      // Get user preferences
      final preferences = await UserBehaviorService.getUserPreferences();
      print('RecommendationService: User preferences: $preferences');
      
      if (preferences.isEmpty || preferences['categories'] == null) {
        // If no user behavior, return popular items from user's country
        print('RecommendationService: No preferences found, getting popular items');
        return await _getPopularItemsByCountry(countryCode, limit);
      }

      final List<MarketplaceItem> recommendations = [];
      
      // Calculate how many items for each category
      final similarCount = (limit * similarityThreshold).round();
      final relatedCount = limit - similarCount;
      print('RecommendationService: Similar: $similarCount, Related: $relatedCount');

      // Get similar items (70-80%)
      final similarItems = await _getSimilarItems(
        preferences, 
        countryCode, 
        similarCount,
      );
      recommendations.addAll(similarItems);
      print('RecommendationService: Got ${similarItems.length} similar items');

      // Get related items (20-30%)
      final relatedItems = await _getRelatedItems(
        preferences, 
        countryCode, 
        relatedCount,
        excludeIds: similarItems.map((item) => item.id).toList(),
      );
      recommendations.addAll(relatedItems);
      print('RecommendationService: Got ${relatedItems.length} related items');

      // Shuffle to make recommendations appear more natural
      recommendations.shuffle();

      // Cache the results
      _cachedRecommendations = recommendations;
      _lastCacheTime = DateTime.now();

      if (kDebugMode) {
        print('RecommendationService: Generated ${recommendations.length} recommendations total');
        print('Similar: ${similarItems.length}, Related: ${relatedItems.length}');
        print('RecommendationService: Cached recommendations for future requests');
      }

      return recommendations;
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationService: Error getting recommendations: $e');
      }
      return [];
    }
  }

  /// Get items similar to user's viewing/search history
  static Future<List<MarketplaceItem>> _getSimilarItems(
    Map<String, dynamic> preferences,
    String countryCode,
    int limit,
  ) async {
    final List<MarketplaceItem> similarItems = [];

    try {
      // Get preferred category and brand
      final preferredCategory = preferences['preferredCategory'] as String?;
      final preferredBrand = preferences['preferredBrand'] as String?;
      final searchTerms = preferences['searchTerms'] as List<String>? ?? [];

      // Query based on preferred category
      if (preferredCategory != null) {
        var query = _firestore
            .collection('marketplace')
            .where('isActive', isEqualTo: true);

        // Add country filter only if location field exists
        if (countryCode.isNotEmpty) {
          query = query.where('location', isEqualTo: countryCode);
        }

        // Filter by type if it's a valid MarketplaceItemType
        if (preferredCategory.contains('MarketplaceItemType.')) {
          final typeString = preferredCategory.split('.').last;
          query = query.where('type', isEqualTo: typeString);
        }

        final snapshot = await query
            .orderBy('createdAt', descending: true)
            .limit(limit * 2) // Get more to filter later
            .get();

        for (final doc in snapshot.docs) {
          try {
            final item = MarketplaceItem.fromJson(doc.id, doc.data());
            
            // Check if item matches user preferences
            if (_isItemSimilar(item, preferences)) {
              similarItems.add(item);
              if (similarItems.length >= limit) break;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing similar item ${doc.id}: $e');
            }
          }
        }
      }

      // If we don't have enough similar items, get by search terms
      if (similarItems.length < limit && searchTerms.isNotEmpty) {
        final remaining = limit - similarItems.length;
        final termItems = await _getItemsBySearchTerms(
          searchTerms, 
          countryCode, 
          remaining,
          excludeIds: similarItems.map((item) => item.id).toList(),
        );
        similarItems.addAll(termItems);
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error getting similar items: $e');
      }
    }

    // If no items found, return demo data
    if (similarItems.isEmpty) {
      print('RecommendationService: No similar items found, generating demo data');
      return _generateDemoData(limit);
    }

    return similarItems.take(limit).toList();
  }

  /// Get related items (different but relevant)
  static Future<List<MarketplaceItem>> _getRelatedItems(
    Map<String, dynamic> preferences,
    String countryCode,
    int limit, {
    List<String> excludeIds = const [],
  }) async {
    final List<MarketplaceItem> relatedItems = [];

    try {
      final preferredBrand = preferences['preferredBrand'] as String?;
      
      // Get items from related categories/brands
      var query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true);

      // Add country filter
      if (countryCode.isNotEmpty) {
        query = query.where('location', isEqualTo: countryCode);
      }

      if (excludeIds.isNotEmpty) {
        // Firestore doesn't support not-in with large arrays, so we'll filter later
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Get more to filter
          .get();

      for (final doc in snapshot.docs) {
        if (excludeIds.contains(doc.id)) continue;
        
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          
          // Check if item is related but not too similar
          if (_isItemRelated(item, preferences) && !_isItemSimilar(item, preferences)) {
            relatedItems.add(item);
            if (relatedItems.length >= limit) break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing related item ${doc.id}: $e');
          }
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error getting related items: $e');
      }
    }

    return relatedItems.take(limit).toList();
  }

  /// Get items by search terms
  static Future<List<MarketplaceItem>> _getItemsBySearchTerms(
    List<String> searchTerms,
    String countryCode,
    int limit, {
    List<String> excludeIds = const [],
  }) async {
    final List<MarketplaceItem> items = [];

    try {
      for (final term in searchTerms.take(3)) { // Limit to top 3 search terms
        final snapshot = await _firestore
            .collection('marketplace')
            .where('isActive', isEqualTo: true)
            .where('location', isEqualTo: countryCode)
            .where('tags', arrayContainsAny: [term, term.toLowerCase(), term.toUpperCase()])
            .limit(limit)
            .get();

        for (final doc in snapshot.docs) {
          if (excludeIds.contains(doc.id)) continue;
          if (items.any((item) => item.id == doc.id)) continue; // Avoid duplicates
          
          try {
            final item = MarketplaceItem.fromJson(doc.id, doc.data());
            items.add(item);
            if (items.length >= limit) break;
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing search term item ${doc.id}: $e');
            }
          }
        }
        
        if (items.length >= limit) break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting items by search terms: $e');
      }
    }

    return items;
  }

  /// Check if item is similar to user preferences
  static bool _isItemSimilar(MarketplaceItem item, Map<String, dynamic> preferences) {
    final categories = preferences['categories'] as Map<String, int>? ?? {};
    final brands = preferences['brands'] as Map<String, int>? ?? {};
    
    // Check category similarity
    final itemType = item.type.toString();
    if (categories.containsKey(itemType)) {
      return true;
    }

    // Check brand similarity
    final itemBrand = _extractBrand(item.title);
    if (itemBrand.isNotEmpty && brands.containsKey(itemBrand)) {
      return true;
    }

    return false;
  }

  /// Extract brand from title/query (internal method)
  static String _extractBrand(String text) {
    return UserBehaviorService.extractBrand(text);
  }

  /// Check if item is related but not too similar
  static bool _isItemRelated(MarketplaceItem item, Map<String, dynamic> preferences) {
    final brands = preferences['brands'] as Map<String, int>? ?? {};
    final searchTerms = preferences['searchTerms'] as List<String>? ?? [];
    
    // Check if it's from a related brand (for cars)
    if (item.type == MarketplaceItemType.car) {
      final itemBrand = _extractBrand(item.title);
      if (itemBrand.isNotEmpty) {
        // Get related brands
        final relatedBrands = _getRelatedBrands(itemBrand);
        for (final relatedBrand in relatedBrands) {
          if (brands.containsKey(relatedBrand)) {
            return true;
          }
        }
      }
    }

    // Check if title contains any search terms
    final titleLower = item.title.toLowerCase();
    for (final term in searchTerms) {
      if (titleLower.contains(term.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Get related brands for a given brand
  static List<String> _getRelatedBrands(String brand) {
    final brandGroups = {
      'BMW': ['Mercedes', 'Audi', 'Lexus'],
      'Mercedes': ['BMW', 'Audi', 'Lexus'],
      'Audi': ['BMW', 'Mercedes', 'Lexus'],
      'Volkswagen': ['Skoda', 'Seat', 'Audi'],
      'Skoda': ['Volkswagen', 'Seat'],
      'Toyota': ['Honda', 'Mazda', 'Nissan'],
      'Honda': ['Toyota', 'Mazda', 'Nissan'],
      'Ford': ['Chevrolet', 'GMC'],
      'Renault': ['Peugeot', 'Citroen'],
      'Peugeot': ['Renault', 'Citroen'],
    };

    return brandGroups[brand] ?? [];
  }

  /// Get popular items from a specific country (fallback)
  static Future<List<MarketplaceItem>> _getPopularItemsByCountry(
    String countryCode,
    int limit,
  ) async {
    try {
      print('RecommendationService: Getting popular items for country: $countryCode');
      
      var query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true);

      // Only add country filter if we have a valid country code
      if (countryCode.isNotEmpty && countryCode != 'Unknown') {
        query = query.where('country', isEqualTo: countryCode);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to ensure we have enough after filtering
          .get();

      print('RecommendationService: Found ${snapshot.docs.length} marketplace items');

      final List<MarketplaceItem> items = [];
      
      // If no items found in Firestore, return demo data for testing
      if (snapshot.docs.isEmpty) {
        print('RecommendationService: No items in Firestore, generating demo data');
        return _generateDemoData(limit);
      }
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('RecommendationService: Processing item ${doc.id} - ${data['title']}');
          final item = MarketplaceItem.fromJson(doc.id, data);
          items.add(item);
          if (items.length >= limit) break;
        } catch (e) {
          if (kDebugMode) {
            print('RecommendationService: Error parsing popular item ${doc.id}: $e');
          }
        }
      }

      print('RecommendationService: Returning ${items.length} popular items');
      return items;
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationService: Error getting popular items: $e');
      }
      return [];
    }
  }

  /// Get trending items based on view count
  static Future<List<MarketplaceItem>> getTrendingItems({
    int limit = 10,
    String? countryCode,
  }) async {
    try {
      // Check cache first
      if (_isCacheValid() && _cachedTrending != null) {
        print('RecommendationService: Returning cached trending items');
        return _cachedTrending!.take(limit).toList();
      }
      
      print('RecommendationService: Getting trending items...');
      
      // Get current country if not provided
      if (countryCode == null) {
        final country = await CountryService.detectCurrentCountry();
        countryCode = country?.code ?? 'RO';
      }
      
      print('RecommendationService: Trending items for country: $countryCode');

      // This would require a more complex implementation with view tracking
      // For now, return recent items with high ratings
      var query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true);

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      print('RecommendationService: Found ${snapshot.docs.length} items for trending');

      final List<MarketplaceItem> items = [];
      for (final doc in snapshot.docs) {
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          items.add(item);
          if (items.length >= limit) break;
        } catch (e) {
          if (kDebugMode) {
            print('RecommendationService: Error parsing trending item ${doc.id}: $e');
          }
        }
      }

      print('RecommendationService: Returning ${items.length} trending items');
      
      // Cache the results
      _cachedTrending = items;
      if (_lastCacheTime == null) {
        _lastCacheTime = DateTime.now();
      }
      
      return items;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('RecommendationService: Error getting trending items: $e');
        }
      }
      return [];
    }
  }

  /// Generate demo data for testing when Firestore is empty
  static List<MarketplaceItem> _generateDemoData(int limit) {
    print('RecommendationService: Generating $limit demo items');
    
    final List<MarketplaceItem> demoItems = [];
    final random = math.Random();
    
    final carBrands = ['BMW', 'Mercedes', 'Audi', 'Toyota', 'VW', 'Ford', 'Honda', 'Nissan'];
    final carModels = ['X5', 'C-Class', 'A4', 'Camry', 'Golf', 'Focus', 'Civic', 'Altima'];
    final accessories = ['Anvelope', 'Jante', 'Navigatie', 'Camera', 'Senzori', 'Alarma', 'Scaune'];
    final services = ['Reparatii', 'Mentenanta', 'Curatenie', 'Verificare', 'Tuning', 'Vopsire'];
    final locations = ['Bucuresti', 'Cluj-Napoca', 'Timisoara', 'Iasi', 'Constanta', 'Brasov'];
    
    for (int i = 0; i < limit; i++) {
      final itemType = MarketplaceItemType.values[random.nextInt(MarketplaceItemType.values.length)];
      final imageUrls = [
        'https://picsum.photos/400/300?random=$i',
        'https://picsum.photos/400/300?random=${i + 100}',
      ];
      
      String title;
      double price;
      
      switch (itemType) {
        case MarketplaceItemType.car:
          final brand = carBrands[random.nextInt(carBrands.length)];
          final model = carModels[random.nextInt(carModels.length)];
          title = '$brand $model ${2015 + random.nextInt(9)}';
          price = 15000 + random.nextDouble() * 85000; // 15k - 100k
          break;
        case MarketplaceItemType.accessory:
          title = '${accessories[random.nextInt(accessories.length)]} ${carBrands[random.nextInt(carBrands.length)]}';
          price = 100 + random.nextDouble() * 4900; // 100 - 5000
          break;
        case MarketplaceItemType.service:
          title = '${services[random.nextInt(services.length)]} Auto Premium';
          price = 50 + random.nextDouble() * 950; // 50 - 1000
          break;
      }
      
      final item = MarketplaceItem(
        id: 'demo_$i',
        title: title,
        description: 'Descriere detaliata pentru $title. Produsul este in stare excelenta si garantat.',
        price: price,
        currency: 'EUR',
        images: imageUrls,
        type: itemType,
        sellerId: 'demo_seller_$i',
        sellerName: 'Vanzator Demo $i',
        location: locations[random.nextInt(locations.length)],
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        updatedAt: DateTime.now(),
        details: {'model': title, 'condition': 'excellent'},
        viewCount: random.nextInt(1000),
        averageRating: 3.5 + random.nextDouble() * 1.5, // 3.5 - 5.0
        reviewCount: random.nextInt(20),
        tags: ['demo', 'test'],
        accessoryCategory: itemType == MarketplaceItemType.accessory 
            ? AccessoryCategory.values[random.nextInt(AccessoryCategory.values.length)]
            : null,
        serviceCategory: itemType == MarketplaceItemType.service 
            ? ServiceCategory.values[random.nextInt(ServiceCategory.values.length)]
            : null,
      );
      
      demoItems.add(item);
    }
    
    print('RecommendationService: Generated ${demoItems.length} demo items');
    return demoItems;
  }

  /// Refresh recommendations (clear cache if implemented)
  static Future<void> refreshRecommendations() async {
    // Clear cache to force refresh
    _cachedRecommendations = null;
    _cachedTrending = null;
    _lastCacheTime = null;
    
    if (kDebugMode) {
      print('Refreshing recommendations... Cache cleared.');
    }
  }
  
  /// Clear cache manually if needed
  static void clearCache() {
    _cachedRecommendations = null;
    _cachedTrending = null;
    _lastCacheTime = null;
  }
}
