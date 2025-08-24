import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/marketplace_item.dart';
import '../screens/marketplace_item_detail_screen.dart';
import '../screens/chat_screen.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification service
  static Future<void> initialize() async {
    print('🔔 Initializing NotificationService...');

    // Request permission for iOS
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get and save FCM token
    await _saveTokenToDatabase();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _checkForInitialMessage();

    print('✅ NotificationService initialized successfully');
  }

  // Request notification permission
  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('❌ Error requesting permission: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  // Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
      'default_channel',
      'Default',
      description: 'Default notification channel',
      importance: Importance.high,
    );

    const AndroidNotificationChannel messageChannel =
        AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
    );

    const AndroidNotificationChannel favoriteChannel =
        AndroidNotificationChannel(
      'favorites',
      'Favorites',
      description: 'Notifications for favorite updates',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel priceUpdateChannel =
        AndroidNotificationChannel(
      'price_updates',
      'Price Updates',
      description: 'Notifications for price changes',
      importance: Importance.high,
    );

    const AndroidNotificationChannel dailySummaryChannel =
        AndroidNotificationChannel(
      'daily_summary',
      'Daily Summary',
      description: 'Daily summary of favorites',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(favoriteChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(priceUpdateChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dailySummaryChannel);
  }

  // Save FCM token to database
  static Future<void> _saveTokenToDatabase([String? token]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, cannot save FCM token');
        return;
      }

      final fcmToken = token ?? await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        print('❌ Failed to get FCM token');
        return;
      }

      print('📱 Saving FCM token for user: ${user.uid}');
      print('🔑 Token: ${fcmToken.substring(0, 50)}...');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': fcmToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': 'android',
        'appVersion': '1.0.0',
      });

      print('✅ FCM Token saved successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      // Încearcă să creeze documentul dacă nu există
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final fcmToken = token ?? await _firebaseMessaging.getToken();
          if (fcmToken != null) {
            await _firestore.collection('users').doc(user.uid).set({
              'fcmToken': fcmToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
              'platform': 'android',
              'appVersion': '1.0.0',
            }, SetOptions(merge: true));
            print('✅ FCM Token saved with document creation');
          }
        }
      } catch (e2) {
        print('❌ Failed to create user document: $e2');
      }
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Received foreground message: ${message.messageId}');

    // Save to unread notifications
    await _saveUnreadNotification(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.data}');
    await _navigateFromNotification(message.data);
  }

  // Check for initial message (app opened from terminated state)
  static Future<void> _checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from notification: ${initialMessage.data}');
      // Wait a bit for app to initialize
      await Future.delayed(const Duration(seconds: 2));
      await _navigateFromNotification(initialMessage.data);
    }
  }

  // Handle local notification tap
  static void _onLocalNotificationTap(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateFromNotification(data);
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    if (notification == null) return;

    String channelId = 'default';
    switch (data['type']) {
      case 'message':
        channelId = 'messages';
        break;
      case 'favorite_added':
        channelId = 'favorites';
        break;
      case 'price_update':
        channelId = 'price_updates';
        break;
      case 'daily_summary':
        channelId = 'daily_summary';
        break;
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, // Use the determined channelId
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data),
    );
  }

  // Save unread notification to Firestore (exclude messages)
  static Future<void> _saveUnreadNotification(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Don't save message notifications to notifications tab
      if (message.data['type'] == 'message') {
        print('📨 Message notification skipped from notifications tab');
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': message.data['type'] ?? 'general',
      });

      print('💾 Unread notification saved');
    } catch (e) {
      print('❌ Error saving unread notification: $e');
    }
  }

  // Navigate based on notification data
  static Future<void> _navigateFromNotification(
      Map<String, dynamic> data) async {
    try {
      switch (data['type']) {
        case 'message':
          // Navigate to chat
          if (data['conversationId'] != null) {
            Get.to(() => ChatConversationScreen(
                  conversationId: data['conversationId'],
                  receiverId: data['senderId'] ?? '',
                  carBrand: data['carBrand'] ?? 'Chat',
                ));
          }
          break;

        case 'favorite_added':
        case 'price_update':
          // Navigate to marketplace item
          if (data['itemId'] != null) {
            try {
              final itemDoc = await _firestore
                  .collection('marketplace')
                  .doc(data['itemId'])
                  .get();

              if (itemDoc.exists) {
                final item = MarketplaceItem.fromJson(
                  itemDoc.id,
                  itemDoc.data() as Map<String, dynamic>,
                );
                Get.to(() => MarketplaceItemDetailScreen(item: item));
              }
            } catch (e) {
              print('❌ Error loading marketplace item: $e');
            }
          }
          break;

        case 'daily_summary':
          // Navigate to favorites or analytics screen
          // Get.to(() => FavoritesAnalyticsScreen());
          break;
      }
    } catch (e) {
      print('❌ Error navigating from notification: $e');
    }
  }

  // Send message notification
  static Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String conversationId,
    String? carBrand,
  }) async {
    try {
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('⚠️ No FCM token for user: $receiverId');
        return;
      }

      // Send push notification
      await _sendPushNotification(
        token: fcmToken,
        title: 'New message from $senderName',
        body: message,
        data: {
          'type': 'message',
          'conversationId': conversationId,
          'senderId': _auth.currentUser?.uid ?? '',
          'carBrand': carBrand ?? 'Chat',
        },
      );

      // Message notifications only as push + badge, not in notifications tab
      // await _saveNotificationToUser(...) - REMOVED

      print('📤 Message notification sent to: $receiverId');
    } catch (e) {
      print('❌ Error sending message notification: $e');
    }
  }

  // Send favorite added notification
  static Future<void> sendFavoriteAddedNotification({
    required String itemOwnerId,
    required String favoritedByName,
    required String itemTitle,
    required String itemId,
  }) async {
    try {
      final ownerDoc =
          await _firestore.collection('users').doc(itemOwnerId).get();
      final fcmToken = ownerDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('⚠️ No FCM token for user: $itemOwnerId');
        return;
      }

      // Send push notification
      await _sendPushNotification(
        token: fcmToken,
        title: 'Listing added to favorites!',
        body: '$favoritedByName added "$itemTitle" to favorites',
        data: {
          'type': 'favorite_added',
          'itemId': itemId,
          'favoritedBy': _auth.currentUser?.uid ?? '',
        },
      );

      // Save notification in user's notifications collection for in-app display
      await _saveNotificationToUser(
        userId: itemOwnerId,
        title: 'Listing added to favorites!',
        body: '$favoritedByName added "$itemTitle" to favorites',
        type: 'favorite_added',
        data: {
          'itemId': itemId,
          'favoritedBy': _auth.currentUser?.uid ?? '',
        },
      );

      print('📤 Favorite notification sent to: $itemOwnerId');
    } catch (e) {
      print('❌ Error sending favorite notification: $e');
    }
  }

  // Send price update notification
  static Future<void> sendPriceUpdateNotification({
    required String itemId,
    required String itemTitle,
    required double oldPrice,
    required double newPrice,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all users who favorited this item
      final favoritesQuery = await _firestore
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .get();

      for (final doc in favoritesQuery.docs) {
        final userId = doc.data()['userId'];
        if (userId == null) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final fcmToken = userDoc.data()?['fcmToken'];

        if (fcmToken == null) continue;

        final priceChange = newPrice < oldPrice ? 'decreased' : 'increased';
        final priceDiff = (newPrice - oldPrice).abs();

        // Send push notification
        await _sendPushNotification(
          token: fcmToken,
          title: 'Price updated!',
          body:
              'Price for "$itemTitle" has $priceChange by €${priceDiff.toStringAsFixed(0)}',
          data: {
            'type': 'price_update',
            'itemId': itemId,
            'oldPrice': oldPrice.toString(),
            'newPrice': newPrice.toString(),
          },
        );

        // Save notification in user's notifications collection for in-app display
        await _saveNotificationToUser(
          userId: userId,
          title: 'Price updated!',
          body:
              'Price for "$itemTitle" has $priceChange by €${priceDiff.toStringAsFixed(0)}',
          type: 'price_update',
          data: {
            'itemId': itemId,
            'oldPrice': oldPrice.toString(),
            'newPrice': newPrice.toString(),
          },
        );
      }

      print('📤 Price update notifications sent for item: $itemId');
    } catch (e) {
      print('❌ Error sending price update notifications: $e');
    }
  }

  // Send daily summary notification
  static Future<void> sendDailySummaryNotification({
    required String userId,
    required int totalFavorites,
    required List<String> itemTitles,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('⚠️ No FCM token for user: $userId');
        return;
      }

      String body = totalFavorites == 1
          ? 'One person added your listings to favorites today'
          : '$totalFavorites people added your listings to favorites today';

      // Send push notification
      await _sendPushNotification(
        token: fcmToken,
        title: 'Daily summary',
        body: body,
        data: {
          'type': 'daily_summary',
          'totalFavorites': totalFavorites.toString(),
          'itemTitles': itemTitles.join(','),
        },
      );

      // Save notification in user's notifications collection for in-app display
      await _saveNotificationToUser(
        userId: userId,
        title: 'Daily summary',
        body: body,
        type: 'daily_summary',
        data: {
          'totalFavorites': totalFavorites.toString(),
          'itemTitles': itemTitles.join(','),
        },
      );

      print('📤 Daily summary notification sent to: $userId');
    } catch (e) {
      print('❌ Error sending daily summary notification: $e');
    }
  }

  // Send push notification via FCM
  static Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get current user's FCM token
      final currentUser = _auth.currentUser;
      String? currentUserToken;

      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        currentUserToken = userDoc.data()?['fcmToken'];
      }

      // Show local notification ONLY if it's for the current user
      if (currentUserToken != null && currentUserToken == token) {
        await _showCustomNotification(
          title: title,
          body: body,
          data: data,
        );
        print('📱 Local notification shown for current user');
      } else {
        print('📤 Notification for different user - only sending remote push');
      }

      // Always send remote push notification via Firebase Messaging
      await _sendRemotePushNotification(
        token: token,
        title: title,
        body: body,
        data: data,
      );

      print(
          '📝 Remote push notification sent to token: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Send remote push notification via Firebase Messaging
  static Future<void> _sendRemotePushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Save to pending_notifications for server processing
      await _saveToPendingNotifications(token, title, body, data);

      print(
          '📤 Remote push notification queued for token: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error sending remote push notification: $e');
    }
  }

  // Fallback: Save to pending notifications for server processing
  static Future<void> _saveToPendingNotifications(
    String token,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      await _firestore.collection('pending_notifications').add({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('📝 Notification saved to pending for server processing');
    } catch (e) {
      print('❌ Error saving to pending notifications: $e');
    }
  }

  // Show local notification
  static Future<void> _showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default notification channel',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: data?.toString(),
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Save notification to user's notifications collection
  static Future<void> _saveNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('💾 Notification saved to user collection: $userId');
    } catch (e) {
      print('❌ Error saving notification to user: $e');
    }
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Get notifications stream
  static Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🗑️ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  // Helper methods for channel names and descriptions
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Messages';
      case 'favorites':
        return 'Favorites';
      case 'price_updates':
        return 'Price Updates';
      case 'daily_summary':
        return 'Daily Summary';
      default:
        return 'Default';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Notifications for new messages';
      case 'favorites':
        return 'Notifications for favorite updates';
      case 'price_updates':
        return 'Notifications for price changes';
      case 'daily_summary':
        return 'Daily summary of favorites';
      default:
        return 'Default notifications';
    }
  }

  // Public method to check and refresh FCM token
  static Future<String?> getCurrentFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('🔑 Current FCM Token: ${token?.substring(0, 20)}...');

      // Save to database if user is logged in
      final user = _auth.currentUser;
      if (user != null && token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ FCM Token updated in database');
      }

      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Public method to manually refresh token
  static Future<void> refreshFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await getCurrentFCMToken();
      print('🔄 FCM Token refreshed');
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
    }
  }

  // Send ownership verification notification
  static Future<void> sendOwnershipVerificationNotification({
    required String userId,
    required String carId,
    required String carInfo,
  }) async {
    try {
      // Create notification document in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'ownership_verification',
        'title': 'Car Ownership Verification',
        'message':
            'Do you still own $carInfo? Please confirm or your car will be removed from your garage.',
        'carId': carId,
        'carInfo': carInfo,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'requiresAction': true,
      });

      // Send local notification if user is currently using the app
      final user = _auth.currentUser;
      if (user?.uid == userId) {
        await _showCustomLocalNotification(
          id: carId.hashCode,
          title: 'Car Ownership Verification',
          body: 'Do you still own $carInfo?',
          payload: jsonEncode({
            'type': 'ownership_verification',
            'carId': carId,
            'carInfo': carInfo,
          }),
        );
      }

      print('✅ Ownership verification notification sent for car: $carInfo');
    } catch (e) {
      print('❌ Error sending ownership verification notification: $e');
    }
  }

  // Show custom local notification
  static Future<void> _showCustomLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'ownership_verification',
        'Ownership Verification',
        channelDescription: 'Notifications for car ownership verification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing custom local notification: $e');
    }
  }
}
