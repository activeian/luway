import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/country_service.dart';
import '../services/ownership_verification_service.dart';
import '../widgets/ownership_verification_card.dart';
import 'add_car_screen.dart';

const Color oliveColor = Color(0xFFB3B760);

class MyGarageScreen extends StatefulWidget {
  const MyGarageScreen({super.key});

  @override
  State<MyGarageScreen> createState() => _MyGarageScreenState();
}

class _MyGarageScreenState extends State<MyGarageScreen> {
  List<Car> _myCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyCars();
    _checkOwnershipVerifications();
  }

  Future<void> _checkOwnershipVerifications() async {
    try {
      await OwnershipVerificationService.checkPendingVerifications();
    } catch (e) {
      print('Error checking ownership verifications: $e');
    }
  }

  Future<void> _loadMyCars() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('MyGarageScreen: Current user: ${user?.uid}');

      if (user != null) {
        print('MyGarageScreen: Loading cars for user ${user.uid}');

        // First, let's check all cars in the collection for debugging
        final allCarsSnapshot =
            await FirebaseFirestore.instance.collection('cars').get();
        print(
            'MyGarageScreen: Total cars in collection: ${allCarsSnapshot.docs.length}');

        for (final doc in allCarsSnapshot.docs) {
          final data = doc.data();
          print(
              'MyGarageScreen: Car ${doc.id}: ownerId=${data['ownerId']}, plate=${data['plateNumber'] ?? 'No plate'}');
        }

        // Now get user-specific cars
        final cars = await CarService.getUserCars(user.uid);
        print('MyGarageScreen: Loaded ${cars.length} cars for user');

        // Initialize ownership verification for cars that don't have it
        await _initializeOwnershipVerification(cars);

        setState(() {
          _myCars = cars;
          _isLoading = false;
        });
      } else {
        print('MyGarageScreen: No user authenticated');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('MyGarageScreen: Error loading cars: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cars: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeOwnershipVerification(List<Car> cars) async {
    try {
      for (final car in cars) {
        if (car.nextOwnershipVerification == null) {
          // Initialize verification for cars that don't have it set
          final now = DateTime.now();
          final nextVerification =
              now.add(const Duration(days: 60)); // 2 months from now

          // Update car with initial verification dates
          await FirebaseFirestore.instance
              .collection('cars')
              .doc(car.id)
              .update({
            'lastOwnershipVerification': now,
            'nextOwnershipVerification': nextVerification,
          });

          print(
              'Initialized ownership verification for car ${car.plateNumber}');
        }
      }
    } catch (e) {
      print('Error initializing ownership verification: $e');
    }
  }

  Future<void> _deleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.plateNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CarService.deleteCar(car.id);
        _loadMyCars(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Car deleted successfully. Marketplace listing also removed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting car: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCar(Car car) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCarScreen(carToEdit: car),
      ),
    );

    if (result == true) {
      _loadMyCars(); // Refresh if car was updated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Garage',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: oliveColor),
            onPressed: () async {
              // Navigate to Add Car screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCarScreen()),
              );

              if (result == true) {
                _loadMyCars(); // Refresh if car was added
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFFB3B760),
            ))
          : _myCars.isEmpty
              ? _buildEmptyState()
              : _buildCarsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.garage,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24.h),
            Text(
              'Your garage is empty',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add your first car to get started',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCarScreen()),
                );

                if (result == true) {
                  _loadMyCars(); // Refresh if car was added
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Add Your First Car',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarsList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyCars();
        await _checkOwnershipVerifications();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _myCars.length,
        itemBuilder: (context, index) {
          final car = _myCars[index];
          return Column(
            children: [
              // Ownership verification card (if needed)
              OwnershipVerificationCard(
                car: car,
                onCarRemoved: () {
                  _loadMyCars(); // Refresh list when car is removed
                },
                onCarVerified: () {
                  _loadMyCars(); // Refresh list when car is verified
                },
              ),
              // Regular car card
              _buildCarCard(car),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    final country = CountryService.getCountryByCode(car.countryCode);
    final daysUntilVerification =
        OwnershipVerificationService.getDaysUntilNextVerification(car);
    final isExpired = OwnershipVerificationService.hasExpiredVerification(car);
    final needsSoon = OwnershipVerificationService.needsVerificationSoon(car);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car Image
          if (car.images != null && car.images!.isNotEmpty)
            Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                image: DecorationImage(
                  image: NetworkImage(car.images!.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Header with license plate and actions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: car.images != null && car.images!.isNotEmpty
                  ? BorderRadius.zero
                  : BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                // Country flag and license plate
                Row(
                  children: [
                    if (country != null) ...[
                      Text(
                        country.flag,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        car.plateNumber.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    // Ownership verification indicator
                    if (isExpired || needsSoon) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color:
                              isExpired ? Colors.red[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: isExpired
                                ? Colors.red[300]!
                                : Colors.orange[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpired ? Icons.warning : Icons.access_time,
                              size: 12.sp,
                              color: isExpired
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              isExpired
                                  ? 'Verify'
                                  : '${daysUntilVerification}d',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                // Action buttons
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCar(car);
                    } else if (value == 'delete') {
                      _deleteCar(car);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: oliveColor),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Car details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand and model
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 20.sp, color: oliveColor),
                    SizedBox(width: 8.w),
                    Text(
                      '${car.brand} ${car.model}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Additional details if available
                if (car.isForSale) ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      car.price != null
                          ? 'FOR SALE - €${car.price!.toStringAsFixed(0)}'
                          : 'FOR SALE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (car.year != null)
                    _buildDetailRow('Year', car.year.toString()),
                  if (car.mileage != null)
                    _buildDetailRow('Mileage', '${car.mileage} km'),
                  if (car.fuelType != null)
                    _buildDetailRow('Fuel', car.fuelType!),
                ] else ...[
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'NOT FOR SALE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 12.h),

                // Added date and verification status
                Row(
                  children: [
                    Text(
                      'Added: ${_formatDate(car.createdAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (car.lastOwnershipVerification != null) ...[
                      SizedBox(width: 16.w),
                      Text(
                        'Verified: ${_formatDate(car.lastOwnershipVerification!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),

                // Next verification info (if applicable)
                if (car.nextOwnershipVerification != null &&
                    !isExpired &&
                    !needsSoon)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'Next verification: ${_formatDate(car.nextOwnershipVerification!)} (${daysUntilVerification} days)',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
