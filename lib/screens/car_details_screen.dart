import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import '../models/marketplace_item.dart';
import '../services/country_service.dart';
import '../screens/marketplace_item_detail_screen.dart';
import 'chat_screen.dart';

const Color oliveColor = Color(0xFFB3B760);

class CarDetailsScreen extends StatelessWidget {
  final Car car;

  const CarDetailsScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final country = CountryService.getCountryByCode(car.countryCode);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnCar = currentUser?.uid == car.ownerId;

    // Debug: Print car images
    print('Car images: ${car.images}');
    print('Car images length: ${car.images?.length ?? 0}');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Car Details',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    oliveColor.withOpacity(0.1),
                    oliveColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // License plate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (country != null) ...[
                        Text(
                          country.flag,
                          style: TextStyle(fontSize: 32.sp),
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          car.plateNumber.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Car image (first image if available)
                  if (car.images != null && car.images!.isNotEmpty) ...[
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          car.images!.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading car image: $error');
                            print('Image URL: ${car.images!.first}');
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.car_rental,
                                      size: 64.sp,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Image not available',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'URL: ${car.images!.first}',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ] else ...[
                    // Show placeholder when no images
                    Container(
                      height: 200.h,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 64.sp,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No images available',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  
                  // Brand and model
                  Text(
                    '${car.brand} ${car.model}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // For sale status
                  if (car.isForSale) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sell,
                            size: 16.sp,
                            color: Colors.green.shade700,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            car.price != null 
                                ? 'FOR SALE - €${car.price!.toStringAsFixed(0)}'
                                : 'FOR SALE',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // View Listing button for cars that are for sale
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () => _viewMarketplaceListing(context, car),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8FBC8F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'NOT FOR SALE',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Car details
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Car Information',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Details grid
                  if (car.year != null)
                    _buildDetailRow('Year', car.year.toString(), Icons.calendar_today),
                  
                  if (car.mileage != null)
                    _buildDetailRow('Mileage', '${car.mileage} km', Icons.speed),
                  
                  if (car.fuelType != null)
                    _buildDetailRow('Fuel Type', car.fuelType!, Icons.local_gas_station),
                  
                  if (car.engine != null)
                    _buildDetailRow('Engine', car.engine!, Icons.build),
                  
                  if (car.color != null)
                    _buildDetailRow('Color', car.color!, Icons.palette),
                  
                  _buildDetailRow('Country', country?.name ?? 'Unknown', Icons.flag),
                  
                  _buildDetailRow('Added', _formatDate(car.createdAt), Icons.access_time),
                  
                  if (car.description != null && car.description!.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        car.description!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Contact buttons (only show if not own car)
      bottomNavigationBar: !isOwnCar ? Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Owner',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                // Chat button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatConversationScreen(
                              receiverId: car.ownerId,
                              carPlateNumber: car.plateNumber,
                              carBrand: '${car.brand} ${car.model}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to contact the owner'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oliveColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                
                if (car.phone != null && car.phone!.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  // Phone button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callPhone(context, car.phone!),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ) : null,
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: oliveColor,
          ),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Show phone number if can't launch
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone: $phoneNumber'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy phone number to clipboard
                Clipboard.setData(ClipboardData(text: phoneNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error launching phone: $e');
      // Show phone number when error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone: $phoneNumber'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // Copy phone number to clipboard
              Clipboard.setData(ClipboardData(text: phoneNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _viewMarketplaceListing(BuildContext context, Car car) async {
    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view marketplace listings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('Searching for marketplace listing for car ID: ${car.id}');
      
      // Search for marketplace item with this car's ID
      final marketplaceQuery = await FirebaseFirestore.instance
          .collection('marketplace')
          .where('carId', isEqualTo: car.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      print('Marketplace query completed. Found ${marketplaceQuery.docs.length} results');
      
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);
      
      if (marketplaceQuery.docs.isNotEmpty) {
        final doc = marketplaceQuery.docs.first;
        final itemData = doc.data();
        final marketplaceItem = MarketplaceItem.fromJson(doc.id, itemData);
        
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketplaceItemDetailScreen(item: marketplaceItem),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Marketplace listing not found for this car'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);
      
      print('Error loading marketplace listing: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading listing: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
