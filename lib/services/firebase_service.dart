import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/vehicle_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String vehiclesCollection = 'vehicles';
  static const String accessoriesCollection = 'accessories';
  static const String servicesCollection = 'services';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String transferRequestsCollection = 'transfer_requests';

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Authentication
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateUserFCMToken();
      return result.user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await _createUserDocument(result.user!, displayName);
        await _updateUserFCMToken();
      }
      
      return result.user;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User Management
  Future<void> _createUserDocument(User user, String displayName) async {
    await _firestore.collection(usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'subscription': 'basic',
      'fcmToken': null,
    });
  }

  Future<void> _updateUserFCMToken() async {
    if (currentUser == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection(usersCollection).doc(currentUser!.uid).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Vehicle Management
  Future<String> addVehicle(VehicleModel vehicle) async {
    if (currentUser == null) throw Exception('User not logged in');

    try {
      // Check if license plate already exists
      final existing = await _firestore
          .collection(vehiclesCollection)
          .where('licensePlate', isEqualTo: vehicle.licensePlate)
          .where('countryCode', isEqualTo: vehicle.countryCode)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingVehicle = existing.docs.first;
        if (existingVehicle.data()['ownerId'] == currentUser!.uid) {
          throw Exception('You already own this vehicle');
        } else {
          // Create transfer request
          await _createTransferRequest(
            vehicleId: existingVehicle.id,
            fromUserId: existingVehicle.data()['ownerId'],
            toUserId: currentUser!.uid,
            licensePlate: vehicle.licensePlate,
            countryCode: vehicle.countryCode,
          );
          throw Exception('Vehicle already registered. Transfer request sent to current owner.');
        }
      }

      // Add new vehicle
      final docRef = await _firestore.collection(vehiclesCollection).add({
        ...vehicle.toJson(),
        'ownerId': currentUser!.uid,
        'ownerName': currentUser!.displayName ?? 'Unknown',
        'ownerEmail': currentUser!.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createTransferRequest({
    required String vehicleId,
    required String fromUserId,
    required String toUserId,
    required String licensePlate,
    required String countryCode,
  }) async {
    await _firestore.collection(transferRequestsCollection).add({
      'vehicleId': vehicleId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'licensePlate': licensePlate,
      'countryCode': countryCode,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to current owner
    // TODO: Implement push notification
  }

  // Search Vehicles
  Future<List<VehicleModel>> searchVehicles({
    String? query,
    String? countryCode,
    int limit = 20,
  }) async {
    try {
      Query vehiclesQuery = _firestore
          .collection(vehiclesCollection)
          .where('isActive', isEqualTo: true);

      if (countryCode != null) {
        vehiclesQuery = vehiclesQuery.where('countryCode', isEqualTo: countryCode);
      }

      if (query != null && query.isNotEmpty) {
        // Search by license plate
        vehiclesQuery = vehiclesQuery
            .where('licensePlate', isGreaterThanOrEqualTo: query.toUpperCase())
            .where('licensePlate', isLessThanOrEqualTo: '${query.toUpperCase()}\uf8ff');
      }

      final QuerySnapshot snapshot = await vehiclesQuery.limit(limit).get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Search failed: ${e.toString()}');
    }
  }

  // Get user's vehicles
  Future<List<VehicleModel>> getUserVehicles() async {
    if (currentUser == null) return [];

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(vehiclesCollection)
          .where('ownerId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get vehicles: ${e.toString()}');
    }
  }

  // Update vehicle views
  Future<void> incrementVehicleViews(String vehicleId) async {
    try {
      await _firestore.collection(vehiclesCollection).doc(vehicleId).update({
        'views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating views: $e');
    }
  }

  // Chat Management
  Future<String> createOrGetChat({
    required String licensePlate,
    required String countryCode,
    String? participantId,
  }) async {
    try {
      // Find vehicle
      final vehicleQuery = await _firestore
          .collection(vehiclesCollection)
          .where('licensePlate', isEqualTo: licensePlate)
          .where('countryCode', isEqualTo: countryCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (vehicleQuery.docs.isEmpty) {
        throw Exception('Vehicle not found');
      }

      final vehicle = vehicleQuery.docs.first;
      final ownerId = vehicle.data()['ownerId'];

      if (currentUser == null) {
        // Guest chat - create temporary chat
        final chatRef = await _firestore.collection(chatsCollection).add({
          'vehicleId': vehicle.id,
          'vehicleLicensePlate': licensePlate,
          'vehicleCountryCode': countryCode,
          'ownerId': ownerId,
          'guestId': 'guest_${DateTime.now().millisecondsSinceEpoch}',
          'isGuestChat': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
        });
        return chatRef.id;
      } else {
        // Authenticated user chat
        final chatQuery = await _firestore
            .collection(chatsCollection)
            .where('vehicleId', isEqualTo: vehicle.id)
            .where('participants', arrayContains: currentUser!.uid)
            .get();

        if (chatQuery.docs.isNotEmpty) {
          return chatQuery.docs.first.id;
        }

        // Create new chat
        final chatRef = await _firestore.collection(chatsCollection).add({
          'vehicleId': vehicle.id,
          'vehicleLicensePlate': licensePlate,
          'vehicleCountryCode': countryCode,
          'participants': [currentUser!.uid, ownerId],
          'ownerId': ownerId,
          'isGuestChat': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
        });
        return chatRef.id;
      }
    } catch (e) {
      throw Exception('Failed to create chat: ${e.toString()}');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    String? senderId,
    String? senderName,
  }) async {
    try {
      final messageData = {
        'chatId': chatId,
        'message': message,
        'senderId': currentUser?.uid ?? senderId ?? 'guest',
        'senderName': currentUser?.displayName ?? senderName ?? 'Guest',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .add(messageData);

      // Update chat's last message
      await _firestore.collection(chatsCollection).doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send push notification
      // TODO: Implement push notification to other participants
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // FCM Token Management
  Future<void> requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _updateUserFCMToken();
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Subscription Management
  Future<Map<String, dynamic>?> getUserSubscription() async {
    if (currentUser == null) return null;

    try {
      final userDoc = await _firestore.collection(usersCollection).doc(currentUser!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'subscription': data['subscription'] ?? 'basic',
          'subscriptionExpiry': data['subscriptionExpiry'],
          'features': _getSubscriptionFeatures(data['subscription'] ?? 'basic'),
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get subscription: ${e.toString()}');
    }
  }

  List<String> _getSubscriptionFeatures(String subscription) {
    switch (subscription) {
      case 'premium':
        return ['cars', 'accessories', 'services', 'analytics'];
      case 'pro':
        return ['cars', 'accessories', 'services', 'analytics', 'promotion', 'priority_support'];
      default:
        return ['cars'];
    }
  }

  Future<void> updateSubscription(String subscription) async {
    if (currentUser == null) throw Exception('User not logged in');

    await _firestore.collection(usersCollection).doc(currentUser!.uid).update({
      'subscription': subscription,
      'subscriptionExpiry': DateTime.now().add(const Duration(days: 30)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Marketplace
  Future<List<Map<String, dynamic>>> getMarketplaceItems({
    String? category,
    String? filter,
    int limit = 20,
  }) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd query different collections based on category
      
      final QuerySnapshot snapshot = await _firestore
          .collection(vehiclesCollection)
          .where('isActive', isEqualTo: true)
          .where('isForSale', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'type': 'vehicle',
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get marketplace items: ${e.toString()}');
    }
  }
}
