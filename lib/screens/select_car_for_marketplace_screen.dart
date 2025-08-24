import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../screens/add_car_screen.dart';

const Color oliveColor = Color(0xFF808000);

class SelectCarForMarketplaceScreen extends StatefulWidget {
  const SelectCarForMarketplaceScreen({super.key});

  @override
  State<SelectCarForMarketplaceScreen> createState() =>
      _SelectCarForMarketplaceScreenState();
}

class _SelectCarForMarketplaceScreenState
    extends State<SelectCarForMarketplaceScreen> {
  bool _isLoading = true;
  List<Car> _userCars = [];
  Map<String, bool> _marketplaceStatus =
      {}; // Store marketplace status for each car

  @override
  void initState() {
    super.initState();
    _loadUserCars();
  }

  Future<void> _loadUserCars() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cars = await CarService.getUserCars(user.uid);

        // Check marketplace status for each car
        Map<String, bool> statusMap = {};
        for (Car car in cars) {
          bool isInMarketplace = await CarService.isCarInMarketplace(car.id);
          statusMap[car.id] = isInMarketplace;
        }

        setState(() {
          _userCars = cars;
          _marketplaceStatus = statusMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                    child:
                        Text('Connection issue. Please check your internet.')),
              ],
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _navigateToAddCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCarScreen(),
      ),
    ).then((_) {
      // Refresh the car list when returning from add car screen
      _loadUserCars();
    });
  }

  void _selectCar(Car car) async {
    bool isInMarketplace = _marketplaceStatus[car.id] ?? false;

    if (isInMarketplace) {
      // Show options for already listed cars (edit or view status)
      _showListedCarOptions(car);
    } else {
      // Navigate to edit car for non-listed cars
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCarScreen(carToEdit: car),
        ),
      ).then((_) {
        // Refresh the car list when returning
        _loadUserCars();
      });
    }
  }

  void _showListedCarOptions(Car car) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.blue[600],
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Manage Listing',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your ${car.brand} ${car.model} is currently listed in the marketplace.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to edit the listed car
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCarScreen(carToEdit: car),
                  ),
                ).then((_) {
                  // Refresh the car list when returning
                  _loadUserCars();
                });
              },
              icon: Icon(
                Icons.edit,
                size: 18.w,
                color: oliveColor,
              ),
              label: Text(
                'Edit Car',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: oliveColor,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Select Car for Marketplace',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userCars.isEmpty
              ? _buildEmptyState()
              : _buildCarList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
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
            'No Cars in My Garage',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'You need to add a car to your garage before you can list it in the marketplace.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToAddCar,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Car'),
              style: ElevatedButton.styleFrom(
                backgroundColor: oliveColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: oliveColor),
              foregroundColor: oliveColor,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          color: oliveColor.withOpacity(0.1),
          child: Text(
            'Select a car to edit for marketplace listing. Cars already listed will show their status.',
            style: TextStyle(
              fontSize: 14.sp,
              color: oliveColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _userCars.length,
            itemBuilder: (context, index) {
              final car = _userCars[index];
              return _buildCarCard(car);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToAddCar,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Car'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: oliveColor),
                    foregroundColor: oliveColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(Car car) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
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
          // Status badge
          if (_marketplaceStatus[car.id] == true)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14.w,
                    color: Colors.green[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Listed in Marketplace',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Car image placeholder or first image
              Container(
                width: 80.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: car.images != null && car.images!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          car.images!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_car,
                              size: 32.sp,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.directions_car,
                        size: 32.sp,
                        color: Colors.grey.shade400,
                      ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.brand} ${car.model}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            car.plateNumber,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (car.year != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            '${car.year}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (car.mileage != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${car.mileage} km',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: _buildCarActionButton(car),
          ),
        ],
      ),
    );
  }

  Widget _buildCarActionButton(Car car) {
    bool isInMarketplace = _marketplaceStatus[car.id] ?? false;

    if (isInMarketplace) {
      // Show edit button for already listed cars
      return ElevatedButton.icon(
        onPressed: () => _selectCar(car),
        icon: Icon(
          Icons.edit,
          size: 16.w,
        ),
        label: Text(
          'Edit Listed Car',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    } else {
      // Show active edit button for non-listed cars
      return ElevatedButton.icon(
        onPressed: () => _selectCar(car),
        icon: Icon(
          Icons.edit,
          size: 16.w,
        ),
        label: Text(
          'Edit This Car',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: oliveColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }
}
