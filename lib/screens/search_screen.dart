import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/country_service.dart';
import 'car_details_screen.dart';

const Color oliveColor = Color(0xFF808000);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Car> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCars() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final cars = await CarService.searchCars(query);

      // Filter out current user's cars
      final filteredCars =
          cars.where((car) => car.ownerId != currentUser?.uid).toList();

      setState(() {
        _searchResults = filteredCars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching cars: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Search Cars',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by plate number, brand, or model...',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: oliveColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                    onSubmitted: (_) => _searchCars(),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: _searchCars,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oliveColor,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Search',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Color(0xFFB3B760),
      ));
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final car = _searchResults[index];
        return _buildCarCard(car);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24.h),
            Text(
              'Search for cars',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Enter a plate number, brand, or model to find cars',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24.h),
            Text(
              'No cars found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    final country = CountryService.getCountryByCode(car.countryCode);

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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailsScreen(car: car),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License plate and country
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
                  const Spacer(),
                  if (car.isForSale)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'FOR SALE',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12.h),

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

              if (car.isForSale && car.price != null) ...[
                SizedBox(height: 8.h),
                Text(
                  '€${car.price!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],

              SizedBox(height: 12.h),

              // Additional details
              Row(
                children: [
                  if (car.year != null) ...[
                    _buildDetailChip('${car.year}'),
                    SizedBox(width: 8.w),
                  ],
                  if (car.fuelType != null) ...[
                    _buildDetailChip(car.fuelType!),
                    SizedBox(width: 8.w),
                  ],
                  if (car.mileage != null)
                    _buildDetailChip('${car.mileage} km'),
                ],
              ),

              SizedBox(height: 12.h),

              // View details button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: oliveColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.sp,
                    color: oliveColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
