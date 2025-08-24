import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';
import 'notification_service.dart';

class OwnershipVerificationService {
  static const Duration _verificationInterval = Duration(days: 60); // 2 luni
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifică toate mașinile utilizatorului pentru verificări în curs de expirare
  static Future<void> checkPendingVerifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userCarsSnapshot = await _firestore
          .collection('cars')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      for (final doc in userCarsSnapshot.docs) {
        final carData = doc.data();
        carData['id'] = doc.id;
        final car = Car.fromJson(carData);

        await _checkCarOwnershipVerification(car);
      }
    } catch (e) {
      print('Error checking pending verifications: $e');
    }
  }

  /// Verifică o mașină specifică pentru verificarea proprietății
  static Future<void> _checkCarOwnershipVerification(Car car) async {
    final now = DateTime.now();

    // Dacă nu s-a făcut niciodată verificare, setează prima verificare la 2 luni de la crearea mașinii
    if (car.nextOwnershipVerification == null) {
      final nextVerification = car.createdAt.add(_verificationInterval);

      await _firestore.collection('cars').doc(car.id).update({
        'nextOwnershipVerification': Timestamp.fromDate(nextVerification),
      });

      // Dacă este timpul pentru prima verificare
      if (now.isAfter(nextVerification)) {
        await _showOwnershipVerificationNotification(car);
      }
      return;
    }

    // Verifică dacă este timpul pentru verificare
    if (now.isAfter(car.nextOwnershipVerification!)) {
      await _showOwnershipVerificationNotification(car);
    }
  }

  /// Afișează notificarea de verificare proprietate
  static Future<void> _showOwnershipVerificationNotification(Car car) async {
    await NotificationService.sendOwnershipVerificationNotification(
      userId: car.ownerId,
      carId: car.id,
      carInfo: '${car.brand} ${car.model} - ${car.plateNumber}',
    );
  }

  /// Confirmă că utilizatorul încă deține mașina
  static Future<bool> confirmOwnership(String carId) async {
    try {
      final now = DateTime.now();
      final nextVerification = now.add(_verificationInterval);

      await _firestore.collection('cars').doc(carId).update({
        'lastOwnershipVerification': Timestamp.fromDate(now),
        'nextOwnershipVerification': Timestamp.fromDate(nextVerification),
      });

      return true;
    } catch (e) {
      print('Error confirming ownership: $e');
      return false;
    }
  }

  /// Șterge mașina dacă utilizatorul nu o mai deține
  static Future<bool> declineOwnership(String carId) async {
    try {
      // Șterge mașina din Firestore
      await _firestore.collection('cars').doc(carId).delete();

      // Șterge și din marketplace dacă există
      final marketplaceQuery = await _firestore
          .collection('marketplace_items')
          .where('carId', isEqualTo: carId)
          .get();

      for (final doc in marketplaceQuery.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error declining ownership: $e');
      return false;
    }
  }

  /// Obține mașinile care necesită verificarea proprietății
  static Future<List<Car>> getCarsNeedingVerification(String userId) async {
    try {
      final now = DateTime.now();
      final userCarsSnapshot = await _firestore
          .collection('cars')
          .where('ownerId', isEqualTo: userId)
          .get();

      List<Car> carsNeedingVerification = [];

      for (final doc in userCarsSnapshot.docs) {
        final carData = doc.data();
        carData['id'] = doc.id;
        final car = Car.fromJson(carData);

        // Verifică dacă mașina necesită verificare
        if (car.nextOwnershipVerification == null) {
          // Prima verificare la 2 luni de la creare
          final nextVerification = car.createdAt.add(_verificationInterval);
          if (now.isAfter(nextVerification)) {
            carsNeedingVerification.add(car);
          }
        } else if (now.isAfter(car.nextOwnershipVerification!)) {
          carsNeedingVerification.add(car);
        }
      }

      return carsNeedingVerification;
    } catch (e) {
      print('Error getting cars needing verification: $e');
      return [];
    }
  }

  /// Inițializează verificările pentru o mașină nouă
  static Future<void> initializeOwnershipVerification(String carId) async {
    try {
      final now = DateTime.now();
      final nextVerification = now.add(_verificationInterval);

      await _firestore.collection('cars').doc(carId).update({
        'nextOwnershipVerification': Timestamp.fromDate(nextVerification),
      });
    } catch (e) {
      print('Error initializing ownership verification: $e');
    }
  }

  /// Calculează numărul de zile până la următoarea verificare
  static int getDaysUntilNextVerification(Car car) {
    if (car.nextOwnershipVerification == null) {
      final nextVerification = car.createdAt.add(_verificationInterval);
      final difference = nextVerification.difference(DateTime.now());
      return difference.inDays;
    }

    final difference =
        car.nextOwnershipVerification!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Verifică dacă o mașină necesită verificare în următoarele 7 zile
  static bool needsVerificationSoon(Car car) {
    final daysUntilVerification = getDaysUntilNextVerification(car);
    return daysUntilVerification <= 7 && daysUntilVerification >= 0;
  }

  /// Verifică dacă o mașină are verificarea expirată
  static bool hasExpiredVerification(Car car) {
    final daysUntilVerification = getDaysUntilNextVerification(car);
    return daysUntilVerification < 0;
  }
}
