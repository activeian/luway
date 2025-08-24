import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';

class CarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'cars';

  static Future<String> addCar(Car car) async {
    try {
      DocumentReference doc = await _firestore.collection(_collection).add(car.toJson());
      String carId = doc.id;
      
      // If car is for sale and visible in marketplace, create marketplace listing
      if (car.isForSale && car.isVisibleInMarketplace) {
        await _createMarketplaceListing(carId, car);
      }
      
      return carId;
    } catch (e) {
      print('Error adding car: $e');
      throw Exception('Failed to add car');
    }
  }

  static Future<void> updateCar(String carId, Car car) async {
    try {
      print('🔄 Updating car $carId with new data...');
      await _firestore.collection(_collection).doc(carId).update(car.toJson());
      print('✅ Car $carId updated in database');
      
      // Handle marketplace listing based on car status
      if (car.isForSale && car.isVisibleInMarketplace) {
        print('🛒 Car is for sale and visible in marketplace, checking listing...');
        // Check if marketplace listing exists
        final marketplaceQuery = await _firestore
            .collection('marketplace')
            .where('carId', isEqualTo: carId)
            .get();
            
        if (marketplaceQuery.docs.isEmpty) {
          print('📝 No marketplace listing found, creating new one...');
          // Create new marketplace listing
          await _createMarketplaceListing(carId, car);
        } else {
          print('🔄 Marketplace listing found, syncing changes...');
          // Update existing marketplace listing
          await _syncCarToMarketplace(carId, car);
        }
      } else {
        print('🚫 Car not for sale or not visible, deactivating marketplace listing...');
        // Deactivate marketplace listing if car is not for sale or not visible
        await _deactivateMarketplaceListing(carId);
      }
    } catch (e) {
      print('❌ Error updating car: $e');
      throw Exception('Failed to update car');
    }
  }

  static Future<void> _syncCarToMarketplace(String carId, Car car) async {
    try {
      print('🔄 Starting sync for car $carId to marketplace...');
      print('📋 Car details: ${car.brand} ${car.model} (${car.year})');
      print('📸 Car images: ${car.images?.length ?? 0} images');
      
      // Query for ALL marketplace listings (both active and inactive) for this car
      final marketplaceQuery = await _firestore
          .collection('marketplace')
          .where('carId', isEqualTo: carId)
          .get(); // Removed the isActive filter to include inactive listings too

      print('🔍 Found ${marketplaceQuery.docs.length} marketplace listings for car $carId');

      if (marketplaceQuery.docs.isNotEmpty) {
        print('🚀 Syncing car $carId to ${marketplaceQuery.docs.length} marketplace listings...');
        
        for (final doc in marketplaceQuery.docs) {
          // Update marketplace item with new car data
          final updateData = <String, dynamic>{
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          };

          // Update title
          String newTitle = '${car.brand} ${car.model}';
          if (car.year != null) {
            newTitle += ' (${car.year})';
          }
          updateData['title'] = newTitle;

          // Update details with new car information
          final currentDetails = Map<String, dynamic>.from(doc.data()['details'] ?? {});
          currentDetails['brand'] = car.brand;
          currentDetails['model'] = car.model;
          currentDetails['plateNumber'] = car.plateNumber;
          currentDetails['countryCode'] = car.countryCode;
          if (car.year != null) currentDetails['year'] = car.year;
          if (car.mileage != null) currentDetails['mileage'] = car.mileage;
          if (car.fuelType != null) currentDetails['fuelType'] = car.fuelType;
          if (car.transmission != null) currentDetails['transmission'] = car.transmission;
          if (car.engine != null) currentDetails['engine'] = car.engine;
          if (car.color != null) currentDetails['color'] = car.color;
          updateData['details'] = currentDetails;

          // Update price if changed
          if (car.price != null) {
            updateData['price'] = car.price;
          }

          // Update description with new car details
          String newDescription = 'Car for sale in excellent condition.\n\n';
          if (car.year != null) newDescription += 'Year: ${car.year}\n';
          if (car.mileage != null) newDescription += 'Mileage: ${car.mileage} km\n';
          if (car.fuelType != null) newDescription += 'Fuel Type: ${car.fuelType}\n';
          if (car.transmission != null) newDescription += 'Transmission: ${car.transmission}\n';
          if (car.color != null) newDescription += 'Color: ${car.color}\n';
          if (car.engine != null) newDescription += 'Engine: ${car.engine}\n';
          newDescription += 'License Plate: ${car.plateNumber}\n';
          if (car.description != null && car.description!.isNotEmpty) {
            newDescription += '\nAdditional Info: ${car.description}\n';
          }
          updateData['description'] = newDescription;

          // Always update images (including empty list if images were removed)
          updateData['images'] = car.images ?? [];

          // Update location and phone from car
          if (car.location != null) updateData['location'] = car.location;
          if (car.phone != null) updateData['sellerPhone'] = car.phone;

          // Apply updates to marketplace item
          print('🔄 Updating marketplace listing ${doc.id}...');
          print('📝 Title: $newTitle');
          print('📸 Images: ${car.images?.length ?? 0} images');
          print('💰 Price: ${car.price ?? 'N/A'}');
          
          await _firestore
              .collection('marketplace')
              .doc(doc.id)
              .update(updateData);
          
          print('✅ Successfully synced car data to marketplace listing ${doc.id}');
          print('� Updated fields: ${updateData.keys.toList()}');
        }
        
        print('🎉 Completed syncing car $carId to ${marketplaceQuery.docs.length} marketplace listings');
      } else {
        print('⚠️ No marketplace listings found for car $carId - skipping sync');
      }
    } catch (e) {
      print('❌ Error syncing car to marketplace: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      // Don't throw error since car update was successful
    }
  }

  static Future<void> _createMarketplaceListing(String carId, Car car) async {
    try {
      print('Creating marketplace listing for car $carId...');
      
      // Build comprehensive title
      String title = '${car.brand} ${car.model}';
      if (car.year != null) title += ' (${car.year})';

      // Build comprehensive description
      String description = 'Mașină de vânzare în stare excelentă.\n\n';
      if (car.year != null) description += 'An: ${car.year}\n';
      if (car.mileage != null) description += 'Kilometraj: ${car.mileage} km\n';
      if (car.fuelType != null) description += 'Combustibil: ${car.fuelType}\n';
      if (car.transmission != null) description += 'Transmisie: ${car.transmission}\n';
      if (car.color != null) description += 'Culoare: ${car.color}\n';
      if (car.engine != null) description += 'Motor: ${car.engine}\n';
      if (car.power != null) description += 'Putere: ${car.power} CP\n';
      description += 'Număr înmatriculare: ${car.plateNumber}\n';
      if (car.notes != null && car.notes!.isNotEmpty) {
        description += '\nObservații: ${car.notes}\n';
      }
      if (car.description != null && car.description!.isNotEmpty) {
        description += '\n${car.description}';
      }

      // Create marketplace item data
      final user = FirebaseAuth.instance.currentUser;
      final marketplaceData = {
        'title': title,
        'description': description,
        'price': car.price ?? 0.0,
        'currency': 'EUR',
        'type': 'car',
        'sellerId': car.ownerId,
        'sellerName': user?.displayName ?? 'User',
        'sellerPhone': car.phone,
        'images': car.images ?? [],
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isActive': true,
        'details': {
          // Basic car info
          'country': car.countryCode,
          'plateNumber': car.plateNumber,
          'brand': car.brand,
          'model': car.model,
          'year': car.year,
          'mileage': car.mileage,
          
          // Technical specifications
          'engine': car.engine,
          'power': car.power,
          'fuelType': car.fuelType,
          'transmission': car.transmission,
          'bodyType': car.bodyType,
          'color': car.color,
          'doors': car.doors,
          'condition': car.condition,
          
          // Additional information
          'vin': car.vin,
          'previousOwners': car.previousOwners,
          'hasServiceHistory': car.hasServiceHistory,
          'hasAccidentHistory': car.hasAccidentHistory,
          'notes': car.notes,
          
          // Status and sale options
          'isForSale': car.isForSale,
          'urgencyLevel': car.urgencyLevel,
          'isPriceNegotiable': car.isPriceNegotiable,
          'isVisibleInMarketplace': car.isVisibleInMarketplace,
          'allowContactFromBuyers': car.allowContactFromBuyers,
          
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
        'location': car.location,
        'carId': carId, // Reference to car from My Garage
        'tags': [
          car.brand.toLowerCase(),
          car.model.toLowerCase(),
          if (car.year != null) car.year.toString(),
          if (car.fuelType != null) car.fuelType!.toLowerCase(),
          if (car.bodyType != null) car.bodyType!.toLowerCase(),
          if (car.transmission != null) car.transmission!.toLowerCase(),
          car.countryCode.toLowerCase(),
        ].where((tag) => tag.isNotEmpty).toList(),
        'averageRating': 0.0,
        'reviewCount': 0,
        'viewCount': 0,
        'todayViewCount': 0,
      };

      await _firestore.collection('marketplace').add(marketplaceData);
      print('✅ Successfully created marketplace listing for car $carId');
    } catch (e) {
      print('❌ Error creating marketplace listing: $e');
      // Don't throw error since car creation was successful
    }
  }

  static Future<void> deleteCar(String carId) async {
    try {
      await _firestore.collection(_collection).doc(carId).delete();
      
      // Also deactivate marketplace listing if exists
      await _deactivateMarketplaceListing(carId);
    } catch (e) {
      print('Error deleting car: $e');
      throw Exception('Failed to delete car');
    }
  }

  static Future<void> _deactivateMarketplaceListing(String carId) async {
    try {
      final marketplaceQuery = await _firestore
          .collection('marketplace')
          .where('carId', isEqualTo: carId)
          .where('isActive', isEqualTo: true)
          .get();

      if (marketplaceQuery.docs.isNotEmpty) {
        print('Deactivating marketplace listings for deleted car $carId...');
        
        for (final doc in marketplaceQuery.docs) {
          await _firestore
              .collection('marketplace')
              .doc(doc.id)
              .update({
                'isActive': false,
                'updatedAt': Timestamp.fromDate(DateTime.now()),
              });
          
          print('Deactivated marketplace listing ${doc.id}');
        }
      }
    } catch (e) {
      print('Error deactivating marketplace listing: $e');
      // Don't throw error since car deletion was successful
    }
  }

  static Future<Car?> getCarById(String carId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(carId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Car.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting car: $e');
      return null;
    }
  }

  static Future<List<Car>> searchCarsByPlate(String plateQuery, {String? currentCountryCode}) async {
    try {
      if (plateQuery.length < 2) return [];

      // Convert query to uppercase for matching
      String upperQuery = plateQuery.toUpperCase();
      
      // First search in current country if provided
      List<Car> results = [];
      
      if (currentCountryCode != null) {
        QuerySnapshot currentCountryQuery = await _firestore
            .collection(_collection)
            .where('countryCode', isEqualTo: currentCountryCode)
            .where('plateNumber', isGreaterThanOrEqualTo: upperQuery)
            .where('plateNumber', isLessThanOrEqualTo: '$upperQuery\uf8ff')
            .limit(10)
            .get();

        for (var doc in currentCountryQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          results.add(Car.fromJson(data));
        }
      }

      // Then search in other countries if we need more results
      if (results.length < 10) {
        Query query = _firestore
            .collection(_collection)
            .where('plateNumber', isGreaterThanOrEqualTo: upperQuery)
            .where('plateNumber', isLessThanOrEqualTo: '$upperQuery\uf8ff')
            .limit(20);

        if (currentCountryCode != null) {
          query = query.where('countryCode', isNotEqualTo: currentCountryCode);
        }

        QuerySnapshot globalQuery = await query.get();

        for (var doc in globalQuery.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          Car car = Car.fromJson(data);
          
          // Avoid duplicates
          if (!results.any((c) => c.id == car.id)) {
            results.add(car);
          }
        }
      }

      // Sort results: current country first, then by plate number
      results.sort((a, b) {
        if (currentCountryCode != null) {
          if (a.countryCode == currentCountryCode && b.countryCode != currentCountryCode) {
            return -1;
          }
          if (b.countryCode == currentCountryCode && a.countryCode != currentCountryCode) {
            return 1;
          }
        }
        return a.plateNumber.compareTo(b.plateNumber);
      });

      return results.take(10).toList();
    } catch (e) {
      print('Error searching cars: $e');
      return [];
    }
  }

  /// Sync all user's cars to their marketplace listings
  /// This can be called to fix any out-of-sync data
  static Future<void> syncAllUserCarsToMarketplace(String userId) async {
    try {
      print('Syncing all cars for user $userId to marketplace...');
      
      // Get all user's cars
      final userCars = await getUserCars(userId);
      
      for (final car in userCars) {
        await _syncCarToMarketplace(car.id, car);
      }
      
      print('Synced ${userCars.length} cars to marketplace');
    } catch (e) {
      print('Error syncing cars to marketplace: $e');
    }
  }

  static Future<List<Car>> getUserCars(String userId) async {
    try {
      print('CarService: Getting cars for user: $userId');
      QuerySnapshot query = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('CarService: Found ${query.docs.length} cars for user');
      
      List<Car> cars = query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        print('CarService: Processing car ${doc.id}: ${data['title'] ?? 'No title'}');
        return Car.fromJson(data);
      }).toList();
      
      print('CarService: Returning ${cars.length} cars');
      return cars;
    } catch (e) {
      print('Error getting user cars: $e');
      return [];
    }
  }

  static Future<List<Car>> getCarsForSale({String? countryCode, int limit = 20}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('isForSale', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (countryCode != null) {
        query = query.where('countryCode', isEqualTo: countryCode);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Car.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting cars for sale: $e');
      return [];
    }
  }

  static Future<bool> isPlateNumberExists(String plateNumber, String countryCode) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(_collection)
          .where('plateNumber', isEqualTo: plateNumber.toUpperCase())
          .where('countryCode', isEqualTo: countryCode)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking plate number: $e');
      return false;
    }
  }

  static Stream<List<Car>> getCarsStream({String? countryCode}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (countryCode != null) {
      query = query.where('countryCode', isEqualTo: countryCode);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Car.fromJson(data);
      }).toList();
    });
  }

  static Future<List<Car>> searchCars(String searchQuery) async {
    try {
      final String query = searchQuery.toLowerCase().trim();
      
      // Get all cars
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .get();

      // Filter cars locally based on search query
      List<Car> allCars = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Car.fromJson(data);
      }).toList();

      // Filter cars that match the search query
      List<Car> filteredCars = allCars.where((car) {
        final plateNumber = car.plateNumber.toLowerCase();
        final brand = car.brand.toLowerCase();
        final model = car.model.toLowerCase();
        
        return plateNumber.contains(query) ||
               brand.contains(query) ||
               model.contains(query);
      }).toList();

      return filteredCars;
    } catch (e) {
      print('Error searching cars: $e');
      return [];
    }
  }

  /// Check if a car is already listed in marketplace
  static Future<bool> isCarInMarketplace(String carId) async {
    try {
      final marketplaceQuery = await _firestore
          .collection('marketplace')
          .where('carId', isEqualTo: carId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return marketplaceQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking marketplace status: $e');
      return false;
    }
  }

  /// Get marketplace listing info for a car
  static Future<String?> getMarketplaceStatus(String carId) async {
    try {
      final marketplaceQuery = await _firestore
          .collection('marketplace')
          .where('carId', isEqualTo: carId)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (marketplaceQuery.docs.isNotEmpty) {
        final doc = marketplaceQuery.docs.first;
        final data = doc.data();
        final title = data['title'] ?? 'Unknown car';
        final price = data['price'] ?? 0;
        return 'This car is already listed in marketplace as "$title" for $price EUR';
      }
      return null;
    } catch (e) {
      print('Error checking marketplace status: $e');
      return null;
    }
  }
}
