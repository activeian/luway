import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String plateNumber;
  final String countryCode;
  final String brand;
  final String model;
  final bool isForSale;
  final String ownerId;
  final DateTime createdAt;

  // Optional sale details
  final double? price;
  final String? description;
  final int? year;
  final int? mileage;
  final String? fuelType;
  final String? transmission;
  final String? engine;
  final String? color;
  final List<String>? images;
  final String? location;
  final String? phone;

  // Extended car details from comprehensive form
  final String? bodyType;
  final String? doors;
  final String? condition;
  final int? power;
  final String? vin;
  final int? previousOwners;
  final bool hasServiceHistory;
  final bool hasAccidentHistory;
  final String? urgencyLevel;
  final bool isPriceNegotiable;
  final bool isVisibleInMarketplace;
  final bool allowContactFromBuyers;
  final String? notes;

  // Safety equipment
  final bool hasABS;
  final bool hasESP;
  final bool hasAirbags;
  final bool hasAlarm;

  // Comfort equipment
  final bool hasAirConditioning;
  final bool hasHeatedSeats;
  final bool hasNavigation;
  final bool hasBluetooth;
  final bool hasUSB;
  final bool hasLeatherSteering;

  // Exterior equipment
  final bool hasAlloyWheels;
  final bool hasSunroof;
  final bool hasXenonLights;
  final bool hasElectricMirrors;

  // Ownership verification
  final DateTime? lastOwnershipVerification;
  final DateTime? nextOwnershipVerification;

  const Car({
    required this.id,
    required this.plateNumber,
    required this.countryCode,
    required this.brand,
    required this.model,
    required this.isForSale,
    required this.ownerId,
    required this.createdAt,
    this.price,
    this.description,
    this.year,
    this.mileage,
    this.fuelType,
    this.transmission,
    this.engine,
    this.color,
    this.images,
    this.location,
    this.phone,
    // Extended car details
    this.bodyType,
    this.doors,
    this.condition,
    this.power,
    this.vin,
    this.previousOwners,
    this.hasServiceHistory = false,
    this.hasAccidentHistory = false,
    this.urgencyLevel,
    this.isPriceNegotiable = false,
    this.isVisibleInMarketplace = true,
    this.allowContactFromBuyers = true,
    this.notes,
    // Safety equipment
    this.hasABS = false,
    this.hasESP = false,
    this.hasAirbags = false,
    this.hasAlarm = false,
    // Comfort equipment
    this.hasAirConditioning = false,
    this.hasHeatedSeats = false,
    this.hasNavigation = false,
    this.hasBluetooth = false,
    this.hasUSB = false,
    this.hasLeatherSteering = false,
    // Exterior equipment
    this.hasAlloyWheels = false,
    this.hasSunroof = false,
    this.hasXenonLights = false,
    this.hasElectricMirrors = false,
    // Ownership verification
    this.lastOwnershipVerification,
    this.nextOwnershipVerification,
  });

  Map<String, dynamic> toJson() {
    return {
      'plateNumber': plateNumber,
      'countryCode': countryCode,
      'brand': brand,
      'model': model,
      'isForSale': isForSale,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt), // Use Firestore Timestamp
      'price': price,
      'description': description,
      'year': year,
      'mileage': mileage,
      'fuelType': fuelType,
      'transmission': transmission,
      'engine': engine,
      'color': color,
      'images': images,
      'location': location,
      'phone': phone,
      // Extended car details
      'bodyType': bodyType,
      'doors': doors,
      'condition': condition,
      'power': power,
      'vin': vin,
      'previousOwners': previousOwners,
      'hasServiceHistory': hasServiceHistory,
      'hasAccidentHistory': hasAccidentHistory,
      'urgencyLevel': urgencyLevel,
      'isPriceNegotiable': isPriceNegotiable,
      'isVisibleInMarketplace': isVisibleInMarketplace,
      'allowContactFromBuyers': allowContactFromBuyers,
      'notes': notes,
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
      // Ownership verification
      'lastOwnershipVerification': lastOwnershipVerification != null
          ? Timestamp.fromDate(lastOwnershipVerification!)
          : null,
      'nextOwnershipVerification': nextOwnershipVerification != null
          ? Timestamp.fromDate(nextOwnershipVerification!)
          : null,
    };
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      countryCode: json['countryCode'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      isForSale: json['isForSale'] ?? false,
      ownerId: json['ownerId'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String()),
      price: json['price']?.toDouble(),
      description: json['description'],
      year: json['year']?.toInt(),
      mileage: json['mileage']?.toInt(),
      fuelType: json['fuelType'],
      transmission: json['transmission'],
      engine: json['engine'],
      color: json['color'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      location: json['location'],
      phone: json['phone'],
      // Extended car details
      bodyType: json['bodyType'],
      doors: json['doors'],
      condition: json['condition'],
      power: json['power']?.toInt(),
      vin: json['vin'],
      previousOwners: json['previousOwners']?.toInt(),
      hasServiceHistory: json['hasServiceHistory'] ?? false,
      hasAccidentHistory: json['hasAccidentHistory'] ?? false,
      urgencyLevel: json['urgencyLevel'],
      isPriceNegotiable: json['isPriceNegotiable'] ?? false,
      isVisibleInMarketplace: json['isVisibleInMarketplace'] ?? true,
      allowContactFromBuyers: json['allowContactFromBuyers'] ?? true,
      notes: json['notes'],
      // Safety equipment
      hasABS: json['hasABS'] ?? false,
      hasESP: json['hasESP'] ?? false,
      hasAirbags: json['hasAirbags'] ?? false,
      hasAlarm: json['hasAlarm'] ?? false,
      // Comfort equipment
      hasAirConditioning: json['hasAirConditioning'] ?? false,
      hasHeatedSeats: json['hasHeatedSeats'] ?? false,
      hasNavigation: json['hasNavigation'] ?? false,
      hasBluetooth: json['hasBluetooth'] ?? false,
      hasUSB: json['hasUSB'] ?? false,
      hasLeatherSteering: json['hasLeatherSteering'] ?? false,
      // Exterior equipment
      hasAlloyWheels: json['hasAlloyWheels'] ?? false,
      hasSunroof: json['hasSunroof'] ?? false,
      hasXenonLights: json['hasXenonLights'] ?? false,
      hasElectricMirrors: json['hasElectricMirrors'] ?? false,
      // Ownership verification
      lastOwnershipVerification: json['lastOwnershipVerification'] is Timestamp
          ? (json['lastOwnershipVerification'] as Timestamp).toDate()
          : json['lastOwnershipVerification'] != null
              ? DateTime.parse(json['lastOwnershipVerification'])
              : null,
      nextOwnershipVerification: json['nextOwnershipVerification'] is Timestamp
          ? (json['nextOwnershipVerification'] as Timestamp).toDate()
          : json['nextOwnershipVerification'] != null
              ? DateTime.parse(json['nextOwnershipVerification'])
              : null,
    );
  }

  Car copyWith({
    String? id,
    String? plateNumber,
    String? countryCode,
    String? brand,
    String? model,
    bool? isForSale,
    String? ownerId,
    DateTime? createdAt,
    double? price,
    String? description,
    int? year,
    int? mileage,
    String? fuelType,
    String? transmission,
    String? engine,
    String? color,
    List<String>? images,
    String? location,
    String? phone,
    // Extended car details
    String? bodyType,
    String? doors,
    String? condition,
    int? power,
    String? vin,
    int? previousOwners,
    bool? hasServiceHistory,
    bool? hasAccidentHistory,
    String? urgencyLevel,
    bool? isPriceNegotiable,
    bool? isVisibleInMarketplace,
    bool? allowContactFromBuyers,
    String? notes,
    // Safety equipment
    bool? hasABS,
    bool? hasESP,
    bool? hasAirbags,
    bool? hasAlarm,
    // Comfort equipment
    bool? hasAirConditioning,
    bool? hasHeatedSeats,
    bool? hasNavigation,
    bool? hasBluetooth,
    bool? hasUSB,
    bool? hasLeatherSteering,
    // Exterior equipment
    bool? hasAlloyWheels,
    bool? hasSunroof,
    bool? hasXenonLights,
    bool? hasElectricMirrors,
    // Ownership verification
    DateTime? lastOwnershipVerification,
    DateTime? nextOwnershipVerification,
  }) {
    return Car(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      countryCode: countryCode ?? this.countryCode,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      isForSale: isForSale ?? this.isForSale,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
      description: description ?? this.description,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      engine: engine ?? this.engine,
      color: color ?? this.color,
      images: images ?? this.images,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      // Extended car details
      bodyType: bodyType ?? this.bodyType,
      doors: doors ?? this.doors,
      condition: condition ?? this.condition,
      power: power ?? this.power,
      vin: vin ?? this.vin,
      previousOwners: previousOwners ?? this.previousOwners,
      hasServiceHistory: hasServiceHistory ?? this.hasServiceHistory,
      hasAccidentHistory: hasAccidentHistory ?? this.hasAccidentHistory,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      isPriceNegotiable: isPriceNegotiable ?? this.isPriceNegotiable,
      isVisibleInMarketplace:
          isVisibleInMarketplace ?? this.isVisibleInMarketplace,
      allowContactFromBuyers:
          allowContactFromBuyers ?? this.allowContactFromBuyers,
      notes: notes ?? this.notes,
      // Safety equipment
      hasABS: hasABS ?? this.hasABS,
      hasESP: hasESP ?? this.hasESP,
      hasAirbags: hasAirbags ?? this.hasAirbags,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      // Comfort equipment
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      hasHeatedSeats: hasHeatedSeats ?? this.hasHeatedSeats,
      hasNavigation: hasNavigation ?? this.hasNavigation,
      hasBluetooth: hasBluetooth ?? this.hasBluetooth,
      hasUSB: hasUSB ?? this.hasUSB,
      hasLeatherSteering: hasLeatherSteering ?? this.hasLeatherSteering,
      // Exterior equipment
      hasAlloyWheels: hasAlloyWheels ?? this.hasAlloyWheels,
      hasSunroof: hasSunroof ?? this.hasSunroof,
      hasXenonLights: hasXenonLights ?? this.hasXenonLights,
      hasElectricMirrors: hasElectricMirrors ?? this.hasElectricMirrors,
      // Ownership verification
      lastOwnershipVerification:
          lastOwnershipVerification ?? this.lastOwnershipVerification,
      nextOwnershipVerification:
          nextOwnershipVerification ?? this.nextOwnershipVerification,
    );
  }
}
