import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType {
  monthly,
  annual,
  lifetime,
}

enum BoostType {
  renewAd,        // $0.99 - Reînnoire anunț
  coloredFrame,   // $0.99 - Ramă colorată (7 zile)
  topBrandModel,  // $0.99 - Top Brand/Model (7 zile)
  topRecommended, // $0.99 - Top Recomandări (7 zile)
  pushNotification, // $0.99 - Promoted push notification
  localBoost,     // $0.99 - Local Boost (7 zile)
  labelTags,      // $0.99 - Labels/Tags (Sale, Best Price, etc.)
  animatedBorder, // $0.99 - Animated border/shimmer effect (7 days)
  
  // 🔖 Badge Boosts (Classic badges)
  newBadge,       // $0.99 - Green "New" label
  saleBadge,      // $0.99 - Red percentage discount label
  negotiableBadge, // $0.99 - Yellow "Negotiable" label
  deliveryBadge,  // $0.99 - Truck icon "Free Delivery" badge
  popularBadge,   // $0.99 - Blue "Popular" tag
  
  // 🟩 Border/Outline Boosts
  coloredBorder,  // $0.99 - Simple colored border
  animatedGlow,   // $0.99 - Glowing aura effect
  
  // ⚡ Dynamic/Impact Boosts
  pulsingCard,    // $0.99 - Pulsing card effect
  shimmerLabel,   // $0.99 - Animated shimmer label
  bounceOnLoad,   // $0.99 - Bounce animation on load
  
  // 🧩 Creative/Special Boosts
  triangularCard, // $0.99 - Triangular corner cut-out
  orbitalStar,    // $0.99 - Orbital star animation
  hologramEffect, // $0.99 - Hologram gradient animation
  lightRay,       // $0.99 - Light ray sweep effect
  floating3DBadge, // $0.99 - 3D floating badge
  tornLabel,      // $0.99 - Torn paper label effect
  handdrawnSticker, // $0.99 - Hand-drawn style sticker
}

enum FrameColor {
  green,
  red,
  blue,
  gold,
  black,
}

enum LabelType {
  sale,        // Sale - Red
  bestPrice,   // Best Price - Green
  negotiable,  // Negotiable - Blue
  new_item,    // New - Orange
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double price;
  final String transactionId;

  Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.price,
    required this.transactionId,
  });

  factory Subscription.fromJson(String id, Map<String, dynamic> json) {
    return Subscription(
      id: id,
      userId: json['userId'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${json['type']}',
        orElse: () => SubscriptionType.monthly,
      ),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null ? (json['endDate'] as Timestamp).toDate() : null,
      isActive: json['isActive'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      transactionId: json['transactionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'price': price,
      'transactionId': transactionId,
    };
  }

  bool get isLifetime => type == SubscriptionType.lifetime;
  
  bool get isExpired {
    if (isLifetime) return false;
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  static Map<SubscriptionType, Map<String, dynamic>> get subscriptionPlans => {
    SubscriptionType.monthly: {
      'name': 'Monthly',
      'price': 4.99,
      'duration': 30, // days
      'productId': 'luway_monthly_subscription',
      'benefits': [
        'Access to Services section',
        'Access to Accessories section',
        'Advanced statistics',
        'Priority support'
      ],
    },
    SubscriptionType.annual: {
      'name': 'Annual',
      'price': 24.99,
      'duration': 365, // days
      'productId': 'luway_annual_subscription',
      'benefits': [
        'All Monthly benefits',
        '50% discount vs Monthly',
        'Extended analytics',
        'Premium support'
      ],
    },
    SubscriptionType.lifetime: {
      'name': 'Lifetime',
      'price': 89.99,
      'duration': null, // permanent
      'productId': 'luway_lifetime_subscription',
      'benefits': [
        'All features forever',
        'No recurring payments',
        'Priority feature access',
        'VIP support'
      ],
    },
  };
}

class Boost {
  final String id;
  final String userId;
  final String itemId;
  final BoostType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double price;
  final String transactionId;
  final Map<String, dynamic>? metadata; // For frame color, etc.
  final bool isPaused; // New field for pause/resume functionality
  final DateTime? pausedAt; // When the boost was paused
  final DateTime? resumedAt; // When the boost was resumed
  final int? remainingTimeMs; // Remaining time in milliseconds when paused

  Boost({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.price,
    required this.transactionId,
    this.metadata,
    this.isPaused = false,
    this.pausedAt,
    this.resumedAt,
    this.remainingTimeMs,
  });

  factory Boost.fromJson(String id, Map<String, dynamic> json) {
    return Boost(
      id: id,
      userId: json['userId'] ?? '',
      itemId: json['itemId'] ?? '',
      type: BoostType.values.firstWhere(
        (e) => e.toString() == 'BoostType.${json['type']}',
        orElse: () => BoostType.renewAd,
      ),
      startDate: json['startDate'] != null 
        ? (json['startDate'] as Timestamp).toDate()
        : json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: json['endDate'] != null 
        ? (json['endDate'] as Timestamp).toDate()
        : json['expiresAt'] != null 
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(Duration(days: 7)), // default 7 days
      isActive: json['isActive'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      transactionId: json['transactionId'] ?? '',
      metadata: json['metadata'],
      isPaused: json['isPaused'] ?? false,
      pausedAt: json['pausedAt'] != null ? (json['pausedAt'] as Timestamp).toDate() : null,
      resumedAt: json['resumedAt'] != null ? (json['resumedAt'] as Timestamp).toDate() : null,
      remainingTimeMs: json['remainingTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'itemId': itemId,
      'type': type.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'price': price,
      'transactionId': transactionId,
      'metadata': metadata,
      'isPaused': isPaused,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'resumedAt': resumedAt != null ? Timestamp.fromDate(resumedAt!) : null,
      'remainingTime': remainingTimeMs,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  
  Duration get remainingTime {
    if (isPaused && remainingTimeMs != null) {
      return Duration(milliseconds: remainingTimeMs!);
    }
    final now = DateTime.now();
    final remaining = endDate.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Map<BoostType, Map<String, dynamic>> get boostPlans => {
    BoostType.renewAd: {
      'name': 'Renew Ad',
      'description': 'Republish your ad before 30 days',
      'price': 0.99,
      'duration': 0, // instant
      'productId': 'luway_boost_renew_ad',
      'icon': '🔁',
      'badge': 'Actualizat',
    },
    BoostType.coloredFrame: {
      'name': 'Colored Frame',
      'description': 'Attract attention with colored border',
      'price': 0.99,
      'duration': 7, // days
      'productId': 'luway_boost_colored_frame',
      'icon': '🎨',
      'badge': 'Premium',
    },
    BoostType.topBrandModel: {
      'name': 'Top Brand/Model',
      'description': 'Appear at top of brand/model searches',
      'price': 1.99,
      'duration': 7, // days
      'productId': 'luway_boost_top_brand_model',
      'icon': '🔝',
      'badge': 'În top',
    },
    BoostType.topRecommended: {
      'name': 'Top Recommendations',
      'description': 'Appear in first recommendation carousel',
      'price': 1.99,
      'duration': 7, // days
      'productId': 'luway_boost_top_recommended',
      'icon': '⭐',
      'badge': 'Recomandat',
    },
    BoostType.pushNotification: {
      'name': 'Push Notification',
      'description': 'Send notification to interested users',
      'price': 0.99,
      'duration': 0, // one-time
      'productId': 'luway_boost_push_notification',
      'icon': '🔔',
      'badge': 'Promovat',
    },
    BoostType.localBoost: {
      'name': 'Local Boost',
      'description': 'Appear first in local searches',
      'price': 0.99,
      'duration': 7, // days
      'productId': 'luway_boost_local',
      'icon': '📍',
      'badge': 'Local Top',
    },
    BoostType.labelTags: {
      'name': 'Label Tags',
      'description': 'Add eye-catching labels to your listing',
      'price': 0.99,
      'duration': 7, // days
      'productId': 'luway_boost_label_tags',
      'icon': '🏷️',
      'badge': 'Tagged',
    },
    BoostType.animatedBorder: {
      'name': 'Animated Border',
      'description': 'Shimmer effect and animated border around your listing',
      'price': 0.99,
      'duration': 7, // days
      'productId': 'luway_boost_animated_border',
      'icon': '✨',
      'badge': 'Shimmering',
    },
    
    // 🔖 Badge Boosts (Classic badges)
    BoostType.newBadge: {
      'name': 'New Badge',
      'description': 'Green label showing item is recently added',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_new_badge',
      'icon': '🆕',
      'badge': 'New',
    },
    BoostType.saleBadge: {
      'name': 'Sale Badge',
      'description': 'Red percentage label indicating current offer',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_sale_badge',
      'icon': '🔥',
      'badge': 'Sale',
    },
    BoostType.negotiableBadge: {
      'name': 'Negotiable Badge',
      'description': 'Yellow label signaling price is discussible',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_negotiable_badge',
      'icon': '💬',
      'badge': 'Negotiable',
    },
    BoostType.deliveryBadge: {
      'name': 'Free Delivery Badge',
      'description': 'Truck icon badge informing delivery is included',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_delivery_badge',
      'icon': '🚚',
      'badge': 'Free Delivery',
    },
    BoostType.popularBadge: {
      'name': 'Popular Badge',
      'description': 'Blue tag for listings with many views or favorites',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_popular_badge',
      'icon': '⭐',
      'badge': 'Popular',
    },
    
    // 🟩 Border/Outline Boosts
    BoostType.coloredBorder: {
      'name': 'Colored Border',
      'description': 'Simple colored border suggesting promoted listing',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_colored_border',
      'icon': '🔲',
      'badge': 'Highlighted',
    },
    BoostType.animatedGlow: {
      'name': 'Glow Effect',
      'description': 'Subtle luminous border for special listings',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_animated_glow',
      'icon': '🌟',
      'badge': 'Glowing',
    },
    
    // ⚡ Dynamic/Impact Boosts
    BoostType.pulsingCard: {
      'name': 'Pulsing Card',
      'description': 'Entire listing pulses slowly to attract attention',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_pulsing_card',
      'icon': '💓',
      'badge': 'Pulsing',
    },
    BoostType.shimmerLabel: {
      'name': 'Shimmer Label',
      'description': 'Label with moving shine effect simulating premium',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_shimmer_label',
      'icon': '💎',
      'badge': 'Premium',
    },
    BoostType.bounceOnLoad: {
      'name': 'Bounce Animation',
      'description': 'Listing bounces slightly on load, standing out',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_bounce_load',
      'icon': '🎯',
      'badge': 'Dynamic',
    },
    
    // 🧩 Creative/Special Boosts
    BoostType.triangularCard: {
      'name': 'Triangular Corner',
      'description': 'Corner cut-out with message appearing torn',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_triangular_card',
      'icon': '📐',
      'badge': 'Hot Deal',
    },
    BoostType.orbitalStar: {
      'name': 'Orbital Star',
      'description': 'Small animated star moving around listing corners',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_orbital_star',
      'icon': '🌟',
      'badge': 'Featured',
    },
    BoostType.hologramEffect: {
      'name': 'Hologram Effect',
      'description': 'Animated gradient background imitating hologram',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_hologram_effect',
      'icon': '🌈',
      'badge': 'Futuristic',
    },
    BoostType.lightRay: {
      'name': 'Light Ray',
      'description': 'Translucent ray crosses listing diagonally',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_light_ray',
      'icon': '🔦',
      'badge': 'Spotlight',
    },
    BoostType.floating3DBadge: {
      'name': '3D Floating Badge',
      'description': 'Badge that appears to float above listing with shadow',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_floating_3d_badge',
      'icon': '🎈',
      'badge': '3D Effect',
    },
    BoostType.tornLabel: {
      'name': 'Torn Label',
      'description': 'Corner appears torn like ripped paper with offer text',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_torn_label',
      'icon': '📜',
      'badge': 'Limited Offer',
    },
    BoostType.handdrawnSticker: {
      'name': 'Hand-drawn Sticker',
      'description': 'Badge with stylized hand-written font effect',
      'price': 0.99,
      'duration': 7,
      'productId': 'luway_boost_handdrawn_sticker',
      'icon': '✍️',
      'badge': 'Authentic',
    },
  };
}

class Transaction {
  final String id;
  final String userId;
  final String type; // 'subscription', 'boost', 'unblock'
  final String itemId; // subscription id, boost id, or 'unblock'
  final double amount;
  final String currency;
  final DateTime createdAt;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String? transactionId; // from payment provider
  final Map<String, dynamic>? metadata;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.itemId,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.status,
    this.transactionId,
    this.metadata,
  });

  factory Transaction.fromJson(String id, Map<String, dynamic> json) {
    return Transaction(
      id: id,
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] ?? 'pending',
      transactionId: json['transactionId'],
      metadata: json['metadata'],
    );
  }
  
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      itemId: map['itemId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'itemId': itemId,
      'amount': amount,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }
}

class UserBlock {
  final String id;
  final String userId;
  final int reportCount;
  final DateTime blockedAt;
  final DateTime? unblockAt;
  final bool isActive;
  final String? unblockTransactionId;

  UserBlock({
    required this.id,
    required this.userId,
    required this.reportCount,
    required this.blockedAt,
    this.unblockAt,
    required this.isActive,
    this.unblockTransactionId,
  });

  factory UserBlock.fromJson(String id, Map<String, dynamic> json) {
    return UserBlock(
      id: id,
      userId: json['userId'] ?? '',
      reportCount: json['reportCount'] ?? 0,
      blockedAt: (json['blockedAt'] as Timestamp).toDate(),
      unblockAt: json['unblockAt'] != null ? (json['unblockAt'] as Timestamp).toDate() : null,
      isActive: json['isActive'] ?? false,
      unblockTransactionId: json['unblockTransactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reportCount': reportCount,
      'blockedAt': Timestamp.fromDate(blockedAt),
      'unblockAt': unblockAt != null ? Timestamp.fromDate(unblockAt!) : null,
      'isActive': isActive,
      'unblockTransactionId': unblockTransactionId,
    };
  }

  bool get isExpired {
    if (unblockAt == null) return false;
    return DateTime.now().isAfter(unblockAt!);
  }

  static const double unblockPrice = 29.99;
  static const String unblockProductId = 'luway_unblock_account';
  static const int blockDurationDays = 7;
}
