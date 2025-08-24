import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketplaceItemType {
  car,
  accessory,
  service,
}

enum ServiceCategory {
  carWash,
  repair,
  maintenance,
  insurance,
  parking,
  rental,
  inspection,
  towing,
  fuel,
  other,
}

enum AccessoryCategory {
  tires,
  electronics,
  interior,
  exterior,
  performance,
  safety,
  lighting,
  audio,
  navigation,
  other,
}

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final MarketplaceItemType type;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? deactivatedAt; // When the item was deactivated
  final DateTime? graceExpiresAt; // When the 30-day grace period expires
  final bool isExpired; // Whether the grace period has expired
  final Map<String, dynamic> details;
  final String? location;
  final ServiceCategory? serviceCategory;
  final AccessoryCategory? accessoryCategory;
  final String? carId; // Reference to car from My Garage
  final List<String> tags;
  final double averageRating;
  final int reviewCount;
  final int viewCount;
  final int todayViewCount;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.deactivatedAt,
    this.graceExpiresAt,
    this.isExpired = false,
    required this.details,
    this.location,
    this.serviceCategory,
    this.accessoryCategory,
    this.carId,
    required this.tags,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.viewCount = 0,
    this.todayViewCount = 0,
  });

  factory MarketplaceItem.fromJson(String id, Map<String, dynamic> json) {
    return MarketplaceItem(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      type: MarketplaceItemType.values.firstWhere(
        (e) => e.toString() == 'MarketplaceItemType.${json['type']}',
        orElse: () => MarketplaceItemType.car,
      ),
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? '',
      sellerPhone: json['sellerPhone'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      deactivatedAt: (json['deactivatedAt'] as Timestamp?)?.toDate(),
      graceExpiresAt: (json['graceExpiresAt'] as Timestamp?)?.toDate(),
      isExpired: json['isExpired'] ?? false,
      details: json['details'] ?? {},
      location: json['location'],
      serviceCategory: json['serviceCategory'] != null
          ? ServiceCategory.values.firstWhere(
              (e) => e.toString() == 'ServiceCategory.${json['serviceCategory']}',
              orElse: () => ServiceCategory.other,
            )
          : null,
      accessoryCategory: json['accessoryCategory'] != null
          ? AccessoryCategory.values.firstWhere(
              (e) => e.toString() == 'AccessoryCategory.${json['accessoryCategory']}',
              orElse: () => AccessoryCategory.other,
            )
          : null,
      carId: json['carId'],
      tags: List<String>.from(json['tags'] ?? []),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      todayViewCount: json['todayViewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type.toString().split('.').last,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'deactivatedAt': deactivatedAt != null ? Timestamp.fromDate(deactivatedAt!) : null,
      'graceExpiresAt': graceExpiresAt != null ? Timestamp.fromDate(graceExpiresAt!) : null,
      'isExpired': isExpired,
      'details': details,
      'location': location,
      'serviceCategory': serviceCategory?.toString().split('.').last,
      'accessoryCategory': accessoryCategory?.toString().split('.').last,
      'carId': carId,
      'tags': tags,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'viewCount': viewCount,
      'todayViewCount': todayViewCount,
    };
  }

  // Helper methods for deactivation/reactivation logic
  bool get canBeReactivated {
    return !isActive && (graceExpiresAt?.isAfter(DateTime.now()) ?? false);
  }

  bool get isInGracePeriod {
    return !isActive && 
           deactivatedAt != null && 
           graceExpiresAt != null && 
           graceExpiresAt!.isAfter(DateTime.now());
  }

  int get daysUntilExpiry {
    if (graceExpiresAt == null) return 0;
    final now = DateTime.now();
    if (graceExpiresAt!.isBefore(now)) return 0;
    return graceExpiresAt!.difference(now).inDays;
  }

  String get statusText {
    if (isActive) return 'Active';
    if (isInGracePeriod) return 'Deactivated (${daysUntilExpiry} days to reactivate)';
    return 'Expired';
  }
}

class MarketplaceReview {
  final String id;
  final String itemId;
  final String reviewerId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool hasContacted; // User has contacted seller via chat/phone

  MarketplaceReview({
    required this.id,
    required this.itemId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.hasContacted,
  });

  factory MarketplaceReview.fromJson(String id, Map<String, dynamic> json) {
    return MarketplaceReview(
      id: id,
      itemId: json['itemId'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: (json['timestamp'] as Timestamp?)?.toDate() ?? 
                 (json['createdAt'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      hasContacted: json['hasContacted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'hasContacted': hasContacted,
    };
  }
}

class MarketplaceFilter {
  final MarketplaceItemType? type;
  final ServiceCategory? serviceCategory;
  final AccessoryCategory? accessoryCategory;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? searchQuery;
  final List<String> tags;
  
  // Car specific filters
  final String? country;
  final String? brand;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final String? fuelType;
  final String? transmission;
  final String? bodyType;
  final String? color;
  final String? condition;
  final int? minMileage;
  final int? maxMileage;
  final int? minPower;
  final int? maxPower;
  final String? doors;
  
  // Equipment filters
  final bool? hasABS;
  final bool? hasESP;
  final bool? hasAirbags;
  final bool? hasAirConditioning;
  final bool? hasNavigation;
  final bool? hasHeatedSeats;
  final bool? hasAlarm;
  final bool? hasBluetooth;
  final bool? hasUSB;
  final bool? hasLeatherSteering;
  final bool? hasAlloyWheels;
  final bool? hasSunroof;
  final bool? hasXenonLights;
  final bool? hasElectricMirrors;
  
  // Status filters
  final bool? isForSale;
  final bool? isPriceNegotiable;
  final bool? hasServiceHistory;
  final bool? hasAccidentHistory;

  MarketplaceFilter({
    this.type,
    this.serviceCategory,
    this.accessoryCategory,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.searchQuery,
    this.tags = const [],
    
    // Car specific
    this.country,
    this.brand,
    this.model,
    this.minYear,
    this.maxYear,
    this.fuelType,
    this.transmission,
    this.bodyType,
    this.color,
    this.condition,
    this.minMileage,
    this.maxMileage,
    this.minPower,
    this.maxPower,
    this.doors,
    
    // Equipment
    this.hasABS,
    this.hasESP,
    this.hasAirbags,
    this.hasAirConditioning,
    this.hasNavigation,
    this.hasHeatedSeats,
    this.hasAlarm,
    this.hasBluetooth,
    this.hasUSB,
    this.hasLeatherSteering,
    this.hasAlloyWheels,
    this.hasSunroof,
    this.hasXenonLights,
    this.hasElectricMirrors,
    
    // Status
    this.isForSale,
    this.isPriceNegotiable,
    this.hasServiceHistory,
    this.hasAccidentHistory,
  });
}
