class VehicleModel {
  final String id;
  final String make;
  final String model;
  final String year;
  final String licensePlate;
  final String countryCode;
  final String countryName;
  final String countryFlag;
  final String? price;
  final String? description;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isForSale;
  final int views;
  final double rating;
  final int reviewCount;
  final String? location;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? specifications;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.countryCode,
    required this.countryName,
    required this.countryFlag,
    this.price,
    this.description,
    this.images = const [],
    required this.ownerId,
    required this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isForSale = false,
    this.views = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.location,
    this.latitude,
    this.longitude,
    this.specifications,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      countryCode: json['countryCode'] ?? '',
      countryName: json['countryName'] ?? '',
      countryFlag: json['countryFlag'] ?? '',
      price: json['price'],
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerEmail: json['ownerEmail'],
      ownerPhone: json['ownerPhone'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      isForSale: json['isForSale'] ?? false,
      views: json['views'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      specifications: json['specifications'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'countryCode': countryCode,
      'countryName': countryName,
      'countryFlag': countryFlag,
      'price': price,
      'description': description,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'isForSale': isForSale,
      'views': views,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'specifications': specifications,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? make,
    String? model,
    String? year,
    String? licensePlate,
    String? countryCode,
    String? countryName,
    String? countryFlag,
    String? price,
    String? description,
    List<String>? images,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isForSale,
    int? views,
    double? rating,
    int? reviewCount,
    String? location,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? specifications,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      countryFlag: countryFlag ?? this.countryFlag,
      price: price ?? this.price,
      description: description ?? this.description,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isForSale: isForSale ?? this.isForSale,
      views: views ?? this.views,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      specifications: specifications ?? this.specifications,
    );
  }

  String get displayName => '$make $model $year';
  String get fullLicensePlate => '$countryFlag $licensePlate';
  bool get hasImages => images.isNotEmpty;
  String get priceDisplay => price ?? 'Price not listed';

  @override
  String toString() {
    return 'VehicleModel(id: $id, make: $make, model: $model, year: $year, licensePlate: $licensePlate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleModel &&
        other.id == id &&
        other.licensePlate == licensePlate &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^ licensePlate.hashCode ^ countryCode.hashCode;
  }
}

// Country Info Model (from your global_plate.md file)
class CountryInfo {
  final String code;
  final String name;
  final String flag;
  final String format;
  final double lat;
  final double lng;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.format,
    required this.lat,
    required this.lng,
  });

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      code: json['code'],
      name: json['name'],
      flag: json['flag'],
      format: json['format'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'flag': flag,
      'format': format,
      'lat': lat,
      'lng': lng,
    };
  }
}

// Accessory Model
class AccessoryModel {
  final String id;
  final String name;
  final String description;
  final String price;
  final String category;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isActive;
  final int views;
  final double rating;

  AccessoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    this.isActive = true,
    this.views = 0,
    this.rating = 0.0,
  });

  factory AccessoryModel.fromJson(Map<String, dynamic> json) {
    return AccessoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      category: json['category'],
      images: List<String>.from(json['images'] ?? []),
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'rating': rating,
    };
  }
}

// Service Model
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String priceRange;
  final String category;
  final List<String> images;
  final String providerId;
  final String providerName;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final bool isActive;
  final int views;
  final double rating;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceRange,
    required this.category,
    this.images = const [],
    required this.providerId,
    required this.providerName,
    required this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.isActive = true,
    this.views = 0,
    this.rating = 0.0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      priceRange: json['priceRange'],
      category: json['category'],
      images: List<String>.from(json['images'] ?? []),
      providerId: json['providerId'],
      providerName: json['providerName'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceRange': priceRange,
      'category': category,
      'images': images,
      'providerId': providerId,
      'providerName': providerName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'rating': rating,
    };
  }
}
