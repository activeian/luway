import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_item.dart';
import '../models/car.dart';
import '../models/subscription.dart';
import '../services/marketplace_service.dart';
import '../services/item_deactivation_service.dart';
import '../screens/marketplace_item_detail_screen.dart';
import '../screens/add_car_screen.dart';
import '../screens/boost_center_screen.dart';
import '../screens/deactivated_items_screen.dart';
import '../screens/boost_management_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<MarketplaceItem> _listings = [];
  bool _isLoading = true;
  String? _error;
  int _deactivatedItemsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadDeactivatedItemsCount();
  }

  Future<void> _loadListings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Please log in to view your listings';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final listings = await MarketplaceService.getUserItems(user.uid);

      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading listings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeactivatedItemsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final items =
            await ItemDeactivationService.getUserItemsInGracePeriod(user.uid);
        setState(() {
          _deactivatedItemsCount = items.length;
        });
      } catch (e) {
        print('Error loading deactivated items count: $e');
      }
    }
  }

  Widget _buildDeactivatedItemsBanner() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.orange[600],
            size: 24.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deactivated Items',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  'You have $_deactivatedItemsCount item(s) in 30-day grace period',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedItemsScreen(),
                ),
              ).then((_) {
                // Refresh counts when returning
                _loadDeactivatedItemsCount();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Manage',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Listings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadListings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8FBC8F),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadListings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8FBC8F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No Listings Found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You haven\'t created any marketplace listings yet.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                // Navigate to add listing screen
                Navigator.pop(context);
                // TODO: Navigate to add screen or marketplace
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8FBC8F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: const Text('Create First Listing'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadListings();
        await _loadDeactivatedItemsCount();
      },
      color: const Color(0xFF8FBC8F),
      child: Column(
        children: [
          // Deactivated items banner
          if (_deactivatedItemsCount > 0) _buildDeactivatedItemsBanner(),

          // Listings
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                final listing = _listings[index];
                return _buildListingCard(listing);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(MarketplaceItem listing) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: listing.isActive ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(listing.isActive ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(listing),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active boosts indicator
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getActiveBoosts(listing.id),
                builder: (context, snapshot) {
                  final activeBoosts = snapshot.data ?? [];
                  if (activeBoosts.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: activeBoosts
                          .map((boost) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.deepOrange.shade500
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      boost['icon'] ?? '🚀',
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      boost['badge'] ?? 'Boost',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      boost['timeLeft'] ?? '',
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),

              // Main listing content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with inactive overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: listing.images.isNotEmpty
                            ? Image.network(
                                listing.images.first,
                                width: 80.w,
                                height: 80.w,
                                fit: BoxFit.cover,
                                color: listing.isActive
                                    ? null
                                    : Colors.grey.withOpacity(0.6),
                                colorBlendMode:
                                    listing.isActive ? null : BlendMode.srcATop,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80.w,
                                    height: 80.w,
                                    color: listing.isActive
                                        ? Colors.grey[200]
                                        : Colors.grey[300],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: listing.isActive
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 80.w,
                                height: 80.w,
                                color: listing.isActive
                                    ? Colors.grey[200]
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: listing.isActive
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                ),
                              ),
                      ),
                      if (!listing.isActive)
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Icon(
                              Icons.pause,
                              size: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          listing.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: listing.isActive
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),

                        // Price
                        Text(
                          '${listing.price.toStringAsFixed(0)} ${listing.currency}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: listing.isActive
                                ? const Color(0xFF8FBC8F)
                                : Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Status and stats
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: listing.isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                listing.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: listing.isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Views and favorites stats
                            FutureBuilder<Map<String, int>>(
                              future: _getListingStats(listing.id),
                              builder: (context, snapshot) {
                                final stats = snapshot.data ??
                                    {'uniqueViews': 0, 'favorites': 0};
                                return Row(
                                  children: [
                                    // Unique views
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        border: Border.all(
                                            color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility,
                                              size: 10.sp,
                                              color: Colors.blue.shade700),
                                          SizedBox(width: 2.w),
                                          Text(
                                            '${stats['uniqueViews']}',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    // Favorites
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.favorite,
                                              size: 10.sp,
                                              color: Colors.red.shade700),
                                          SizedBox(width: 2.w),
                                          Text(
                                            '${stats['favorites']}',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // Reviews section
                        if (listing.averageRating > 0 ||
                            listing.reviewCount > 0)
                          Row(
                            children: [
                              if (listing.averageRating > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 14.sp,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  listing.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                              Icon(
                                Icons.comment,
                                size: 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${listing.reviewCount} reviews',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 8.h),

                        // Date info and expiry
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Listed ${_formatDate(listing.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  // Expiry date
                                  Text(
                                    'Expires ${_formatExpiryDate(listing.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: _isExpiringSoon(listing.createdAt)
                                          ? Colors.orange[700]
                                          : Colors.grey[400],
                                      fontWeight:
                                          _isExpiringSoon(listing.createdAt)
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quick boost button
                            GestureDetector(
                              onTap: () => _promoteListing(listing),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.deepOrange.shade500
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rocket_launch,
                                        size: 12.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Boost',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, listing),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: listing.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              listing.isActive ? Icons.pause : Icons.play_arrow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(listing.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(Icons.trending_up,
                                size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Promote',
                                style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: listing.isActive
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),

              // Active Boosts Simple Info
              SizedBox(height: 16.h),
              _buildBoostInfo(listing),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(MarketplaceItem listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceItemDetailScreen(item: listing),
      ),
    );
  }

  void _handleMenuAction(String action, MarketplaceItem listing) {
    switch (action) {
      case 'edit':
        _editListing(listing);
        break;
      case 'activate':
      case 'deactivate':
        _toggleListingStatus(listing);
        break;
      case 'promote':
        _promoteListing(listing);
        break;
      case 'delete':
        _confirmDelete(listing);
        break;
    }
  }

  Future<void> _editListing(MarketplaceItem listing) async {
    // Navigate to Edit Car if it's a car from garage
    if (listing.carId != null) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFB3B760),
            ),
          ),
        );

        // Load car data from My Garage
        final carData = await FirebaseFirestore.instance
            .collection('cars')
            .doc(listing.carId)
            .get();

        // Hide loading
        if (mounted) Navigator.pop(context);

        if (carData.exists) {
          final data = carData.data()!;
          data['id'] = listing.carId; // Add the ID to the data
          final car = Car.fromJson(data);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCarScreen(carToEdit: car),
              ),
            ).then((_) {
              // Refresh listings after editing
              _loadListings();
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Car not found in garage'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Hide loading
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading car: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _toggleListingStatus(MarketplaceItem listing) async {
    if (listing.isActive) {
      // Deactivate with grace period
      await _deactivateWithGracePeriod(listing);
    } else {
      // Try to reactivate if still in grace period
      await _reactivateListing(listing);
    }
  }

  Future<void> _deactivateWithGracePeriod(MarketplaceItem listing) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.pause_circle,
                color: Colors.orange[600],
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Deactivate Item',
                style: TextStyle(fontSize: 18.sp),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deactivate "${listing.title}"?',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Grace Period',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '• Item will be hidden from marketplace\n• You have 30 days to reactivate\n• After 30 days, item expires permanently',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await ItemDeactivationService.deactivateItem(
        listing.id,
        reason: 'Deactivated by user',
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (success) {
        // Refresh listings and deactivated count
        await _loadListings();
        await _loadDeactivatedItemsCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${listing.title} deactivated with 30-day grace period'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to deactivate item. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateListing(MarketplaceItem listing) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await ItemDeactivationService.reactivateItem(listing.id);

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (success) {
        // Refresh listings and deactivated count
        await _loadListings();
        await _loadDeactivatedItemsCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${listing.title} reactivated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to reactivate item. Grace period may have expired.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _promoteListing(MarketplaceItem listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoostCenterScreen(item: listing),
      ),
    ).then((_) {
      // Refresh listings to show new boost indicators
      _loadListings();
    });
  }

  void _confirmDelete(MarketplaceItem listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${listing.title}"?'),
            const SizedBox(height: 8),
            const Text(
              'This will remove the listing from marketplace but your car will remain in My Garage.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                  fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteListing(listing);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteListing(MarketplaceItem listing) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('marketplace')
          .doc(listing.id)
          .delete();

      // Update car in garage to set isForSale = false
      if (listing.carId != null) {
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(listing.carId)
            .update({
          'isForSale': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Hide loading
      if (mounted) Navigator.pop(context);

      // Refresh listings
      await _loadListings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get active boosts for a listing
  Future<List<Map<String, dynamic>>> _getActiveBoosts(String itemId) async {
    try {
      final now = DateTime.now();
      final boostsQuery = await FirebaseFirestore.instance
          .collection('boosts')
          .where('itemId', isEqualTo: itemId)
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .get();

      List<Map<String, dynamic>> activeBoosts = [];

      for (final doc in boostsQuery.docs) {
        final data = doc.data();
        final boost = Boost.fromJson(doc.id, data);
        final boostPlans = Boost.boostPlans;
        final plan = boostPlans[boost.type];

        if (plan != null) {
          final timeLeft = boost.endDate.difference(now);
          String timeLeftString = '';

          if (timeLeft.inDays > 0) {
            timeLeftString = '${timeLeft.inDays}d';
          } else if (timeLeft.inHours > 0) {
            timeLeftString = '${timeLeft.inHours}h';
          } else if (timeLeft.inMinutes > 0) {
            timeLeftString = '${timeLeft.inMinutes}m';
          } else {
            timeLeftString = '<1m';
          }

          activeBoosts.add({
            'id': boost.id,
            'type': boost.type,
            'icon': plan['icon'],
            'badge': plan['badge'],
            'timeLeft': timeLeftString,
            'endDate': boost.endDate,
          });
        }
      }

      return activeBoosts;
    } catch (e) {
      print('Error loading active boosts: $e');
      return [];
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }

  // Get listing statistics (unique views, favorites)
  Future<Map<String, int>> _getListingStats(String itemId) async {
    try {
      print('📊 Loading stats for item: $itemId');

      // Get unique views
      final viewsSnapshot = await FirebaseFirestore.instance
          .collection('item_views')
          .where('itemId', isEqualTo: itemId)
          .get();

      print('🔍 Found ${viewsSnapshot.docs.length} view records');

      final uniqueViewers = <String>{};
      for (var doc in viewsSnapshot.docs) {
        final data = doc.data();
        print('📝 View record: $data');

        // ViewTrackingService uses 'viewerUserId', not 'viewerId'
        final viewerId =
            data['viewerUserId'] as String? ?? data['viewerId'] as String?;
        if (viewerId != null) {
          uniqueViewers.add(viewerId);
        }
      }

      // Get favorites count
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .get();

      print('❤️ Found ${favoritesSnapshot.docs.length} favorites');
      print('👥 Unique viewers: ${uniqueViewers.length}');

      return {
        'uniqueViews': uniqueViewers.length,
        'favorites': favoritesSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error loading listing stats: $e');
      return {'uniqueViews': 0, 'favorites': 0};
    }
  }

  // Format expiry date (listings expire after 60 days)
  String _formatExpiryDate(DateTime createdAt) {
    final expiryDate = createdAt.add(Duration(days: 60));
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;

    if (daysLeft < 0) {
      return 'Expired';
    } else if (daysLeft == 0) {
      return 'Today';
    } else if (daysLeft == 1) {
      return 'Tomorrow';
    } else if (daysLeft < 7) {
      return 'in $daysLeft days';
    } else if (daysLeft < 30) {
      final weeks = (daysLeft / 7).floor();
      return 'in $weeks week${weeks > 1 ? 's' : ''}';
    } else {
      final months = (daysLeft / 30).floor();
      return 'in $months month${months > 1 ? 's' : ''}';
    }
  }

  // Check if listing is expiring soon (within 7 days)
  bool _isExpiringSoon(DateTime createdAt) {
    final expiryDate = createdAt.add(Duration(days: 60));
    final now = DateTime.now();
    final daysLeft = expiryDate.difference(now).inDays;
    return daysLeft <= 7 && daysLeft >= 0;
  }

  Widget _buildBoostInfo(MarketplaceItem listing) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MarketplaceService.getActiveBoosts(listing.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Loading boosts...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final activeBoosts = snapshot.data ?? [];

        if (activeBoosts.isEmpty) {
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: 8.w),
                Text(
                  'No active boosts',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Find the earliest expiry date
        DateTime? earliestExpiry;
        for (var boost in activeBoosts) {
          final expiresAt = boost['expiresAt'];
          DateTime? expiryDate;
          if (expiresAt is Timestamp) {
            expiryDate = expiresAt.toDate();
          } else if (expiresAt is DateTime) {
            expiryDate = expiresAt;
          }

          if (expiryDate != null) {
            if (earliestExpiry == null || expiryDate.isBefore(earliestExpiry)) {
              earliestExpiry = expiryDate;
            }
          }
        }

        String expiryText = '';
        if (earliestExpiry != null) {
          final daysLeft = earliestExpiry.difference(DateTime.now()).inDays;
          if (daysLeft <= 0) {
            expiryText = ' • Expires today';
          } else if (daysLeft == 1) {
            expiryText = ' • Expires tomorrow';
          } else {
            expiryText = ' • Expires in $daysLeft days';
          }
        }

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.rocket_launch,
                size: 16.sp,
                color: Colors.green.shade600,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${activeBoosts.length} active boost${activeBoosts.length > 1 ? 's' : ''}$expiryText',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
