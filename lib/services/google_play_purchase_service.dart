import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'dart:io';

class GooglePlayPurchaseService {
  static final GooglePlayPurchaseService _instance = GooglePlayPurchaseService._internal();
  factory GooglePlayPurchaseService() => _instance;
  GooglePlayPurchaseService._internal();

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Product ID Maps
  static const Map<String, String> subscriptionIds = {
    'monthly': 'luway_premium_monthly',
    'annual': 'luway_premium_annual', 
    'lifetime': 'luway_premium_lifetime',
  };

  static const Map<String, String> boostIds = {
    // Basic Boosts
    'renew_ad': 'luway_boost_renew_ad',
    'colored_frame': 'luway_boost_colored_frame',
    'top_brand': 'luway_boost_top_brand',
    'top_recommended': 'luway_boost_top_recommended',
    'push_notification': 'luway_boost_push_notification',
    'local_boost': 'luway_boost_local_boost',
    'label_tags': 'luway_boost_label_tags',
    'animated_border': 'luway_boost_animated_border',

    // Badge Boosts
    'new_badge': 'luway_boost_new_badge',
    'discount_badge': 'luway_boost_sale_badge',
    'negotiable_badge': 'luway_boost_negotiable_badge',
    'delivery_badge': 'luway_boost_delivery_badge',
    'popular_badge': 'luway_boost_popular_badge',

    // Border/Outline Boosts
    'colored_border': 'luway_boost_colored_border',
    'glow_effect': 'luway_boost_animated_glow',

    // Dynamic/Impact Boosts
    'pulsing_card': 'luway_boost_pulsing_card',
    'shimmer_label': 'luway_boost_shimmer_label',
    'bounce_load': 'luway_boost_bounce_on_load',

    // Creative/Special Boosts
    'triangle_corner': 'luway_boost_triangular_card',
    'orbital_star': 'luway_boost_orbital_star',
    'hologram_effect': 'luway_boost_hologram_effect',
    'light_ray': 'luway_boost_light_ray',
    'floating_badge': 'luway_boost_floating_3d_badge',
    'torn_sticker': 'luway_boost_torn_label',
    'handwritten_sticker': 'luway_boost_handdrawn_sticker',
  };

  static const Map<String, String> otherIds = {
    'unblock_user': 'luway_unblock_user',
  };

  // Initialize the purchase service
  Future<bool> initialize() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        print('❌ In-app purchases not available');
        return false;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription.cancel(),
        onError: (error) => print('❌ Purchase stream error: $error'),
      );

      print('✅ Google Play Purchase Service initialized');
      return true;
    } catch (e) {
      print('❌ Failed to initialize purchase service: $e');
      return false;
    }
  }

  // Get available products from Google Play
  Future<List<ProductDetails>> getAvailableProducts({
    List<String>? subscriptionIds,
    List<String>? boostIds,
    List<String>? otherIds,
  }) async {
    try {
      Set<String> productIds = {};
      
      if (subscriptionIds != null) {
        productIds.addAll(subscriptionIds);
      }
      if (boostIds != null) {
        productIds.addAll(boostIds);
      }
      if (otherIds != null) {
        productIds.addAll(otherIds);
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        print('❌ Error fetching products: ${response.error}');
        return [];
      }

      print('✅ Fetched ${response.productDetails.length} products from Google Play');
      return response.productDetails;
    } catch (e) {
      print('❌ Error getting available products: $e');
      return [];
    }
  }

  // Purchase a boost
  Future<bool> purchaseBoost(String boostType) async {
    try {
      final productId = boostIds[boostType];
      if (productId == null) {
        print('❌ Unknown boost type: $boostType');
        return false;
      }

      // Get product details
      final products = await getAvailableProducts(boostIds: [productId]);
      if (products.isEmpty) {
        print('❌ Product not found: $productId');
        return false;
      }

      final product = products.first;
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Start purchase
      print('🛒 Starting purchase for boost: $boostType ($productId)');
      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      print('❌ Error purchasing boost: $e');
      return false;
    }
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(String subscriptionType) async {
    try {
      final productId = subscriptionIds[subscriptionType];
      if (productId == null) {
        print('❌ Unknown subscription type: $subscriptionType');
        return false;
      }

      // Get product details
      final products = await getAvailableProducts(subscriptionIds: [productId]);
      if (products.isEmpty) {
        print('❌ Subscription not found: $productId');
        return false;
      }

      final product = products.first;
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Start purchase
      print('💳 Starting subscription purchase: $subscriptionType ($productId)');
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      print('❌ Error purchasing subscription: $e');
      return false;
    }
  }

  // Purchase user unblock
  Future<bool> purchaseUnblock() async {
    try {
      final productId = otherIds['unblock_user']!;
      
      // Get product details
      final products = await getAvailableProducts(otherIds: [productId]);
      if (products.isEmpty) {
        print('❌ Unblock product not found: $productId');
        return false;
      }

      final product = products.first;
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Start purchase
      print('🔓 Starting unblock purchase: $productId');
      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      print('❌ Error purchasing unblock: $e');
      return false;
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          print('⏳ Purchase pending: ${purchaseDetails.productID}');
          break;
        case PurchaseStatus.purchased:
          print('✅ Purchase successful: ${purchaseDetails.productID}');
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          print('❌ Purchase error: ${purchaseDetails.error}');
          _handleFailedPurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          print('🔄 Purchase restored: ${purchaseDetails.productID}');
          _handleRestoredPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          print('❌ Purchase canceled: ${purchaseDetails.productID}');
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // TODO: Verify purchase with your backend
    // TODO: Grant the purchased content to user
    // TODO: Update Firestore with purchase details
    
    print('💰 Processing successful purchase: ${purchaseDetails.productID}');
    print('📄 Transaction ID: ${purchaseDetails.purchaseID}');
    print('📅 Purchase Time: ${DateTime.fromMillisecondsSinceEpoch(int.parse(purchaseDetails.transactionDate ?? '0'))}');
  }

  // Handle failed purchase
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    print('💥 Purchase failed for: ${purchaseDetails.productID}');
    print('💥 Error: ${purchaseDetails.error?.message}');
  }

  // Handle restored purchase
  void _handleRestoredPurchase(PurchaseDetails purchaseDetails) {
    // TODO: Restore the purchased content to user
    print('🔄 Restoring purchase: ${purchaseDetails.productID}');
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      print('🔄 Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('❌ Error restoring purchases: $e');
    }
  }

  // Get product price formatted
  String getFormattedPrice(ProductDetails product) {
    return product.price;
  }

  // Check if platform supports in-app purchases
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  // Dispose
  void dispose() {
    _subscription.cancel();
  }

  // Get all product IDs as a list for easy reference
  static List<String> getAllProductIds() {
    return [
      ...subscriptionIds.values,
      ...boostIds.values,
      ...otherIds.values,
    ];
  }

  // Get product ID by type and name
  static String? getProductId(String type, String name) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return subscriptionIds[name];
      case 'boost':
        return boostIds[name];
      case 'other':
        return otherIds[name];
      default:
        return null;
    }
  }
}
