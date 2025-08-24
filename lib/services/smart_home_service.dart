import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_item.dart';
import '../models/subscription.dart';
import '../services/country_service.dart';
import '../services/user_behavior_service.dart';
import '../services/monetization_service.dart';
import 'dart:math' as math;

class SmartHomeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get intelligent home feed with mixed content
  /// Algorithm: Boosts + Relevant + Random for diversity
  static Future<List<MarketplaceItem>> getSmartHomeFeed({int limit = 10}) async {
    try {
      print('SmartHomeService: Getting smart home feed...');
      
      final List<MarketplaceItem> homeFeed = [];
      final Set<String> usedItemIds = {};
      
      // 1. Get active boosts (Top Recomandare, Top Model) - 20% of feed or at least 1
      final boostCount = math.max(1, (limit * 0.2).round());
      final boostedItems = await _getBoostedItems(boostCount);
      for (final item in boostedItems) {
        if (!usedItemIds.contains(item.id)) {
          homeFeed.add(item);
          usedItemIds.add(item.id);
        }
      }
      print('SmartHomeService: Added ${boostedItems.length} boosted items');

      // 2. Get relevant items based on user interests - 50% of feed
      final relevantCount = (limit * 0.5).round();
      final relevantItems = await _getRelevantItems(relevantCount, usedItemIds);
      for (final item in relevantItems) {
        if (!usedItemIds.contains(item.id) && homeFeed.length < limit) {
          homeFeed.add(item);
          usedItemIds.add(item.id);
        }
      }
      print('SmartHomeService: Added ${relevantItems.length} relevant items');

      // 3. Fill remaining with random global items for diversity
      final remainingSlots = limit - homeFeed.length;
      if (remainingSlots > 0) {
        final randomItems = await _getRandomItems(remainingSlots, usedItemIds);
        homeFeed.addAll(randomItems);
        print('SmartHomeService: Added ${randomItems.length} random items');
      }

      // 4. If still not enough items, get any available items
      if (homeFeed.length < limit) {
        final anyItems = await _getAnyAvailableItems(limit - homeFeed.length, usedItemIds);
        homeFeed.addAll(anyItems);
        print('SmartHomeService: Added ${anyItems.length} additional items');
      }

      // 5. Smart shuffle - maintain boost priority but mix others
      final shuffledFeed = _smartShuffle(homeFeed, boostedItems.length);
      
      // 6. Apply boost information to all items
      final finalFeed = await _applyBoostsToItems(shuffledFeed);
      
      print('SmartHomeService: Final feed has ${finalFeed.length} items');
      return finalFeed;
      
    } catch (e) {
      print('SmartHomeService: Error getting smart home feed: $e');
      return [];
    }
  }

  /// Get items with active boosts (Top Recomandare, Top Model, etc.)
  static Future<List<MarketplaceItem>> _getBoostedItems(int limit) async {
    try {
      final boostedItems = <MarketplaceItem>[];
      
      // Query items with active boosts
      final snapshot = await _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .where('hasActiveBoost', isEqualTo: true)
          .orderBy('boostPriority', descending: true)
          .orderBy('boostStartDate', descending: true)
          .limit(limit * 2) // Get more to filter by boost expiry
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final item = MarketplaceItem.fromJson(doc.id, data);
          
          // Check if boost is still active
          if (_isBoostActive(data)) {
            // Calculate boost score for priority
            final boostScore = _calculateBoostScore(data);
            item.boostScore = boostScore;
            boostedItems.add(item);
            
            if (boostedItems.length >= limit) break;
          }
        } catch (e) {
          print('Error parsing boosted item ${doc.id}: $e');
        }
      }

      // Sort by boost score (highest first)
      boostedItems.sort((a, b) => (b.boostScore ?? 0).compareTo(a.boostScore ?? 0));
      
      return boostedItems;
    } catch (e) {
      print('Error getting boosted items: $e');
      return [];
    }
  }

  /// Get relevant items based on user preferences and location
  static Future<List<MarketplaceItem>> _getRelevantItems(int limit, Set<String> excludeIds) async {
    try {
      final relevantItems = <MarketplaceItem>[];
      
      // Get user's country and preferences
      final country = await CountryService.detectCurrentCountry();
      final countryCode = country?.code ?? 'RO';
      final preferences = await UserBehaviorService.getUserPreferences();
      
      // 70-80% from current country, rest global
      final localCount = (limit * 0.75).round();

      // Get local relevant items
      final localItems = await _getRelevantItemsByLocation(
        countryCode, localCount, excludeIds, preferences
      );
      relevantItems.addAll(localItems);

      // Fill remaining with global relevant items
      if (relevantItems.length < limit) {
        final remaining = limit - relevantItems.length;
        final globalItems = await _getRelevantItemsGlobal(
          remaining, {...excludeIds, ...relevantItems.map((e) => e.id)}, preferences
        );
        relevantItems.addAll(globalItems);
      }

      return relevantItems;
    } catch (e) {
      print('Error getting relevant items: $e');
      return [];
    }
  }

  /// Get relevant items from user's country
  static Future<List<MarketplaceItem>> _getRelevantItemsByLocation(
    String countryCode, int limit, Set<String> excludeIds, Map<String, dynamic> preferences
  ) async {
    try {
      var query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .where('location', isEqualTo: countryCode);

      // Add preference-based filtering if available
      if (preferences.isNotEmpty) {
        final preferredBrand = preferences['preferredBrand'] as String?;
        if (preferredBrand != null && preferredBrand.isNotEmpty) {
          // We'll filter by brand in the processing logic since brand is in details
        }
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Get more to filter
          .get();

      final items = <MarketplaceItem>[];
      for (final doc in snapshot.docs) {
        if (excludeIds.contains(doc.id)) continue;
        
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          
          // Calculate relevance score based on user behavior
          final relevanceScore = _calculateRelevanceScore(item, preferences);
          item.relevanceScore = relevanceScore;
          items.add(item);
          
          if (items.length >= limit) break;
        } catch (e) {
          print('Error parsing local relevant item ${doc.id}: $e');
        }
      }

      // Sort by relevance score
      items.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
      
      return items;
    } catch (e) {
      print('Error getting local relevant items: $e');
      return [];
    }
  }

  /// Get relevant items globally (not location-restricted)
  static Future<List<MarketplaceItem>> _getRelevantItemsGlobal(
    int limit, Set<String> excludeIds, Map<String, dynamic> preferences
  ) async {
    try {
      var query = _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true);

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit * 2)
          .get();

      final items = <MarketplaceItem>[];
      for (final doc in snapshot.docs) {
        if (excludeIds.contains(doc.id)) continue;
        
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          
          // Calculate relevance score
          final relevanceScore = _calculateRelevanceScore(item, preferences);
          if (relevanceScore > 0.3) { // Only include if somewhat relevant
            item.relevanceScore = relevanceScore;
            items.add(item);
          }
          
          if (items.length >= limit) break;
        } catch (e) {
          print('Error parsing global relevant item ${doc.id}: $e');
        }
      }

      // Sort by relevance score
      items.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
      
      return items;
    } catch (e) {
      print('Error getting global relevant items: $e');
      return [];
    }
  }

  /// Get random diverse items for feed diversity
  static Future<List<MarketplaceItem>> _getRandomItems(int limit, Set<String> excludeIds) async {
    try {
      // Get recent items (last 7 days) for freshness
      final cutoffDate = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
      
      final snapshot = await _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: cutoffDate)
          .limit(limit * 4) // Get more for randomization
          .get();

      final allItems = <MarketplaceItem>[];
      for (final doc in snapshot.docs) {
        if (excludeIds.contains(doc.id)) continue;
        
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          allItems.add(item);
        } catch (e) {
          print('Error parsing random item ${doc.id}: $e');
        }
      }

      // Shuffle and take random selection
      allItems.shuffle();
      return allItems.take(limit).toList();
      
    } catch (e) {
      print('Error getting random items: $e');
      return [];
    }
  }

  /// Get any available items when other methods don't return enough
  static Future<List<MarketplaceItem>> _getAnyAvailableItems(int limit, Set<String> excludeIds) async {
    try {
      final snapshot = await _firestore
          .collection('marketplace')
          .where('isActive', isEqualTo: true)
          .limit(limit * 3) // Get more for filtering
          .get();

      final allItems = <MarketplaceItem>[];
      for (final doc in snapshot.docs) {
        if (excludeIds.contains(doc.id)) continue;
        
        try {
          final item = MarketplaceItem.fromJson(doc.id, doc.data());
          allItems.add(item);
          
          if (allItems.length >= limit) break;
        } catch (e) {
          print('Error parsing available item ${doc.id}: $e');
        }
      }

      return allItems;
      
    } catch (e) {
      print('Error getting any available items: $e');
      return [];
    }
  }

  /// Smart shuffle that maintains boost priority but mixes other content
  static List<MarketplaceItem> _smartShuffle(List<MarketplaceItem> items, int boostCount) {
    if (items.length <= boostCount) return items;

    // Separate boosted and non-boosted items
    final boosted = items.take(boostCount).toList();
    final others = items.skip(boostCount).toList();
    
    // Shuffle non-boosted items
    others.shuffle();
    
    // Create final list with strategic placement
    final finalList = <MarketplaceItem>[];
    int boostIndex = 0;
    int otherIndex = 0;
    
    for (int i = 0; i < items.length; i++) {
      // Place boosts at strategic positions (1st, 6th, etc.)
      if ((i == 0 || (i + 1) % 5 == 1) && boostIndex < boosted.length) {
        finalList.add(boosted[boostIndex++]);
      } else if (otherIndex < others.length) {
        finalList.add(others[otherIndex++]);
      } else if (boostIndex < boosted.length) {
        finalList.add(boosted[boostIndex++]);
      }
    }
    
    return finalList;
  }

  /// Check if boost is still active
  static bool _isBoostActive(Map<String, dynamic> data) {
    try {
      final boostEndDate = data['boostEndDate'] as Timestamp?;
      if (boostEndDate == null) return false;
      
      return boostEndDate.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Calculate boost score for priority ordering
  static double _calculateBoostScore(Map<String, dynamic> data) {
    double score = 0.0;
    
    try {
      // Base score by boost type
      final boostTypes = List<String>.from(data['boostTypes'] ?? []);
      for (final boostType in boostTypes) {
        switch (boostType) {
          case 'top_recommendation':
            score += 100.0;
            break;
          case 'top_model':
            score += 80.0;
            break;
          case 'color_boost':
            score += 40.0;
            break;
          case 'animated_boost':
            score += 30.0;
            break;
          case 'label_boost':
            score += 20.0;
            break;
          case 'frame_boost':
            score += 15.0;
            break;
          default:
            score += 10.0;
        }
      }
      
      // Boost for recent activation
      final boostStartDate = data['boostStartDate'] as Timestamp?;
      if (boostStartDate != null) {
        final hoursSinceBoost = DateTime.now().difference(boostStartDate.toDate()).inHours;
        if (hoursSinceBoost < 24) {
          score += 20.0; // Fresh boost bonus
        }
      }
      
      // Boost for view count
      final totalViews = (data['totalViews'] ?? 0) as int;
      score += totalViews * 0.1;
      
    } catch (e) {
      print('Error calculating boost score: $e');
    }
    
    return score;
  }

  /// Apply active boosts to marketplace items
  static Future<List<MarketplaceItem>> _applyBoostsToItems(List<MarketplaceItem> items) async {
    try {
      final updatedItems = <MarketplaceItem>[];
      
      for (final item in items) {
        // Get active boosts for this item (including debug boosts)
        final activeBoosts = await MonetizationService.getCombinedActiveBoosts(item.id);
        
        if (activeBoosts.isNotEmpty) {
          // Create list of boost type names
          final boostTypes = <String>[];
          
          for (final boost in activeBoosts) {
            final boostTypeName = MonetizationService.getBoostTypeName(boost.type);
            boostTypes.add(boostTypeName);
          }
          
          // Update item details with boost information
          final updatedDetails = Map<String, dynamic>.from(item.details);
          updatedDetails['hasActiveBoost'] = true;
          updatedDetails['boostTypes'] = boostTypes;
          updatedDetails['boostCount'] = boostTypes.length;
          
          // Add boost metadata if available
          for (final boost in activeBoosts) {
            if (boost.metadata != null) {
              switch (boost.type) {
                case BoostType.coloredFrame:
                  updatedDetails['frameColor'] = boost.metadata!['frameColor'];
                  break;
                case BoostType.labelTags:
                  updatedDetails['labelType'] = boost.metadata!['labelType'];
                  break;
                default:
                  break;
              }
            }
          }
          
          // Create updated item with boost information
          final updatedItem = MarketplaceItem(
            id: item.id,
            title: item.title,
            description: item.description,
            price: item.price,
            currency: item.currency,
            type: item.type,
            sellerId: item.sellerId,
            sellerName: item.sellerName,
            sellerPhone: item.sellerPhone,
            images: item.images,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            isActive: item.isActive,
            details: updatedDetails,
            location: item.location,
            serviceCategory: item.serviceCategory,
            accessoryCategory: item.accessoryCategory,
            carId: item.carId,
            tags: item.tags,
            averageRating: item.averageRating,
            reviewCount: item.reviewCount,
            viewCount: item.viewCount,
            todayViewCount: item.todayViewCount,
          );
          
          updatedItems.add(updatedItem);
        } else {
          // No boosts, add item as-is
          updatedItems.add(item);
        }
      }
      
      return updatedItems;
    } catch (e) {
      print('Error applying boosts to items: $e');
      return items; // Return original items if error
    }
  }

  /// Calculate relevance score based on user preferences
  static double _calculateRelevanceScore(MarketplaceItem item, Map<String, dynamic> preferences) {
    double score = 0.0;
    
    try {
      // Brand match (check in details or tags)
      final preferredBrand = preferences['preferredBrand'] as String?;
      if (preferredBrand != null) {
        final brandKey = item.details['brand'] as String?;
        if (brandKey?.toLowerCase() == preferredBrand.toLowerCase()) {
          score += 50.0;
        }
        // Also check in tags
        for (final tag in item.tags) {
          if (tag.toLowerCase().contains(preferredBrand.toLowerCase())) {
            score += 30.0;
            break;
          }
        }
      }
      
      // Category match
      final preferredCategory = preferences['preferredCategory'] as String?;
      if (preferredCategory != null && item.type.toString().contains(preferredCategory)) {
        score += 40.0;
      }
      
      // Search terms match
      final searchTerms = List<String>.from(preferences['searchTerms'] ?? []);
      for (final term in searchTerms) {
        if (item.title.toLowerCase().contains(term.toLowerCase()) ||
            item.description.toLowerCase().contains(term.toLowerCase())) {
          score += 20.0;
        }
      }
      
      // Recently viewed similar items
      final recentlyViewed = List<String>.from(preferences['recentlyViewedCategories'] ?? []);
      if (recentlyViewed.contains(item.type.toString())) {
        score += 30.0;
      }
      
      // Price range preference
      final preferredPriceRange = preferences['preferredPriceRange'] as Map<String, dynamic>?;
      if (preferredPriceRange != null) {
        final minPrice = preferredPriceRange['min'] as double?;
        final maxPrice = preferredPriceRange['max'] as double?;
        if (minPrice != null && maxPrice != null) {
          if (item.price >= minPrice && item.price <= maxPrice) {
            score += 25.0;
          }
        }
      }
      
      // Freshness bonus
      final daysSinceCreated = DateTime.now().difference(item.createdAt).inDays;
      if (daysSinceCreated < 3) {
        score += 15.0; // New item bonus
      } else if (daysSinceCreated < 7) {
        score += 10.0; // Recent item bonus
      }
      
      // Normalize score to 0-1 range
      score = score / 200.0; // Max possible score is ~200
      score = math.min(1.0, score);
      
    } catch (e) {
      print('Error calculating relevance score: $e');
    }
    
    return score;
  }

  /// Get user interaction history for last 10 activities
  static Future<List<String>> getUserRecentInteractions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('marketplace_activity')
          .where('userId', isEqualTo: userId)
          .where('action', whereIn: ['item_viewed', 'item_searched'])
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['itemId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
          
    } catch (e) {
      print('Error getting user recent interactions: $e');
      return [];
    }
  }
}

// Extension to add scoring fields to MarketplaceItem
extension MarketplaceItemScoring on MarketplaceItem {
  static final Map<String, double> _boostScores = {};
  static final Map<String, double> _relevanceScores = {};
  
  double? get boostScore => _boostScores[id];
  set boostScore(double? score) => score != null ? _boostScores[id] = score : _boostScores.remove(id);
  
  double? get relevanceScore => _relevanceScores[id];
  set relevanceScore(double? score) => score != null ? _relevanceScores[id] = score : _relevanceScores.remove(id);
}
