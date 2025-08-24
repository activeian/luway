import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_item.dart';
import '../models/car.dart';
import '../models/subscription.dart';
import 'monetization_service.dart';
import 'item_deactivation_service.dart';

class MarketplaceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add car from My Garage to marketplace
  static Future<String> listCarFromGarage({
    required String carId,
    required double price,
    required String currency,
    required String description,
    String? location,
    List<String> additionalImages = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get car details from My Garage
    final carDoc = await _firestore.collection('cars').doc(carId).get();

    if (!carDoc.exists) throw Exception('Car not found');

    final car = Car.fromJson({
      'id': carDoc.id,
      ...carDoc.data()!,
    });

    // Create marketplace item
    final marketplaceItem = MarketplaceItem(
      id: '',
      title: '${car.brand} ${car.model} ${car.year}',
      description: description,
      price: price,
      currency: currency,
      type: MarketplaceItemType.car,
      sellerId: user.uid,
      sellerName: user.displayName ?? 'User',
      sellerPhone: user.phoneNumber,
      images: [...(car.images ?? []), ...additionalImages],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      details: {
        // Basic car info
        'brand': car.brand,
        'model': car.model,
        'year': car.year,
        'plateNumber': car.plateNumber,
        'countryCode': car.countryCode,
        'engine': car.engine,
        'transmission': car.transmission,
        'fuelType': car.fuelType,
        'mileage': car.mileage,
        'color': car.color,

        // Extended car details
        'bodyType': car.bodyType,
        'doors': car.doors,
        'condition': car.condition,
        'power': car.power,
        'vin': car.vin,
        'previousOwners': car.previousOwners,
        'hasServiceHistory': car.hasServiceHistory,
        'hasAccidentHistory': car.hasAccidentHistory,
        'notes': car.notes,
        'urgencyLevel': car.urgencyLevel,
        'isPriceNegotiable': car.isPriceNegotiable,

        // Safety equipment
        'hasABS': car.hasABS,
        'hasESP': car.hasESP,
        'hasAirbags': car.hasAirbags,
        'hasAlarm': car.hasAlarm,

        // Comfort equipment
        'hasAirConditioning': car.hasAirConditioning,
        'hasHeatedSeats': car.hasHeatedSeats,
        'hasNavigation': car.hasNavigation,
        'hasBluetooth': car.hasBluetooth,
        'hasUSB': car.hasUSB,
        'hasLeatherSteering': car.hasLeatherSteering,

        // Exterior equipment
        'hasAlloyWheels': car.hasAlloyWheels,
        'hasSunroof': car.hasSunroof,
        'hasXenonLights': car.hasXenonLights,
        'hasElectricMirrors': car.hasElectricMirrors,
      },
      location: location,
      carId: carId,
      tags: [
        car.brand.toLowerCase(),
        car.model.toLowerCase(),
        car.year.toString(),
        car.fuelType?.toLowerCase() ?? '',
        car.bodyType?.toLowerCase() ?? '',
        car.transmission?.toLowerCase() ?? '',
      ].where((tag) => tag.isNotEmpty).toList(),
    );

    final docRef = await _firestore
        .collection('marketplace')
        .add(marketplaceItem.toJson());

    return docRef.id;
  }

  // Add car directly to marketplace with comprehensive details
  static Future<String> addCarDirectToMarketplace({
    // Basic info
    required String country,
    required String plateNumber,
    required String brand,
    required String model,
    int? year,
    int? mileage,
    required double price,
    required String currency,

    // Technical specs
    String? engine,
    int? power,
    String? fuelType,
    String? transmission,
    String? bodyType,
    String? color,
    String? doors,
    String? condition,

    // Additional info
    String? vin,
    int? previousOwners,
    bool hasServiceHistory = false,
    bool hasAccidentHistory = false,
    String? notes,

    // Status options
    bool isForSale = true,
    String urgencyLevel = 'Normal',
    bool isPriceNegotiable = false,
    bool isVisibleInMarketplace = true,
    bool allowContactFromBuyers = true,

    // Equipment features
    bool hasABS = false,
    bool hasESP = false,
    bool hasAirbags = false,
    bool hasAlarm = false,
    bool hasAirConditioning = false,
    bool hasHeatedSeats = false,
    bool hasNavigation = false,
    bool hasBluetooth = false,
    bool hasUSB = false,
    bool hasLeatherSteering = false,
    bool hasAlloyWheels = false,
    bool hasSunroof = false,
    bool hasXenonLights = false,
    bool hasElectricMirrors = false,

    // Media and contact
    required List<String> images,
    String? location,
    String? phone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Build comprehensive title
    String title = '$brand $model';
    if (year != null) title += ' ($year)';

    // Build comprehensive description
    String description = 'Mașină de vânzare în stare excelentă.\n\n';
    if (year != null) description += 'An: $year\n';
    if (mileage != null) description += 'Kilometraj: $mileage km\n';
    if (fuelType != null) description += 'Combustibil: $fuelType\n';
    if (transmission != null) description += 'Transmisie: $transmission\n';
    if (color != null) description += 'Culoare: $color\n';
    if (engine != null) description += 'Motor: $engine\n';
    if (power != null) description += 'Putere: $power CP\n';
    description += 'Număr înmatriculare: $plateNumber\n';
    if (notes != null && notes.isNotEmpty) {
      description += '\nObservații: $notes\n';
    }

    // Create comprehensive marketplace item
    final marketplaceItem = MarketplaceItem(
      id: '',
      title: title,
      description: description,
      price: price,
      currency: currency,
      type: MarketplaceItemType.car,
      sellerId: user.uid,
      sellerName: user.displayName ?? 'User',
      sellerPhone: phone ?? user.phoneNumber,
      images: images,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: isVisibleInMarketplace,
      details: {
        // Basic car info
        'country': country,
        'plateNumber': plateNumber,
        'brand': brand,
        'model': model,
        'year': year,
        'mileage': mileage,

        // Technical specifications
        'engine': engine,
        'power': power,
        'fuelType': fuelType,
        'transmission': transmission,
        'bodyType': bodyType,
        'color': color,
        'doors': doors,
        'condition': condition,

        // Additional information
        'vin': vin,
        'previousOwners': previousOwners,
        'hasServiceHistory': hasServiceHistory,
        'hasAccidentHistory': hasAccidentHistory,
        'notes': notes,

        // Status and sale options
        'isForSale': isForSale,
        'urgencyLevel': urgencyLevel,
        'isPriceNegotiable': isPriceNegotiable,
        'isVisibleInMarketplace': isVisibleInMarketplace,
        'allowContactFromBuyers': allowContactFromBuyers,

        // Safety equipment
        'hasABS': hasABS,
        'hasESP': hasESP,
        'hasAirbags': hasAirbags,
        'hasAlarm': hasAlarm,

        // Comfort equipment
        'hasAirConditioning': hasAirConditioning,
        'hasHeatedSeats': hasHeatedSeats,
        'hasNavigation': hasNavigation,
        'hasBluetooth': hasBluetooth,
        'hasUSB': hasUSB,
        'hasLeatherSteering': hasLeatherSteering,

        // Exterior equipment
        'hasAlloyWheels': hasAlloyWheels,
        'hasSunroof': hasSunroof,
        'hasXenonLights': hasXenonLights,
        'hasElectricMirrors': hasElectricMirrors,
      },
      location: location,
      tags: [
        brand.toLowerCase(),
        model.toLowerCase(),
        if (year != null) year.toString(),
        if (fuelType != null) fuelType.toLowerCase(),
        if (bodyType != null) bodyType.toLowerCase(),
        if (transmission != null) transmission.toLowerCase(),
        country.toLowerCase(),
      ].where((tag) => tag.isNotEmpty).toList(),
    );

    final docRef = await _firestore
        .collection('marketplace')
        .add(marketplaceItem.toJson());

    return docRef.id;
  }

  // Add accessory (requires subscription)
  static Future<String> addAccessory({
    required String title,
    required String description,
    required double price,
    required String currency,
    required AccessoryCategory category,
    required List<String> images,
    String? location,
    List<String> tags = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // TODO: Check if user has subscription
    // final hasSubscription = await _checkUserSubscription(user.uid);
    // if (!hasSubscription) throw Exception('Subscription required');

    final item = MarketplaceItem(
      id: '',
      title: title,
      description: description,
      price: price,
      currency: currency,
      type: MarketplaceItemType.accessory,
      sellerId: user.uid,
      sellerName: user.displayName ?? 'User',
      sellerPhone: user.phoneNumber,
      images: images,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      details: {},
      location: location,
      accessoryCategory: category,
      tags: tags,
    );

    final docRef =
        await _firestore.collection('marketplace').add(item.toJson());

    return docRef.id;
  }

  // Add service (requires subscription)
  static Future<String> addService({
    required String title,
    required String description,
    required double price,
    required String currency,
    required ServiceCategory category,
    required List<String> images,
    String? location,
    List<String> tags = const [],
    Map<String, dynamic> serviceDetails = const {},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // TODO: Check if user has subscription
    // final hasSubscription = await _checkUserSubscription(user.uid);
    // if (!hasSubscription) throw Exception('Subscription required');

    final item = MarketplaceItem(
      id: '',
      title: title,
      description: description,
      price: price,
      currency: currency,
      type: MarketplaceItemType.service,
      sellerId: user.uid,
      sellerName: user.displayName ?? 'User',
      sellerPhone: user.phoneNumber,
      images: images,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      details: serviceDetails,
      location: location,
      serviceCategory: category,
      tags: tags,
    );

    final docRef =
        await _firestore.collection('marketplace').add(item.toJson());

    return docRef.id;
  }

  // Get marketplace items with filters and boost-based sorting
  static Stream<List<MarketplaceItem>> getMarketplaceItems({
    MarketplaceFilter? filter,
    int limit = 20,
  }) {
    // Trigger maintenance check asynchronously (don't wait for it)
    ItemDeactivationService.expireGracePeriodItems().catchError((e) {
      print('Warning: Failed to perform maintenance check: $e');
    });

    Query query = _firestore
        .collection('marketplace')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (filter != null) {
      if (filter.type != null) {
        query = query.where('type',
            isEqualTo: filter.type!.toString().split('.').last);
      }
      if (filter.serviceCategory != null) {
        query = query.where('serviceCategory',
            isEqualTo: filter.serviceCategory!.toString().split('.').last);
      }
      if (filter.accessoryCategory != null) {
        query = query.where('accessoryCategory',
            isEqualTo: filter.accessoryCategory!.toString().split('.').last);
      }
      if (filter.minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: filter.minPrice);
      }
      if (filter.maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: filter.maxPrice);
      }
      if (filter.location != null && filter.location!.isNotEmpty) {
        query = query.where('location', isEqualTo: filter.location);
      }
    }

    query = query.limit(limit * 2); // Get more to allow for boost sorting

    return query.snapshots().asyncMap((snapshot) async {
      var items = snapshot.docs
          .map((doc) => MarketplaceItem.fromJson(
              doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Apply complex filters on client side (since Firestore has limited query capabilities)
      if (filter != null) {
        items = _applyClientSideFilters(items, filter);
      }

      // Apply boost-based sorting
      items = await _sortItemsByBoosts(items);

      return items.take(limit).toList();
    });
  }

  // Apply complex filters that can't be done in Firestore queries
  static List<MarketplaceItem> _applyClientSideFilters(
      List<MarketplaceItem> items, MarketplaceFilter filter) {
    return items.where((item) {
      // Text search filter
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final searchLower = filter.searchQuery!.toLowerCase();
        final matchesSearch = item.title.toLowerCase().contains(searchLower) ||
            item.description.toLowerCase().contains(searchLower) ||
            item.tags.any((tag) => tag.toLowerCase().contains(searchLower)) ||
            item.details.values.any((value) =>
                value.toString().toLowerCase().contains(searchLower));
        if (!matchesSearch) return false;
      }

      // Car-specific filters (only apply to car items)
      if (item.type == MarketplaceItemType.car) {
        final details = item.details;

        // Country filter
        if (filter.country != null && filter.country!.isNotEmpty) {
          final itemCountry = details['country']?.toString() ?? '';
          if (!itemCountry
              .toLowerCase()
              .contains(filter.country!.toLowerCase())) return false;
        }

        // Brand filter
        if (filter.brand != null && filter.brand!.isNotEmpty) {
          final itemBrand = details['brand']?.toString() ?? '';
          if (!itemBrand.toLowerCase().contains(filter.brand!.toLowerCase()))
            return false;
        }

        // Model filter
        if (filter.model != null && filter.model!.isNotEmpty) {
          final itemModel = details['model']?.toString() ?? '';
          if (!itemModel.toLowerCase().contains(filter.model!.toLowerCase()))
            return false;
        }

        // Year filter
        if (filter.minYear != null || filter.maxYear != null) {
          final itemYear = details['year'] as int?;
          if (itemYear != null) {
            if (filter.minYear != null && itemYear < filter.minYear!)
              return false;
            if (filter.maxYear != null && itemYear > filter.maxYear!)
              return false;
          }
        }

        // Mileage filter
        if (filter.minMileage != null || filter.maxMileage != null) {
          final itemMileage = details['mileage'] as int?;
          if (itemMileage != null) {
            if (filter.minMileage != null && itemMileage < filter.minMileage!)
              return false;
            if (filter.maxMileage != null && itemMileage > filter.maxMileage!)
              return false;
          }
        }

        // Power filter
        if (filter.minPower != null || filter.maxPower != null) {
          final itemPower = details['power'] as int?;
          if (itemPower != null) {
            if (filter.minPower != null && itemPower < filter.minPower!)
              return false;
            if (filter.maxPower != null && itemPower > filter.maxPower!)
              return false;
          }
        }

        // Fuel type filter
        if (filter.fuelType != null && filter.fuelType!.isNotEmpty) {
          final itemFuelType = details['fuelType']?.toString() ?? '';
          if (itemFuelType.toLowerCase() != filter.fuelType!.toLowerCase())
            return false;
        }

        // Transmission filter
        if (filter.transmission != null && filter.transmission!.isNotEmpty) {
          final itemTransmission = details['transmission']?.toString() ?? '';
          if (itemTransmission.toLowerCase() !=
              filter.transmission!.toLowerCase()) return false;
        }

        // Body type filter
        if (filter.bodyType != null && filter.bodyType!.isNotEmpty) {
          final itemBodyType = details['bodyType']?.toString() ?? '';
          if (itemBodyType.toLowerCase() != filter.bodyType!.toLowerCase())
            return false;
        }

        // Color filter
        if (filter.color != null && filter.color!.isNotEmpty) {
          final itemColor = details['color']?.toString() ?? '';
          if (!itemColor.toLowerCase().contains(filter.color!.toLowerCase()))
            return false;
        }

        // Condition filter
        if (filter.condition != null && filter.condition!.isNotEmpty) {
          final itemCondition = details['condition']?.toString() ?? '';
          if (itemCondition.toLowerCase() != filter.condition!.toLowerCase())
            return false;
        }

        // Doors filter
        if (filter.doors != null && filter.doors!.isNotEmpty) {
          final itemDoors = details['doors']?.toString() ?? '';
          if (itemDoors != filter.doors) return false;
        }

        // Equipment filters
        if (filter.hasABS == true && details['hasABS'] != true) return false;
        if (filter.hasESP == true && details['hasESP'] != true) return false;
        if (filter.hasAirbags == true && details['hasAirbags'] != true)
          return false;
        if (filter.hasAirConditioning == true &&
            details['hasAirConditioning'] != true) return false;
        if (filter.hasNavigation == true && details['hasNavigation'] != true)
          return false;
        if (filter.hasHeatedSeats == true && details['hasHeatedSeats'] != true)
          return false;
        if (filter.hasAlarm == true && details['hasAlarm'] != true)
          return false;
        if (filter.hasBluetooth == true && details['hasBluetooth'] != true)
          return false;
        if (filter.hasUSB == true && details['hasUSB'] != true) return false;
        if (filter.hasLeatherSteering == true &&
            details['hasLeatherSteering'] != true) return false;
        if (filter.hasAlloyWheels == true && details['hasAlloyWheels'] != true)
          return false;
        if (filter.hasSunroof == true && details['hasSunroof'] != true)
          return false;
        if (filter.hasXenonLights == true && details['hasXenonLights'] != true)
          return false;
        if (filter.hasElectricMirrors == true &&
            details['hasElectricMirrors'] != true) return false;

        // Status filters
        if (filter.isForSale == true && details['isForSale'] != true)
          return false;
        if (filter.isPriceNegotiable == true &&
            details['isPriceNegotiable'] != true) return false;
        if (filter.hasServiceHistory == true &&
            details['hasServiceHistory'] != true) return false;
        if (filter.hasAccidentHistory == false &&
            details['hasAccidentHistory'] == true) return false;
      }

      return true;
    }).toList();
  }

  static Future<List<MarketplaceItem>> _sortItemsByBoosts(
      List<MarketplaceItem> items) async {
    final itemsWithBoosts = <MarketplaceItem, List<BoostType>>{};

    // Get boost info for each item
    for (final item in items) {
      final boosts = await MonetizationService.getItemActiveBoosts(item.id);
      final boostTypes = boosts.map((b) => b.type).toList();
      itemsWithBoosts[item] = boostTypes;
    }

    // Sort items based on boost priority
    items.sort((a, b) {
      final aBoosts = itemsWithBoosts[a] ?? [];
      final bBoosts = itemsWithBoosts[b] ?? [];

      // Priority order for boosts
      final boostPriority = {
        BoostType.topRecommended: 6,
        BoostType.topBrandModel: 5,
        BoostType.localBoost: 4,
        BoostType.pushNotification: 3,
        BoostType.renewAd: 2,
        BoostType.coloredFrame: 1,
      };

      int aMaxPriority = 0;
      int bMaxPriority = 0;

      for (final boost in aBoosts) {
        final priority = boostPriority[boost] ?? 0;
        if (priority > aMaxPriority) aMaxPriority = priority;
      }

      for (final boost in bBoosts) {
        final priority = boostPriority[boost] ?? 0;
        if (priority > bMaxPriority) bMaxPriority = priority;
      }

      if (aMaxPriority != bMaxPriority) {
        return bMaxPriority.compareTo(aMaxPriority); // Higher priority first
      }

      // If same boost priority, sort by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return items;
  }

  /// Delete a marketplace item permanently
  static Future<bool> deleteMarketplaceItem(String itemId) async {
    try {
      await _firestore.collection('marketplace').doc(itemId).delete();
      print('✅ Marketplace item $itemId deleted permanently');
      return true;
    } catch (e) {
      print('❌ Error deleting marketplace item $itemId: $e');
      return false;
    }
  }

  // Get user's marketplace items
  static Stream<List<MarketplaceItem>> getUserMarketplaceItems(String userId) {
    return _firestore
        .collection('marketplace')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarketplaceItem.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Get marketplace item by ID
  static Future<MarketplaceItem?> getMarketplaceItem(String itemId) async {
    final doc = await _firestore.collection('marketplace').doc(itemId).get();

    if (!doc.exists) return null;

    return MarketplaceItem.fromJson(doc.id, doc.data()!);
  }

  // Add review (simplified for testing)
  static Future<void> addReview({
    required String itemId,
    required double rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('MarketplaceService: Adding review for item $itemId');
    print('MarketplaceService: User: ${user.uid}, Rating: $rating');

    // Check if user already reviewed this item
    final existingReview = await _firestore
        .collection('marketplace')
        .doc(itemId)
        .collection('reviews')
        .where('reviewerId', isEqualTo: user.uid)
        .get();

    if (existingReview.docs.isNotEmpty) {
      throw Exception('You have already reviewed this item');
    }

    final reviewData = {
      'reviewerId': user.uid,
      'reviewerName': user.displayName ?? 'Anonymous User',
      'rating': rating,
      'comment': comment,
      'timestamp': DateTime.now(),
    };

    print('MarketplaceService: Review data: $reviewData');

    // Add review
    await _firestore
        .collection('marketplace')
        .doc(itemId)
        .collection('reviews')
        .add(reviewData);

    print('MarketplaceService: Review added successfully');

    // Update item's average rating
    await _updateItemRating(itemId);
  }

  // Get reviews for an item
  static Stream<List<MarketplaceReview>> getItemReviews(String itemId) {
    print('MarketplaceService: Getting reviews for item: $itemId');
    return _firestore
        .collection('marketplace')
        .doc(itemId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print('MarketplaceService: Found ${snapshot.docs.length} reviews');
      return snapshot.docs
          .map((doc) {
            try {
              final review = MarketplaceReview.fromJson(doc.id, doc.data());
              print('MarketplaceService: Review ${doc.id}: ${review.comment}');
              return review;
            } catch (e) {
              print('MarketplaceService: Error parsing review ${doc.id}: $e');
              return null;
            }
          })
          .where((review) => review != null)
          .cast<MarketplaceReview>()
          .toList();
    });
  }

  // Update marketplace item
  static Future<void> updateMarketplaceItem(
      String itemId, Map<String, dynamic> data) async {
    await _firestore.collection('marketplace').doc(itemId).update({
      ...data,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Sync car from garage to marketplace with all fields
  static Future<void> syncCarToMarketplace(
      String carId, String marketplaceItemId) async {
    try {
      // Get updated car details from My Garage
      final carDoc = await _firestore.collection('cars').doc(carId).get();

      if (!carDoc.exists) throw Exception('Car not found in garage');

      final car = Car.fromJson({
        'id': carDoc.id,
        ...carDoc.data()!,
      });

      // Prepare comprehensive update data
      final updateData = {
        'title': '${car.brand} ${car.model} ${car.year}',
        'images': car.images ?? [],
        'details': {
          // Basic car info
          'brand': car.brand,
          'model': car.model,
          'year': car.year,
          'plateNumber': car.plateNumber,
          'countryCode': car.countryCode,
          'engine': car.engine,
          'transmission': car.transmission,
          'fuelType': car.fuelType,
          'mileage': car.mileage,
          'color': car.color,

          // Extended car details
          'bodyType': car.bodyType,
          'doors': car.doors,
          'condition': car.condition,
          'power': car.power,
          'vin': car.vin,
          'previousOwners': car.previousOwners,
          'hasServiceHistory': car.hasServiceHistory,
          'hasAccidentHistory': car.hasAccidentHistory,
          'notes': car.notes,
          'urgencyLevel': car.urgencyLevel,
          'isPriceNegotiable': car.isPriceNegotiable,

          // Safety equipment
          'hasABS': car.hasABS,
          'hasESP': car.hasESP,
          'hasAirbags': car.hasAirbags,
          'hasAlarm': car.hasAlarm,

          // Comfort equipment
          'hasAirConditioning': car.hasAirConditioning,
          'hasHeatedSeats': car.hasHeatedSeats,
          'hasNavigation': car.hasNavigation,
          'hasBluetooth': car.hasBluetooth,
          'hasUSB': car.hasUSB,
          'hasLeatherSteering': car.hasLeatherSteering,

          // Exterior equipment
          'hasAlloyWheels': car.hasAlloyWheels,
          'hasSunroof': car.hasSunroof,
          'hasXenonLights': car.hasXenonLights,
          'hasElectricMirrors': car.hasElectricMirrors,
        },
        'tags': [
          car.brand.toLowerCase(),
          car.model.toLowerCase(),
          car.year.toString(),
          car.fuelType?.toLowerCase() ?? '',
          car.bodyType?.toLowerCase() ?? '',
          car.transmission?.toLowerCase() ?? '',
        ].where((tag) => tag.isNotEmpty).toList(),
      };

      // Update marketplace item
      await updateMarketplaceItem(marketplaceItemId, updateData);

      print(
          '✅ Successfully synced car $carId to marketplace item $marketplaceItemId');
    } catch (e) {
      print('❌ Error syncing car to marketplace: $e');
      throw e;
    }
  }

  // Delete marketplace item (deactivate)
  static Future<void> deactivateMarketplaceItem(String itemId) async {
    await ItemDeactivationService.deactivateItem(itemId,
        reason: 'Deactivated by user');
  }

  static Future<void> _updateItemRating(String itemId) async {
    final reviewsSnapshot = await _firestore
        .collection('marketplace')
        .doc(itemId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    final reviews = reviewsSnapshot.docs
        .map((doc) => MarketplaceReview.fromJson(doc.id, doc.data()))
        .toList();

    final totalRating =
        reviews.fold<double>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    await _firestore.collection('marketplace').doc(itemId).update({
      'averageRating': averageRating,
      'reviewCount': reviews.length,
    });
  }

  // Get service category display names
  static String getServiceCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.carWash:
        return 'Car Wash';
      case ServiceCategory.repair:
        return 'Repair';
      case ServiceCategory.maintenance:
        return 'Maintenance';
      case ServiceCategory.insurance:
        return 'Insurance';
      case ServiceCategory.parking:
        return 'Parking';
      case ServiceCategory.rental:
        return 'Rental';
      case ServiceCategory.inspection:
        return 'Inspection';
      case ServiceCategory.towing:
        return 'Towing';
      case ServiceCategory.fuel:
        return 'Fuel';
      case ServiceCategory.other:
        return 'Other';
    }
  }

  // Get accessory category display names
  static String getAccessoryCategoryName(AccessoryCategory category) {
    switch (category) {
      case AccessoryCategory.tires:
        return 'Tires';
      case AccessoryCategory.electronics:
        return 'Electronics';
      case AccessoryCategory.interior:
        return 'Interior';
      case AccessoryCategory.exterior:
        return 'Exterior';
      case AccessoryCategory.performance:
        return 'Performance';
      case AccessoryCategory.safety:
        return 'Safety';
      case AccessoryCategory.lighting:
        return 'Lighting';
      case AccessoryCategory.audio:
        return 'Audio';
      case AccessoryCategory.navigation:
        return 'Navigation';
      case AccessoryCategory.other:
        return 'Other';
    }
  }

  // Get user's marketplace items
  static Future<List<MarketplaceItem>> getUserItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return MarketplaceItem.fromJson(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('Error getting user items: $e');
      return [];
    }
  }

  // Create a boost for a marketplace item
  static Future<void> createBoost({
    required String itemId,
    required String boostType,
    required int duration,
    required double price,
    String? playStoreId,
    String? transactionId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Verify payment transaction if provided
      if (transactionId != null) {
        print('🔍 Verifying payment transaction: $transactionId');
        final isValidTransaction =
            await _verifyPaymentTransaction(transactionId, price);
        if (!isValidTransaction) {
          throw Exception(
              'Payment verification failed. Please contact support if payment was processed.');
        }
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: duration));

      // Create boost record
      final boostDoc = await _firestore.collection('boosts').add({
        'itemId': itemId,
        'userId': user.uid,
        'type': boostType,
        'price': price,
        'currency': 'USD',
        'duration': duration,
        'playStoreId': playStoreId,
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'isActive': true,
        'metadata': {
          'purchaseMethod': playStoreId != null ? 'in_app_purchase' : 'direct',
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      });

      // Update the marketplace item to show it has active boosts
      await _firestore.collection('marketplace').doc(itemId).update({
        'hasActiveBoosts': true,
        'lastBoostedAt': FieldValue.serverTimestamp(),
        'activeBoostTypes': FieldValue.arrayUnion([boostType]),
      });

      // Create transaction record for tracking
      if (transactionId != null) {
        await _firestore.collection('transactions').add({
          'userId': user.uid,
          'type': 'boost',
          'amount': price,
          'currency': 'USD',
          'status': 'completed',
          'transactionId': transactionId,
          'boostId': boostDoc.id,
          'itemId': itemId,
          'boostType': boostType,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print(
          '✅ Boost created successfully for item: $itemId (Duration: ${duration} days)');
    } catch (e) {
      print('❌ Error creating boost: $e');
      throw Exception('Failed to create boost: $e');
    }
  }

  // Verify payment transaction (mock implementation - should integrate with actual payment verification)
  static Future<bool> _verifyPaymentTransaction(
      String transactionId, double expectedAmount) async {
    try {
      // Check if transaction already exists
      final existingTransaction = await _firestore
          .collection('transactions')
          .where('transactionId', isEqualTo: transactionId)
          .get();

      if (existingTransaction.docs.isNotEmpty) {
        print('⚠️ Transaction already processed: $transactionId');
        return false;
      }

      // TODO: Implement actual payment verification with Google Play/App Store
      // For now, return true to allow testing
      print('✅ Payment verification passed for transaction: $transactionId');
      return true;
    } catch (e) {
      print('❌ Payment verification failed: $e');
      return false;
    }
  }

  // Get active boosts for an item
  static Future<List<Map<String, dynamic>>> getActiveBoosts(
      String itemId) async {
    try {
      print('🔍 Getting active boosts for item: $itemId');

      final snapshot = await _firestore
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .get();

      print('📊 Found ${snapshot.docs.length} total boosts for item $itemId');

      final activeBoosts = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📝 Boost document ${doc.id}: $data');

        final isActive = data['isActive'] as bool? ?? false;
        final expiresAt = data['expiresAt'];

        // Handle both Timestamp and DateTime
        DateTime? expiryDate;
        if (expiresAt is Timestamp) {
          expiryDate = expiresAt.toDate();
        } else if (expiresAt is DateTime) {
          expiryDate = expiresAt;
        }

        print('🕐 Boost ${doc.id}: active=$isActive, expires=$expiryDate');

        if (isActive && expiryDate != null && expiryDate.isAfter(now)) {
          final boostData = {
            'id': doc.id,
            ...data,
            'expiresAt': expiryDate, // Normalize to DateTime
          };
          activeBoosts.add(boostData);
          print('✅ Added active boost: ${data['type']}');
        } else {
          print('❌ Boost not active or expired');
        }
      }

      print('🎯 Found ${activeBoosts.length} active boosts for item $itemId');
      return activeBoosts;
    } catch (e) {
      print('❌ Error getting active boosts: $e');
      return [];
    }
  }

  // Toggle boost activation
  static Future<void> toggleBoost(String boostId, bool isActive) async {
    try {
      await _firestore.collection('boosts').doc(boostId).update({
        'isActive': isActive,
        'toggledAt': FieldValue.serverTimestamp(),
      });

      print('Boost $boostId toggled to: $isActive');
    } catch (e) {
      print('Error toggling boost: $e');
      throw Exception('Failed to toggle boost: $e');
    }
  }

  // Get boost statistics for user
  static Future<Map<String, int>> getUserBoostStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('boosts')
          .where('userId', isEqualTo: userId)
          .get();

      int total = snapshot.docs.length;
      int active = snapshot.docs.where((doc) {
        final data = doc.data();
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        return data['isActive'] == true && expiresAt.isAfter(DateTime.now());
      }).length;

      return {
        'total': total,
        'active': active,
        'expired': total - active,
      };
    } catch (e) {
      print('Error getting boost stats: $e');
      return {'total': 0, 'active': 0, 'expired': 0};
    }
  }

  // Get active boost types for an item (for visual effects)
  static Future<List<String>> getActiveBoostTypes(String itemId) async {
    try {
      print('🔍 Getting active boost types for item: $itemId');

      final snapshot = await _firestore
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .get();

      print('📊 Found ${snapshot.docs.length} total boosts for item $itemId');

      final activeBoosts = <String>[];
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📝 Boost data: $data');

        final isActive = data['isActive'] as bool? ?? false;
        final expiresAt = data['expiresAt'];
        final endDate = data['endDate']; // Legacy field

        // Handle both expiresAt and endDate fields, and both Timestamp and DateTime
        DateTime? expiryDate;
        if (expiresAt != null) {
          if (expiresAt is Timestamp) {
            expiryDate = expiresAt.toDate();
          } else if (expiresAt is DateTime) {
            expiryDate = expiresAt;
          }
        } else if (endDate != null) {
          if (endDate is Timestamp) {
            expiryDate = endDate.toDate();
          } else if (endDate is DateTime) {
            expiryDate = endDate;
          }
        }

        print('🕐 Boost ${doc.id}: active=$isActive, expires=$expiryDate');

        // Check if boost is active and not expired
        bool isValidTime = true;
        if (expiryDate != null) {
          isValidTime = expiryDate.isAfter(now);
        }
        // For legacy boosts without expiry date, consider them valid if active

        if (isActive && isValidTime) {
          final boostType = data['type'] as String?;
          if (boostType != null) {
            activeBoosts.add(boostType);
            print('✅ Added active boost: $boostType');
          }
        } else {
          print(
              '❌ Boost not active or expired (active=$isActive, validTime=$isValidTime)');
        }
      }

      print('🎯 Active boost types for $itemId: $activeBoosts');
      return activeBoosts;
    } catch (e) {
      print('❌ Error getting active boost types: $e');
      return [];
    }
  }
}
