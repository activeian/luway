import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_item.dart';
import '../services/favorites_service.dart';
import '../services/user_behavior_service.dart';
import '../services/marketplace_service.dart';
import '../services/view_tracking_service.dart';
import '../services/distance_service.dart';
import '../services/map_launcher_service.dart';
import '../screens/chat_screen.dart';
import '../screens/add_review_screen.dart';
import '../screens/add_car_screen.dart';
import '../screens/boost_center_screen.dart';
import '../screens/fullscreen_image_gallery.dart';
import '../models/car.dart';

class MarketplaceItemDetailScreen extends StatefulWidget {
  final MarketplaceItem item;

  const MarketplaceItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<MarketplaceItemDetailScreen> createState() =>
      _MarketplaceItemDetailScreenState();
}

class _MarketplaceItemDetailScreenState
    extends State<MarketplaceItemDetailScreen> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  String? _phoneFromGarage;
  int _totalViews = 0;
  int _todayViews = 0;
  bool _isLoadingViews = true;
  MarketplaceItem? _refreshedItem; // Store refreshed item data
  String? _sellerNickname; // Store seller's nickname

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _trackView();
    _loadPhoneFromGarage();
    _loadViewData();
    _loadSellerNickname();
  }

  // Get the current item (refreshed if available, otherwise original)
  MarketplaceItem get currentItem => _refreshedItem ?? widget.item;

  Future<void> _refreshMarketplaceItem() async {
    try {
      print('🔄 Refreshing marketplace item ${widget.item.id}...');

      // If this marketplace item is linked to a car in garage, sync it first
      if (currentItem.carId != null) {
        print('🔗 Syncing car ${currentItem.carId} to marketplace...');
        await MarketplaceService.syncCarToMarketplace(
            currentItem.carId!, widget.item.id);
        print('✅ Car synced to marketplace successfully');
      }

      // Fetch updated marketplace item from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(widget.item.id)
          .get();

      if (doc.exists) {
        final updatedItem = MarketplaceItem.fromJson(
            doc.id, doc.data() as Map<String, dynamic>);
        setState(() {
          _refreshedItem = updatedItem;
        });
        print('✅ Marketplace item refreshed successfully');
        print('📝 New title: ${updatedItem.title}');
        print('📸 New images: ${updatedItem.images.length} images');
        print(
            '🔧 Equipment fields: ${updatedItem.details.keys.where((k) => k.startsWith('has')).length} equipment items');
      } else {
        print('⚠️ Marketplace item not found during refresh');
      }
    } catch (e) {
      print('❌ Error refreshing marketplace item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadViewData() async {
    try {
      print('🔍 Loading view data for item: ${currentItem.id}');

      // Load total unique views (distinct users)
      final allViewsSnapshot = await FirebaseFirestore.instance
          .collection('item_views')
          .where('itemId', isEqualTo: currentItem.id)
          .get();

      print('📊 Found ${allViewsSnapshot.docs.length} total view records');

      // Count unique viewers
      final uniqueViewers = <String>{};
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayUniqueViewers = <String>{};

      for (var doc in allViewsSnapshot.docs) {
        final data = doc.data();
        print('📝 View record: $data');

        // ViewTrackingService uses 'viewerUserId', not 'viewerId'
        final viewerId =
            data['viewerUserId'] as String? ?? data['viewerId'] as String?;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (viewerId != null) {
          uniqueViewers.add(viewerId);

          // Check if view is from today
          if (timestamp != null && timestamp.isAfter(todayStart)) {
            todayUniqueViewers.add(viewerId);
          }
        }
      }

      print(
          '👥 Unique viewers: ${uniqueViewers.length}, Today: ${todayUniqueViewers.length}');

      setState(() {
        _totalViews = uniqueViewers.length;
        _todayViews = todayUniqueViewers.length;
        _isLoadingViews = false;
      });
    } catch (e) {
      print('❌ Error loading view data: $e');
      setState(() {
        _isLoadingViews = false;
      });
    }
  }

  Future<void> _loadPhoneFromGarage() async {
    if (currentItem.carId != null) {
      try {
        // Load car data from My Garage to get phone number
        final carData = await FirebaseFirestore.instance
            .collection('cars')
            .doc(currentItem.carId)
            .get();

        if (carData.exists) {
          final data = carData.data();
          setState(() {
            _phoneFromGarage =
                data?['phone']; // Fixed: use 'phone' not 'phoneNumber'
          });
          print('Loaded phone from garage: $_phoneFromGarage');
        } else {
          print('Car document not found for carId: ${currentItem.carId}');
        }
      } catch (e) {
        print('Error loading phone from garage: $e');
      }
    } else {
      print('No carId available in marketplace item');
    }
  }

  Future<void> _loadSellerNickname() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentItem.sellerId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _sellerNickname = userData?['nickname'];
        });
        print('Loaded seller nickname: $_sellerNickname');
      }
    } catch (e) {
      print('Error loading seller nickname: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(currentItem.id);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _trackView() async {
    try {
      print('🚀 Starting view tracking for item: ${currentItem.id}');
      print('📝 Current user: ${FirebaseAuth.instance.currentUser?.uid}');
      print('👤 Item owner: ${currentItem.sellerId}');

      await UserBehaviorService.trackItemView(currentItem.id, currentItem);
      print('✅ UserBehaviorService tracking completed');

      // Also track in the new ViewTrackingService
      await ViewTrackingService.trackItemView(
        itemId: currentItem.id,
        itemOwnerId: currentItem.sellerId,
      );
      print('✅ ViewTrackingService tracking completed');
    } catch (e) {
      print('❌ Error in _trackView: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final success = await FavoritesService.toggleFavorite(currentItem.id);
    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  static Future<void> _callPhone(
      BuildContext context, String phoneNumber) async {
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

  String _getItemTypeDisplay() {
    switch (currentItem.type) {
      case MarketplaceItemType.car:
        return 'Car';
      case MarketplaceItemType.accessory:
        return 'Accessory';
      case MarketplaceItemType.service:
        return 'Service';
    }
  }

  String _translateDetailKey(String key) {
    final translations = {
      // Romanian to English translations
      'Anul': 'Year',
      'An': 'Year',
      'Kilometri': 'Mileage',
      'Km': 'Mileage',
      'Combustibil': 'Fuel',
      'Transmisie': 'Transmission',
      'Motor': 'Engine',
      'Culoare': 'Color',
      'Marca': 'Brand',
      'Model': 'Model',
      'Tip': 'Type',
      'Stare': 'Condition',
      'Locație': 'Location',
      'Preț': 'Price',
      // Extended car details
      'bodyType': 'Body Type',
      'doors': 'Doors',
      'condition': 'Condition',
      'power': 'Power (HP)',
      'vin': 'VIN',
      'previousOwners': 'Previous Owners',
      'hasServiceHistory': 'Service History',
      'hasAccidentHistory': 'Accident History',
      'urgencyLevel': 'Urgency Level',
      'isPriceNegotiable': 'Price Negotiable',
      'notes': 'Notes',
      // Safety equipment
      'hasABS': 'ABS',
      'hasESP': 'ESP',
      'hasAirbags': 'Airbags',
      'hasAlarm': 'Alarm System',
      // Comfort equipment
      'hasAirConditioning': 'Air Conditioning',
      'hasHeatedSeats': 'Heated Seats',
      'hasNavigation': 'Navigation System',
      'hasBluetooth': 'Bluetooth',
      'hasUSB': 'USB Ports',
      'hasLeatherSteering': 'Leather Steering Wheel',
      // Exterior equipment
      'hasAlloyWheels': 'Alloy Wheels',
      'hasSunroof': 'Sunroof',
      'hasXenonLights': 'Xenon Lights',
      'hasElectricMirrors': 'Electric Mirrors',
    };

    return translations[key] ?? key;
  }

  bool _isOwner() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == currentItem.sellerId;
  }

  void _editItem() async {
    // Navigate to Edit Car if it's a car from garage
    if (currentItem.carId != null) {
      try {
        // Load car data from My Garage
        final carData = await FirebaseFirestore.instance
            .collection('cars')
            .doc(currentItem.carId)
            .get();

        if (carData.exists) {
          final data = carData.data()!;
          data['id'] = currentItem.carId; // Add the ID to the data
          final car = Car.fromJson(data);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCarScreen(carToEdit: car),
            ),
          ).then((_) {
            // Refresh the marketplace item after editing
            _refreshMarketplaceItem();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Car not found in garage'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading car: $e'),
          ),
        );
      }
    } else {
      // TODO: Navigate to edit screen for other items
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit functionality coming soon for this item type'),
        ),
      );
    }
  }

  void _promoteItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoostCenterScreen(item: currentItem),
      ),
    );
  }

  void _navigateToAddReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(item: currentItem),
      ),
    );
  }

  bool _canLeaveReview() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid != currentItem.sellerId;
  }

  List<Widget> _buildOrganizedDetails() {
    final details = currentItem.details;
    List<Widget> widgets = [];

    // Basic Information
    final basicInfo = <String, dynamic>{};
    final basicKeys = [
      'brand',
      'model',
      'year',
      'plateNumber',
      'countryCode',
      'bodyType',
      'doors',
      'color',
      'condition'
    ];

    for (String key in basicKeys) {
      if (details[key] != null && details[key].toString().isNotEmpty) {
        basicInfo[key] = details[key];
      }
    }

    if (basicInfo.isNotEmpty) {
      widgets.add(_buildDetailSection(
          'Basic Information', basicInfo, Icons.directions_car));
    }

    // Performance & Technical
    final performanceInfo = <String, dynamic>{};
    final performanceKeys = [
      'mileage',
      'fuelType',
      'transmission',
      'engine',
      'power',
      'vin'
    ];

    for (String key in performanceKeys) {
      if (details[key] != null && details[key].toString().isNotEmpty) {
        performanceInfo[key] = details[key];
      }
    }

    if (performanceInfo.isNotEmpty) {
      widgets.add(_buildDetailSection(
          'Performance & Technical', performanceInfo, Icons.speed));
    }

    // History & Status
    final historyInfo = <String, dynamic>{};
    final historyKeys = [
      'previousOwners',
      'hasServiceHistory',
      'hasAccidentHistory',
      'urgencyLevel',
      'isPriceNegotiable',
      'notes'
    ];

    for (String key in historyKeys) {
      if (details[key] != null) {
        if (key == 'hasServiceHistory' ||
            key == 'hasAccidentHistory' ||
            key == 'isPriceNegotiable') {
          if (details[key] == true) {
            historyInfo[key] = details[key];
          }
        } else if (details[key].toString().isNotEmpty) {
          historyInfo[key] = details[key];
        }
      }
    }

    if (historyInfo.isNotEmpty) {
      widgets.add(
          _buildDetailSection('History & Status', historyInfo, Icons.history));
    }

    // Safety Equipment
    final safetyEquipment = <String, dynamic>{};
    final safetyKeys = ['hasABS', 'hasESP', 'hasAirbags', 'hasAlarm'];

    for (String key in safetyKeys) {
      if (details[key] == true) {
        safetyEquipment[key] = details[key];
      }
    }

    if (safetyEquipment.isNotEmpty) {
      widgets.add(_buildEquipmentSection(
          'Safety Equipment', safetyEquipment, Icons.security));
    }

    // Comfort Equipment
    final comfortEquipment = <String, dynamic>{};
    final comfortKeys = [
      'hasAirConditioning',
      'hasHeatedSeats',
      'hasNavigation',
      'hasBluetooth',
      'hasUSB',
      'hasLeatherSteering'
    ];

    for (String key in comfortKeys) {
      if (details[key] == true) {
        comfortEquipment[key] = details[key];
      }
    }

    if (comfortEquipment.isNotEmpty) {
      widgets.add(_buildEquipmentSection('Comfort Equipment', comfortEquipment,
          Icons.airline_seat_recline_extra));
    }

    // Exterior Equipment
    final exteriorEquipment = <String, dynamic>{};
    final exteriorKeys = [
      'hasAlloyWheels',
      'hasSunroof',
      'hasXenonLights',
      'hasElectricMirrors'
    ];

    for (String key in exteriorKeys) {
      if (details[key] == true) {
        exteriorEquipment[key] = details[key];
      }
    }

    if (exteriorEquipment.isNotEmpty) {
      widgets.add(_buildEquipmentSection('Exterior Equipment',
          exteriorEquipment, Icons.directions_car_filled));
    }

    return widgets;
  }

  Widget _buildDetailSection(
      String title, Map<String, dynamic> details, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: const Color(0xFF8FBC8F),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: details.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text(
                        '${_translateDetailKey(entry.key)}:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDetailValue(entry.key, entry.value),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildEquipmentSection(
      String title, Map<String, dynamic> equipment, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: const Color(0xFF8FBC8F),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: equipment.keys.map((key) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14.sp,
                      color: Colors.green[700],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _translateDetailKey(key),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  String _formatDetailValue(String key, dynamic value) {
    if (value == null) return 'N/A';

    switch (key) {
      case 'hasServiceHistory':
        return value == true ? 'Available' : 'Not Available';
      case 'hasAccidentHistory':
        return value == true ? 'Yes' : 'No';
      case 'isPriceNegotiable':
        return value == true ? 'Yes' : 'No';
      case 'mileage':
        return '$value km';
      case 'power':
        return '$value HP';
      case 'year':
        return value.toString();
      default:
        return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentItem.title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (!_isOwner()) ...[
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
              ),
              tooltip: 'Add to favorites',
            ),
          ],
          IconButton(
            onPressed: () {
              // Share functionality
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            if (currentItem.images.isNotEmpty) ...[
              SizedBox(
                height: 250.h,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemCount: currentItem.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullscreenImageGallery(
                                  images: currentItem.images,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            currentItem.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    // Image indicator
                    if (currentItem.images.length > 1)
                      Positioned(
                        bottom: 16.h,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            currentItem.images.length,
                            (index) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Views counter in bottom right
                    if (!_isLoadingViews)
                      Positioned(
                        bottom: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$_totalViews',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              Container(
                height: 200.h,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 50.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            // Publication date and view stats
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Published: ${_formatPublishDate(currentItem.createdAt)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _isLoadingViews
                        ? 'Loading views...'
                        : '$_totalViews unique views ($_todayViews unique today)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and basic info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentItem.price.toStringAsFixed(0)} ${currentItem.currency}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8FBC8F),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _getItemTypeDisplay(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentItem.averageRating > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14.sp,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                currentItem.averageRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              if (currentItem.reviewCount > 0) ...[
                                SizedBox(width: 4.w),
                                Text(
                                  '(${currentItem.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Title
                  Text(
                    currentItem.title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Description
                  Text(
                    currentItem.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Details section - organized by categories
                  if (currentItem.details.isNotEmpty) ...[
                    ..._buildOrganizedDetails(),
                    SizedBox(height: 20.h),
                  ],

                  // Location with enhanced display for services
                  if (currentItem.location != null) ...[
                    // For services, show distance, location, and directions button
                    if (currentItem.type == MarketplaceItemType.service) ...[
                      FutureBuilder<double?>(
                        future: DistanceService.calculateDistanceToAddress(
                            currentItem.location!),
                        builder: (context, distanceSnapshot) {
                          return Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 18.sp,
                                      color: Colors.blue.shade700,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Service Location',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    if (distanceSnapshot.hasData &&
                                        distanceSnapshot.data != null) ...[
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          DistanceService.formatDistance(
                                              distanceSnapshot.data!),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  currentItem.location!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      MapLauncherService.openMapWithDirections(
                                    currentItem.location!,
                                    context: context,
                                  ),
                                  icon: Icon(Icons.directions, size: 16.sp),
                                  label: Text(
                                      'Open in ${MapLauncherService.mapAppName}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // For non-services, show simple location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            currentItem.location!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16.h),
                  ],

                  // Seller info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _sellerNickname ?? widget.item.sellerName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_phoneFromGarage != null ||
                            widget.item.sellerPhone != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            _phoneFromGarage ?? widget.item.sellerPhone!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Tags
                  if (widget.item.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: widget.item.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8FBC8F).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(0xFF8FBC8F)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF8FBC8F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Reviews Section
            _buildReviewsSection(),
          ],
        ),
      ),
      // Contact buttons (only show if not own car)
      bottomNavigationBar: !_isOwner()
          ? Container(
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
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatConversationScreen(
                                    receiverId: widget.item.sellerId,
                                    carPlateNumber:
                                        widget.item.details['plateNumber'] ??
                                            widget.item.title,
                                    carBrand: widget.item.details['brand'] ??
                                        widget.item.title,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please log in to contact the owner'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF808000), // oliveColor
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),

                      if (_phoneFromGarage != null &&
                          _phoneFromGarage!.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        // Phone button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _callPhone(context, _phoneFromGarage!),
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
                      ] else if (widget.item.sellerPhone != null &&
                          widget.item.sellerPhone!.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        // Phone button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _callPhone(context, widget.item.sellerPhone!),
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
            )
          : Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _editItem,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8FBC8F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _promoteItem,
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Promote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.item.reviewCount > 0) ...[
                Text(
                  '(${widget.item.reviewCount})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (_canLeaveReview())
                TextButton(
                  onPressed: _navigateToAddReview,
                  child: Text(
                    'Add Review',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8FBC8F),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          StreamBuilder<List<MarketplaceReview>>(
            stream: MarketplaceService.getItemReviews(widget.item.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: reviews.take(3).map((review) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16.r,
                              backgroundColor: const Color(0xFF8FBC8F),
                              child: Text(
                                review.reviewerName.isNotEmpty
                                    ? review.reviewerName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.reviewerName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16.sp,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(review.createdAt),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (review.comment.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            review.comment,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  String _formatPublishDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
