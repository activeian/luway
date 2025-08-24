import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Test script to check user cars in Firestore
void main() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user authenticated');
      return;
    }
    
    print('Testing garage for user: ${user.uid}');
    
    final firestore = FirebaseFirestore.instance;
    
    // Get all cars for this user
    final query = await firestore
        .collection('cars')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    
    print('Found ${query.docs.length} cars');
    
    for (final doc in query.docs) {
      final data = doc.data();
      print('Car ${doc.id}: ${data}');
    }
    
    // Also check all cars in collection (to see what's there)
    final allCars = await firestore.collection('cars').get();
    print('\nAll cars in collection: ${allCars.docs.length}');
    
    for (final doc in allCars.docs) {
      final data = doc.data();
      print('Car ${doc.id}: ownerId=${data['ownerId']}, plate=${data['plateNumber']}');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
