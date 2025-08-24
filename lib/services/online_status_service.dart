import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnlineStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Set user as online with current timestamp
  static Future<void> setUserOnline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('🟢 User set as online: ${user.uid}');
    } catch (e) {
      print('❌ Error setting user online: $e');
    }
  }
  
  /// Set user as offline with last seen timestamp
  static Future<void> setUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      print('🔴 User set as offline: ${user.uid}');
    } catch (e) {
      print('❌ Error setting user offline: $e');
    }
  }
  
  /// Update user's last seen timestamp (heartbeat)
  static Future<void> updateUserHeartbeat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      // Optionally update online status if it's been more than 2 minutes
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final isOnline = data['isOnline'] ?? false;
        if (!isOnline) {
          await setUserOnline();
        }
      }
    } catch (e) {
      print('❌ Error updating heartbeat: $e');
    }
  }
  
  /// Check if a user is currently online
  static Future<bool> isUserOnline(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final data = userDoc.data()!;
      final isOnline = data['isOnline'] ?? false;
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
      
      if (!isOnline) return false;
      
      // Check if last seen is within the last 5 minutes
      if (lastSeen != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);
        return difference.inMinutes < 5;
      }
      
      return false;
    } catch (e) {
      print('❌ Error checking user online status: $e');
      return false;
    }
  }
  
  /// Get user's last seen time
  static Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data()!;
      return (data['lastSeen'] as Timestamp?)?.toDate();
    } catch (e) {
      print('❌ Error getting user last seen: $e');
      return null;
    }
  }
  
  /// Stream user's online status for real-time updates
  static Stream<bool> userOnlineStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data()!;
      final isOnline = data['isOnline'] ?? false;
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
      
      if (!isOnline) return false;
      
      // Check if last seen is within the last 5 minutes
      if (lastSeen != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);
        return difference.inMinutes < 5;
      }
      
      return false;
    });
  }
  
  /// Initialize online status monitoring (call when app starts)
  static void initializeOnlineStatus() {
    // Set user as online when app starts
    setUserOnline();
    
    // Listen for auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        setUserOnline();
      }
    });
  }
  
  /// Cleanup when app goes to background or closes
  static void cleanup() {
    setUserOffline();
  }
}
