import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

class MonetizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // DEBUG TOGGLES FOR TESTING - now per item
  static bool _debugPremiumActive = false;
  static Map<String, Set<BoostType>> _debugActiveBoosts = {}; // itemId -> Set of active boost types
  static Map<String, Set<BoostType>> _debugPausedBoosts = {}; // itemId -> Set of paused boost types
  static Map<String, Map<BoostType, Duration>> _debugRemainingTime = {}; // itemId -> {boostType: remainingTime}
  
  // DEBUG METADATA STORAGE - per item
  static Map<String, Map<String, dynamic>> _debugColoredFrameMetadata = {}; // itemId -> metadata
  static Map<String, Map<String, dynamic>> _debugLabelTagsMetadata = {}; // itemId -> metadata
  
  // Enhanced debug permissions
  static bool _debugFullAccess = true; // Full access to all boost types

    // PERMISSION AND ACCESS METHODS
  static Future<bool> canUseBoost(BoostType type, String? userId) async {
    // Debug mode always allows
    if (_debugFullAccess) return true;
    
    // Check if user has subscription for premium boosts
    if (_isPremiumBoost(type)) {
      return await hasActiveSubscription(userId);
    }
    
    // Basic boosts are available to everyone
    return true;
  }
  
  static bool _isPremiumBoost(BoostType type) {
    // Define which boosts require premium access
    const premiumBoosts = {
      BoostType.topRecommended,
      BoostType.topBrandModel,
      BoostType.animatedBorder,
      BoostType.animatedGlow,
      BoostType.pulsingCard,
      BoostType.shimmerLabel,
      BoostType.bounceOnLoad,
      BoostType.hologramEffect,
      BoostType.lightRay,
      BoostType.floating3DBadge,
      BoostType.orbitalStar,
    };
    
    return premiumBoosts.contains(type);
  }
  
  static List<BoostType> getAvailableBoosts(bool hasSubscription) {
    if (_debugFullAccess || hasSubscription) {
      return BoostType.values;
    }
    
    // Return only non-premium boosts
    return BoostType.values.where((type) => !_isPremiumBoost(type)).toList();
  }
  
  static Map<String, List<BoostType>> getCategorizedBoosts(bool hasSubscription) {
    final available = getAvailableBoosts(hasSubscription);
    
    return {
      'Visibility': available.where((type) => [
        BoostType.topRecommended,
        BoostType.topBrandModel,
        BoostType.localBoost,
        BoostType.renewAd,
        BoostType.pushNotification,
      ].contains(type)).toList(),
      
      'Visual Effects': available.where((type) => [
        BoostType.coloredFrame,
        BoostType.coloredBorder,
        BoostType.animatedBorder,
        BoostType.animatedGlow,
        BoostType.pulsingCard,
        BoostType.shimmerLabel,
        BoostType.bounceOnLoad,
      ].contains(type)).toList(),
      
      'Badges & Labels': available.where((type) => [
        BoostType.labelTags,
        BoostType.newBadge,
        BoostType.saleBadge,
        BoostType.negotiableBadge,
        BoostType.deliveryBadge,
        BoostType.popularBadge,
      ].contains(type)).toList(),
      
      'Premium Effects': available.where((type) => [
        BoostType.triangularCard,
        BoostType.orbitalStar,
        BoostType.hologramEffect,
        BoostType.lightRay,
        BoostType.floating3DBadge,
        BoostType.tornLabel,
        BoostType.handdrawnSticker,
      ].contains(type)).toList(),
    };
  }
  static void toggleDebugPremium() {
    _debugPremiumActive = !_debugPremiumActive;
    print('Debug Premium: $_debugPremiumActive');
  }
  
  static void toggleDebugFullAccess() {
    _debugFullAccess = !_debugFullAccess;
    print('Debug Full Access: $_debugFullAccess');
  }
  
  static bool get hasDebugFullAccess => _debugFullAccess;

  static Future<void> toggleDebugBoost(BoostType type, String itemId) async {
    if (!_debugActiveBoosts.containsKey(itemId)) {
      _debugActiveBoosts[itemId] = <BoostType>{};
    }
    
    if (_debugActiveBoosts[itemId]!.contains(type)) {
      // Pause the boost instead of removing it completely
      await pauseDebugBoost(type, itemId);
    } else {
      // Check if it's paused and resume it, or activate new
      if (_debugPausedBoosts[itemId]?.contains(type) == true) {
        await resumeDebugBoost(type, itemId);
      } else {
        await activateDebugBoost(type, itemId);
      }
    }
  }
  
  static Future<void> activateDebugBoost(BoostType type, String itemId) async {
    if (!_debugActiveBoosts.containsKey(itemId)) {
      _debugActiveBoosts[itemId] = <BoostType>{};
    }
    
    _debugActiveBoosts[itemId]!.add(type);
    
    // Remove from paused if it was there
    _debugPausedBoosts[itemId]?.remove(type);
    
    // Set default duration if not already set
    if (!_debugRemainingTime.containsKey(itemId)) {
      _debugRemainingTime[itemId] = <BoostType, Duration>{};
    }
    
    if (!_debugRemainingTime[itemId]!.containsKey(type)) {
      final plan = Boost.boostPlans[type];
      final defaultDuration = Duration(days: plan?['duration'] ?? 7);
      _debugRemainingTime[itemId]![type] = defaultDuration;
    }
    
    print('Debug: Activated $type for item $itemId with ${_debugRemainingTime[itemId]![type]!.inDays} days remaining');
    
    // Set default metadata
    Map<String, dynamic> metadata = {};
    if (type == BoostType.coloredFrame) {
      metadata = {'frameColor': 'gold'};
      _debugColoredFrameMetadata[itemId] = metadata;
    } else if (type == BoostType.labelTags) {
      metadata = {'labelType': 'sale'};
      _debugLabelTagsMetadata[itemId] = metadata;
    }
    
    // Create real boost in Firestore so other users can see it
    await _createDebugBoostInFirestore(type, itemId, metadata);
  }
  
  static Future<void> pauseDebugBoost(BoostType type, String itemId) async {
    if (!_debugPausedBoosts.containsKey(itemId)) {
      _debugPausedBoosts[itemId] = <BoostType>{};
    }
    
    // Move from active to paused
    _debugActiveBoosts[itemId]?.remove(type);
    _debugPausedBoosts[itemId]!.add(type);
    
    print('Debug: Paused $type for item $itemId. Remaining time: ${_debugRemainingTime[itemId]?[type]?.inDays ?? 0} days');
    
    // Remove from Firestore so others don't see it
    await _removeDebugBoostFromFirestore(type, itemId);
  }
  
  static Future<void> resumeDebugBoost(BoostType type, String itemId) async {
    if (!_debugActiveBoosts.containsKey(itemId)) {
      _debugActiveBoosts[itemId] = <BoostType>{};
    }
    
    // Move from paused to active
    _debugPausedBoosts[itemId]?.remove(type);
    _debugActiveBoosts[itemId]!.add(type);
    
    print('Debug: Resumed $type for item $itemId. Remaining time: ${_debugRemainingTime[itemId]?[type]?.inDays ?? 0} days');
    
    // Get metadata
    Map<String, dynamic> metadata = {};
    if (type == BoostType.coloredFrame && _debugColoredFrameMetadata.containsKey(itemId)) {
      metadata = _debugColoredFrameMetadata[itemId]!;
    } else if (type == BoostType.labelTags && _debugLabelTagsMetadata.containsKey(itemId)) {
      metadata = _debugLabelTagsMetadata[itemId]!;
    }
    
    // Add back to Firestore
    await _createDebugBoostInFirestore(type, itemId, metadata);
  }
  
  static Future<void> removeDebugBoost(BoostType type, String itemId) async {
    // Completely remove the boost (not just pause)
    _debugActiveBoosts[itemId]?.remove(type);
    _debugPausedBoosts[itemId]?.remove(type);
    _debugRemainingTime[itemId]?.remove(type);
    
    print('Debug: Completely removed $type for item $itemId');
    
    // Remove from Firestore
    await _removeDebugBoostFromFirestore(type, itemId);
  }
  
  static Duration? getDebugBoostRemainingTime(BoostType type, String itemId) {
    return _debugRemainingTime[itemId]?[type];
  }
  
  static String getDebugBoostStatus(BoostType type, String itemId) {
    if (_debugActiveBoosts[itemId]?.contains(type) == true) {
      final remaining = getDebugBoostRemainingTime(type, itemId);
      return 'Active (${remaining?.inDays ?? 0}d remaining)';
    } else if (_debugPausedBoosts[itemId]?.contains(type) == true) {
      final remaining = getDebugBoostRemainingTime(type, itemId);
      return 'Paused (${remaining?.inDays ?? 0}d saved)';
    } else {
      return 'Inactive';
    }
  }
  
  static List<BoostType> getDebugPausedBoosts(String itemId) {
    return _debugPausedBoosts[itemId]?.toList() ?? [];
  }

  static bool get isDebugPremiumActive => _debugPremiumActive;
  static bool isDebugBoostActive(BoostType type, String itemId) {
    return _debugActiveBoosts[itemId]?.contains(type) ?? false;
  }
  
  static bool isDebugBoostPaused(BoostType type, String itemId) {
    return _debugPausedBoosts[itemId]?.contains(type) ?? false;
  }
  
  static bool hasDebugBoost(BoostType type, String itemId) {
    return isDebugBoostActive(type, itemId) || isDebugBoostPaused(type, itemId);
  }
  
  static List<Boost> getDebugBoostsForItem(String itemId) {
    final activeTypes = _debugActiveBoosts[itemId] ?? <BoostType>{};
    final boosts = <Boost>[];
    
    for (final type in activeTypes) {
      Map<String, dynamic> metadata = {};
      
      if (type == BoostType.coloredFrame && _debugColoredFrameMetadata.containsKey(itemId)) {
        metadata = _debugColoredFrameMetadata[itemId]!;
      } else if (type == BoostType.labelTags && _debugLabelTagsMetadata.containsKey(itemId)) {
        metadata = _debugLabelTagsMetadata[itemId]!;
      }
      
      boosts.add(Boost(
        id: 'debug_${type.toString().split('.').last}_$itemId',
        userId: _auth.currentUser?.uid ?? '',
        itemId: itemId,
        type: type,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 1)),
        isActive: true,
        transactionId: 'debug_transaction',
        price: 0.0,
        metadata: metadata.isNotEmpty ? metadata : null,
      ));
    }
    
    return boosts;
  }

  static String getDebugBoostHash(String itemId) {
    final activeTypes = _debugActiveBoosts[itemId] ?? <BoostType>{};
    return activeTypes.map((t) => t.toString().split('.').last).join('_');
  }

  static Future<List<Boost>> getCombinedActiveBoosts(String itemId) async {
    final firestoreBoosts = await getItemActiveBoosts(itemId);
    final debugBoosts = getDebugBoostsForItem(itemId);
    
    // Combine and remove duplicates based on type
    final Map<BoostType, Boost> combinedMap = {};
    
    for (final boost in firestoreBoosts) {
      combinedMap[boost.type] = boost;
    }
    
    // Debug boosts override Firestore boosts for the same type
    for (final boost in debugBoosts) {
      combinedMap[boost.type] = boost;
    }
    
    return combinedMap.values.toList();
  }

  // SUBSCRIPTION METHODS
  static Future<Subscription?> getUserActiveSubscription(String userId) async {
    try {
      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final subscription = Subscription.fromJson(query.docs.first.id, query.docs.first.data());
        
        // Check if subscription is expired
        if (!subscription.isLifetime && subscription.isExpired) {
          // Mark as inactive
          await _firestore
              .collection('subscriptions')
              .doc(subscription.id)
              .update({'isActive': false});
          return null;
        }
        
        return subscription;
      }
      return null;
    } catch (e) {
      print('Error getting user subscription: $e');
      return null;
    }
  }

  static Future<bool> hasActiveSubscription(String? userId) async {
    // Check debug toggle first
    if (_debugPremiumActive) return true;
    
    if (userId == null) return false;
    final subscription = await getUserActiveSubscription(userId);
    return subscription != null;
  }

  static Future<bool> canAccessPremiumFeatures(String? userId) async {
    // Check debug toggle first
    if (_debugPremiumActive) return true;
    
    return await hasActiveSubscription(userId);
  }

  static Future<String?> createSubscription({
    required SubscriptionType type,
    required String transactionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final plan = Subscription.subscriptionPlans[type]!;
      final startDate = DateTime.now();
      DateTime? endDate;
      
      if (type != SubscriptionType.lifetime) {
        endDate = startDate.add(Duration(days: plan['duration']));
      }

      // Deactivate any existing subscription
      await _deactivateUserSubscriptions(user.uid);

      final subscription = Subscription(
        id: '',
        userId: user.uid,
        type: type,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        price: plan['price'],
        transactionId: transactionId,
      );

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toJson());

      // Create transaction record
      await _createTransaction(
        type: 'subscription',
        itemId: docRef.id,
        amount: plan['price'],
        transactionId: transactionId,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  static Future<void> _deactivateUserSubscriptions(String userId) async {
    try {
      final activeSubscriptions = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in activeSubscriptions.docs) {
        await doc.reference.update({'isActive': false});
      }
    } catch (e) {
      print('Error deactivating subscriptions: $e');
    }
  }

  // REAL BOOST PAUSE/RESUME METHODS
  static Future<bool> pauseBoost(String boostId) async {
    try {
      final boostDoc = await _firestore.collection('boosts').doc(boostId).get();
      if (!boostDoc.exists) return false;
      
      final boost = Boost.fromJson(boostDoc.id, boostDoc.data()!);
      if (!boost.isActive) return false;
      
      // Calculate remaining time
      final now = DateTime.now();
      final remainingTime = boost.endDate.difference(now);
      
      if (remainingTime.isNegative) {
        // Boost already expired
        await boostDoc.reference.update({'isActive': false});
        return false;
      }
      
      // Update boost to paused state
      await boostDoc.reference.update({
        'isActive': false,
        'isPaused': true,
        'pausedAt': Timestamp.fromDate(now),
        'remainingTime': remainingTime.inMilliseconds,
      });
      
      // Remove boost effects from marketplace item
      await _removeBoostFromMarketplaceItem(boost.itemId, boost.type);
      
      print('Paused boost $boostId with ${remainingTime.inDays} days remaining');
      return true;
    } catch (e) {
      print('Error pausing boost: $e');
      return false;
    }
  }
  
  static Future<bool> resumeBoost(String boostId) async {
    try {
      final boostDoc = await _firestore.collection('boosts').doc(boostId).get();
      if (!boostDoc.exists) return false;
      
      final boostData = boostDoc.data()!;
      final isPaused = boostData['isPaused'] ?? false;
      if (!isPaused) return false;
      
      final remainingTimeMs = boostData['remainingTime'] ?? 0;
      if (remainingTimeMs <= 0) return false;
      
      final now = DateTime.now();
      final newEndDate = now.add(Duration(milliseconds: remainingTimeMs));
      
      // Update boost to active state with new end date
      await boostDoc.reference.update({
        'isActive': true,
        'isPaused': false,
        'pausedAt': FieldValue.delete(),
        'remainingTime': FieldValue.delete(),
        'endDate': Timestamp.fromDate(newEndDate),
        'resumedAt': Timestamp.fromDate(now),
      });
      
      // Recreate boost from data
      final boost = Boost.fromJson(boostDoc.id, {
        ...boostData,
        'isActive': true,
        'endDate': Timestamp.fromDate(newEndDate),
      });
      
      // Reapply boost effects to marketplace item
      await _updateMarketplaceItemWithBoost(boost.itemId, boost.type, boost.metadata);
      
      print('Resumed boost $boostId with ${Duration(milliseconds: remainingTimeMs).inDays} days remaining');
      return true;
    } catch (e) {
      print('Error resuming boost: $e');
      return false;
    }
  }
  
  static Future<List<Boost>> getUserPausedBoosts(String userId) async {
    try {
      final query = await _firestore
          .collection('boosts')
          .where('userId', isEqualTo: userId)
          .where('isPaused', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Boost.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user paused boosts: $e');
      return [];
    }
  }
  
  static Future<Duration?> getBoostRemainingTime(String boostId) async {
    try {
      final boostDoc = await _firestore.collection('boosts').doc(boostId).get();
      if (!boostDoc.exists) return null;
      
      final boostData = boostDoc.data()!;
      final isPaused = boostData['isPaused'] ?? false;
      
      if (isPaused) {
        final remainingTimeMs = boostData['remainingTime'] ?? 0;
        return Duration(milliseconds: remainingTimeMs);
      } else {
        final endDate = (boostData['endDate'] as Timestamp).toDate();
        final now = DateTime.now();
        final remaining = endDate.difference(now);
        return remaining.isNegative ? Duration.zero : remaining;
      }
    } catch (e) {
      print('Error getting boost remaining time: $e');
      return null;
    }
  }
  // BOOST METHODS
  static Future<List<Boost>> getItemActiveBoosts(String itemId) async {
    try {
      final query = await _firestore
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .where('isActive', isEqualTo: true)
          .get();

      final boosts = <Boost>[];

      for (final doc in query.docs) {
        final boost = Boost.fromJson(doc.id, doc.data());
        
        if (boost.isExpired) {
          // Mark as inactive
          await doc.reference.update({'isActive': false});
        } else {
          boosts.add(boost);
        }
      }

      print('Found ${boosts.length} active boosts for item $itemId');
      return boosts;
    } catch (e) {
      print('Error getting item boosts: $e');
      return [];
    }
  }
  
  static Future<List<Boost>> getItemAllBoosts(String itemId) async {
    try {
      final query = await _firestore
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .get();

      return query.docs
          .map((doc) => Boost.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all item boosts: $e');
      return [];
    }
  }
  
  static Future<List<Boost>> getUserAllBoosts(String userId) async {
    try {
      final query = await _firestore
          .collection('boosts')
          .where('userId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .get();

      return query.docs
          .map((doc) => Boost.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user boosts: $e');
      return [];
    }
  }

  static Future<bool> hasActiveBoost(String itemId, BoostType type) async {
    final boosts = await getItemActiveBoosts(itemId);
    return boosts.any((boost) => boost.type == type);
  }

  static Future<String?> createBoost({
    required String itemId,
    required BoostType type,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // If debug mode is active for this boost type, simulate activation without Firestore
      if (isDebugBoostActive(type, itemId)) {
        print('Debug mode: Simulating boost activation for $type on item $itemId');
        
        // Update the debug metadata if provided
        if (metadata != null) {
          switch (type) {
            case BoostType.coloredFrame:
              _debugColoredFrameMetadata[itemId] = Map<String, dynamic>.from(metadata);
              print('Debug: Setting frame color to ${metadata['frameColor']} for item $itemId');
              break;
            case BoostType.labelTags:
              _debugLabelTagsMetadata[itemId] = Map<String, dynamic>.from(metadata);
              print('Debug: Setting label type to ${metadata['labelType']} for item $itemId');
              break;
            default:
              break;
          }
        }
        
        // Return a mock boost ID
        return 'debug_boost_${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final plan = Boost.boostPlans[type]!;
      final startDate = DateTime.now();
      final endDate = plan['duration'] > 0 
          ? startDate.add(Duration(days: plan['duration']))
          : startDate.add(Duration(minutes: 1)); // For instant boosts

      final boost = Boost(
        id: '',
        userId: user.uid,
        itemId: itemId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        price: plan['price'],
        transactionId: transactionId,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection('boosts')
          .add(boost.toJson());

      // Create transaction record
      await _createTransaction(
        type: 'boost',
        itemId: docRef.id,
        amount: plan['price'],
        transactionId: transactionId,
        metadata: {'boostType': _getBoostTypeName(type)},
      );

      // Handle special boost logic
      await _handleBoostLogic(type, itemId, metadata);

      return docRef.id;
    } catch (e) {
      print('Error creating boost: $e');
      return null;
    }
  }

  static Future<void> _handleBoostLogic(BoostType type, String itemId, Map<String, dynamic>? metadata) async {
    switch (type) {
      case BoostType.renewAd:
        // Update marketplace item's updatedAt to current time
        await _firestore
            .collection('marketplace')
            .doc(itemId)
            .update({'updatedAt': Timestamp.now()});
        break;
      
      case BoostType.pushNotification:
        // TODO: Trigger push notification to interested users
        await _sendPushNotificationForItem(itemId);
        break;
      
      default:
        // Other boosts are handled in UI
        break;
    }
  }

  static Future<void> _sendPushNotificationForItem(String itemId) async {
    // TODO: Implement push notification logic
    // This would involve:
    // 1. Getting users who favorited similar items
    // 2. Getting users who searched for similar items
    // 3. Sending push notifications to those users
    print('Sending push notification for item: $itemId');
  }

  // USER BLOCK METHODS
  static Future<UserBlock?> getUserActiveBlock(String userId) async {
    try {
      final query = await _firestore
          .collection('user_blocks')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('blockedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final block = UserBlock.fromJson(query.docs.first.id, query.docs.first.data());
        
        // Check if block is expired
        if (block.isExpired) {
          // Mark as inactive
          await _firestore
              .collection('user_blocks')
              .doc(block.id)
              .update({'isActive': false});
          return null;
        }
        
        return block;
      }
      return null;
    } catch (e) {
      print('Error getting user block: $e');
      return null;
    }
  }

  static Future<bool> isUserBlocked(String? userId) async {
    if (userId == null) return false;
    final block = await getUserActiveBlock(userId);
    return block != null;
  }

  static Future<String?> createUserBlock(String userId, int reportCount) async {
    try {
      final blockedAt = DateTime.now();
      final unblockAt = blockedAt.add(Duration(days: UserBlock.blockDurationDays));

      final block = UserBlock(
        id: '',
        userId: userId,
        reportCount: reportCount,
        blockedAt: blockedAt,
        unblockAt: unblockAt,
        isActive: true,
      );

      final docRef = await _firestore
          .collection('user_blocks')
          .add(block.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating user block: $e');
      return null;
    }
  }

  static Future<bool> unblockUser(String userId, String transactionId) async {
    try {
      // Get active block
      final block = await getUserActiveBlock(userId);
      if (block == null) return false;

      // Mark block as inactive
      await _firestore
          .collection('user_blocks')
          .doc(block.id)
          .update({
        'isActive': false,
        'unblockTransactionId': transactionId,
      });

      // Create transaction record
      await _createTransaction(
        type: 'unblock',
        itemId: block.id,
        amount: UserBlock.unblockPrice,
        transactionId: transactionId,
      );

      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // TRANSACTION METHODS
  static Future<String?> _createTransaction({
    required String type,
    required String itemId,
    required double amount,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final transaction = Transaction(
        id: '',
        userId: user.uid,
        type: type,
        itemId: itemId,
        amount: amount,
        currency: 'USD',
        createdAt: DateTime.now(),
        status: 'completed',
        transactionId: transactionId,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  static Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Transaction.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // UTILITY METHODS
  static String getBoostBadgeText(BoostType type) {
    final plan = Boost.boostPlans[type];
    return plan?['badge'] ?? '';
  }

  static String getBoostIcon(BoostType type) {
    final plan = Boost.boostPlans[type];
    return plan?['icon'] ?? '';
  }
  
  static String getBoostBadge(BoostType type) {
    final plan = Boost.boostPlans[type];
    return plan?['badge'] ?? '';
  }

  static double calculateBoostTotal(List<BoostType> selectedBoosts) {
    double total = 0.0;
    for (final type in selectedBoosts) {
      final plan = Boost.boostPlans[type];
      if (plan != null) {
        total += plan['price'];
      }
    }
    return total;
  }

  static List<String> getAllProductIds() {
    final List<String> productIds = [];
    
    // Add subscription product IDs
    for (final plan in Subscription.subscriptionPlans.values) {
      productIds.add(plan['productId']);
    }
    
    // Add boost product IDs
    for (final plan in Boost.boostPlans.values) {
      productIds.add(plan['productId']);
    }
    
    // Add unblock product ID
    productIds.add(UserBlock.unblockProductId);
    
    return productIds;
  }

  // Helper methods for debug boost management
  static Future<void> _createDebugBoostInFirestore(BoostType type, String itemId, Map<String, dynamic> metadata) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final plan = Boost.boostPlans[type]!;
      final boost = Boost(
        id: 'debug_${type.toString().split('.').last}_$itemId',
        type: type,
        userId: user.uid,
        itemId: itemId,
        transactionId: 'debug_transaction_${DateTime.now().millisecondsSinceEpoch}',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: plan['duration'])),
        isActive: true,
        price: 0.0, // Debug boost is free
        metadata: metadata,
      );

      await _firestore
          .collection('boosts')
          .doc(boost.id)
          .set(boost.toJson());

      // Also update the marketplace item with boost information
      await _updateMarketplaceItemWithBoost(itemId, type, metadata);

      print('Debug: Created real boost in Firestore for $type on item $itemId');
    } catch (e) {
      print('Error creating debug boost in Firestore: $e');
    }
  }

  static Future<void> _removeDebugBoostFromFirestore(BoostType type, String itemId) async {
    try {
      final docId = 'debug_${type.toString().split('.').last}_$itemId';
      await _firestore
          .collection('boosts')
          .doc(docId)
          .delete();

      // Also remove boost information from marketplace item
      await _removeBoostFromMarketplaceItem(itemId, type);

      print('Debug: Removed real boost from Firestore for $type on item $itemId');
    } catch (e) {
      print('Error removing debug boost from Firestore: $e');
    }
  }

  /// Maps BoostType enum to the correct string name used in marketplace boostTypes
  static String _getBoostTypeName(BoostType type) {
    switch (type) {
      case BoostType.topRecommended:
        return 'top_recommendation';
      case BoostType.topBrandModel:
        return 'top_model';
      case BoostType.coloredFrame:
        return 'frame_boost';
      case BoostType.labelTags:
        return 'label_boost';
      case BoostType.animatedBorder:
        return 'animated_boost';
      case BoostType.renewAd:
        return 'renew_ad';
      case BoostType.pushNotification:
        return 'push_notification';
      case BoostType.localBoost:
        return 'local_boost';
      
      // 🔖 Badge Boosts (Classic badges)
      case BoostType.newBadge:
        return 'new_badge';
      case BoostType.saleBadge:
        return 'sale_badge';
      case BoostType.negotiableBadge:
        return 'negotiable_badge';
      case BoostType.deliveryBadge:
        return 'delivery_badge';
      case BoostType.popularBadge:
        return 'popular_badge';
      
      // 🟩 Border/Outline Boosts
      case BoostType.coloredBorder:
        return 'colored_border';
      case BoostType.animatedGlow:
        return 'animated_glow';
      
      // ⚡ Dynamic/Impact Boosts
      case BoostType.pulsingCard:
        return 'pulsing_card';
      case BoostType.shimmerLabel:
        return 'shimmer_label';
      case BoostType.bounceOnLoad:
        return 'bounce_on_load';
      
      // 🧩 Creative/Special Boosts
      case BoostType.triangularCard:
        return 'triangular_card';
      case BoostType.orbitalStar:
        return 'orbital_star';
      case BoostType.hologramEffect:
        return 'hologram_effect';
      case BoostType.lightRay:
        return 'light_ray';
      case BoostType.floating3DBadge:
        return 'floating_3d_badge';
      case BoostType.tornLabel:
        return 'torn_label';
      case BoostType.handdrawnSticker:
        return 'handdrawn_sticker';
    }
  }

  /// Public accessor for boost type name mapping
  static String getBoostTypeName(BoostType type) {
    return _getBoostTypeName(type);
  }

  /// Update marketplace item with boost information
  static Future<void> _updateMarketplaceItemWithBoost(String itemId, BoostType type, Map<String, dynamic>? metadata) async {
    try {
      final boostTypeName = _getBoostTypeName(type);
      
      // Get current marketplace item
      final itemDoc = await _firestore.collection('marketplace').doc(itemId).get();
      if (!itemDoc.exists) {
        print('Marketplace item $itemId not found');
        return;
      }
      
      final currentData = itemDoc.data()!;
      final currentBoostTypes = List<String>.from(currentData['boostTypes'] ?? []);
      
      // Add new boost type if not already present
      if (!currentBoostTypes.contains(boostTypeName)) {
        currentBoostTypes.add(boostTypeName);
      }
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'hasActiveBoost': true,
        'boostTypes': currentBoostTypes,
        'boostCount': currentBoostTypes.length,
      };
      
      // Add specific metadata based on boost type
      if (metadata != null) {
        switch (type) {
          case BoostType.coloredFrame:
            if (metadata.containsKey('frameColor')) {
              updateData['frameColor'] = metadata['frameColor'];
            }
            break;
          case BoostType.labelTags:
            if (metadata.containsKey('labelType')) {
              updateData['labelType'] = metadata['labelType'];
            }
            break;
          default:
            // Add any other metadata directly
            updateData.addAll(metadata);
            break;
        }
      }
      
      // Update marketplace item
      await _firestore.collection('marketplace').doc(itemId).update(updateData);
      
      print('Updated marketplace item $itemId with boost $boostTypeName');
    } catch (e) {
      print('Error updating marketplace item with boost: $e');
    }
  }

  /// Remove boost information from marketplace item
  static Future<void> _removeBoostFromMarketplaceItem(String itemId, BoostType type) async {
    try {
      final boostTypeName = _getBoostTypeName(type);
      
      // Get current marketplace item
      final itemDoc = await _firestore.collection('marketplace').doc(itemId).get();
      if (!itemDoc.exists) {
        print('Marketplace item $itemId not found');
        return;
      }
      
      final currentData = itemDoc.data()!;
      final currentBoostTypes = List<String>.from(currentData['boostTypes'] ?? []);
      
      // Remove boost type
      currentBoostTypes.remove(boostTypeName);
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'boostTypes': currentBoostTypes,
        'boostCount': currentBoostTypes.length,
      };
      
      // If no more boosts, mark as inactive
      if (currentBoostTypes.isEmpty) {
        updateData['hasActiveBoost'] = false;
      }
      
      // Remove specific metadata based on boost type
      switch (type) {
        case BoostType.coloredFrame:
          updateData['frameColor'] = FieldValue.delete();
          break;
        case BoostType.labelTags:
          updateData['labelType'] = FieldValue.delete();
          break;
        default:
          break;
      }
      
      // Update marketplace item
      await _firestore.collection('marketplace').doc(itemId).update(updateData);
      
      print('Removed boost $boostTypeName from marketplace item $itemId');
    } catch (e) {
      print('Error removing boost from marketplace item: $e');
    }
  }
}
