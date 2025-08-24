import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';
import '../services/google_play_purchase_service.dart';
import '../widgets/boost_result_dialog.dart';

class BoostCenterScreen extends StatefulWidget {
  final MarketplaceItem item;

  const BoostCenterScreen({
    super.key,
    required this.item,
  });

  @override
  State<BoostCenterScreen> createState() => _BoostCenterScreenState();
}

class _BoostCenterScreenState extends State<BoostCenterScreen> {
  String? _selectedBoost;
  bool _isLoading = false;
  final GooglePlayPurchaseService _purchaseService =
      GooglePlayPurchaseService();

  @override
  void initState() {
    super.initState();
    _initializePurchaseService();
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
  }

  // Complete boost options - using Google Play Product IDs
  final Map<String, Map<String, dynamic>> boostOptions = {
    // � Priority Boosts - Renew (shown first)
    'renew_ad': {
      'name': 'Renew Listing',
      'description': 'Refresh listing timestamp to appear recent',
      'icon': '🔄',
      'price': 0.99,
      'duration': 30,
      'category': 'Priority Boosts',
      'playStoreId': 'luway_boost_renew_ad',
    },

    // �🔖 Classic Badge Boosts
    'new_badge': {
      'name': 'New Badge',
      'description': 'Green "NEW" label in corner showing recent addition',
      'icon': '🆕',
      'price': 0.99,
      'duration': 7,
      'category': 'Classic Badges',
      'playStoreId': 'luway_boost_new_badge',
    },
    'discount_badge': {
      'name': 'Sale Badge',
      'description': 'Red discount percentage label for promotions',
      'icon': '🏷️',
      'price': 0.99,
      'duration': 7,
      'category': 'Classic Badges',
      'playStoreId': 'luway_boost_sale_badge',
    },
    'negotiable_badge': {
      'name': 'Negotiable Badge',
      'description': 'Yellow "NEGOTIABLE" label indicating price flexibility',
      'icon': '💬',
      'price': 0.99,
      'duration': 7,
      'category': 'Classic Badges',
      'playStoreId': 'luway_boost_negotiable_badge',
    },
    'delivery_badge': {
      'name': 'Delivery Badge',
      'description':
          'Blue "DELIVERY" badge with truck icon showing transport coverage',
      'icon': '🚚',
      'price': 0.99,
      'duration': 7,
      'category': 'Classic Badges',
      'playStoreId': 'luway_boost_delivery_badge',
    },
    'popular_badge': {
      'name': 'Popular Badge',
      'description': 'Purple "POPULAR" tag for high-engagement listings',
      'icon': '🔥',
      'price': 0.99,
      'duration': 7,
      'category': 'Classic Badges',
      'playStoreId': 'luway_boost_popular_badge',
    },

    // 🟩 Border/Outline Boosts
    'colored_border': {
      'name': 'Colored Border',
      'description': 'Blue colored border around listing card',
      'icon': '🖼️',
      'price': 0.99,
      'duration': 7,
      'category': 'Border Effects',
      'playStoreId': 'luway_boost_colored_border',
    },
    'animated_border': {
      'name': 'Animated Border',
      'description': 'Border changes color smoothly to attract attention',
      'icon': '✨',
      'price': 0.99,
      'duration': 7,
      'category': 'Border Effects',
      'playStoreId': 'luway_boost_animated_border',
    },
    'glow_effect': {
      'name': 'Glow Effect',
      'description': 'Blue and cyan glow effect around listing card',
      'icon': '💫',
      'price': 0.99,
      'duration': 7,
      'category': 'Border Effects',
      'playStoreId': 'luway_boost_animated_glow',
    },

    // ⚡ Dynamic/Impact Boosts
    'pulsing_card': {
      'name': 'Pulsing Card',
      'description': 'Listing card pulses slowly (0.95x to 1.05x scale)',
      'icon': '💓',
      'price': 0.99,
      'duration': 7,
      'category': 'Dynamic Effects',
      'playStoreId': 'luway_boost_pulsing_card',
    },
    'shimmer_label': {
      'name': 'Shimmer Effect',
      'description': 'Light shimmer sweeps across the listing card',
      'icon': '⭐',
      'price': 0.99,
      'duration': 7,
      'category': 'Dynamic Effects',
      'playStoreId': 'luway_boost_shimmer_label',
    },
    'bounce_load': {
      'name': 'Bounce on Load',
      'description': 'Listing bounces when it loads into view',
      'icon': '🏀',
      'price': 0.99,
      'duration': 7,
      'category': 'Dynamic Effects',
      'playStoreId': 'luway_boost_bounce_on_load',
    },

    // 🧩 Creative/Unique Boosts
    'triangle_corner': {
      'name': 'Triangle Corner',
      'description': 'Triangle corner cutout with "Hot!" text',
      'icon': '📐',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_triangular_card',
    },
    'orbital_star': {
      'name': 'Orbital Star',
      'description': 'Animated star orbits around listing corners',
      'icon': '🌟',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_orbital_star',
    },
    'hologram_effect': {
      'name': 'Hologram Effect',
      'description': 'Animated gradient hologram background effect',
      'icon': '🌈',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_hologram_effect',
    },
    'light_ray': {
      'name': 'Light Ray',
      'description': 'Diagonal light ray sweep effect across listing',
      'icon': '⚡',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_light_ray',
    },
    'floating_badge': {
      'name': 'Floating 3D Badge',
      'description': '3D floating badge with shadow and subtle movement',
      'icon': '🏷️',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_floating_3d_badge',
    },
    'torn_sticker': {
      'name': 'Torn Label',
      'description': 'Torn paper effect label with "Limited Offer"',
      'icon': '📄',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_torn_label',
    },
    'handwritten_sticker': {
      'name': 'Hand-drawn Sticker',
      'description': 'Hand-drawn style sticker overlay effect',
      'icon': '✍️',
      'price': 0.99,
      'duration': 7,
      'category': 'Creative Effects',
      'playStoreId': 'luway_boost_handdrawn_sticker',
    },

    // Basic Functionality Boosts
    'colored_frame': {
      'name': 'Colored Frame',
      'description': 'Add colored border frame to listing',
      'icon': '🖼️',
      'price': 0.99,
      'duration': 7,
      'category': 'Basic Functions',
      'playStoreId': 'luway_boost_colored_frame',
    },
    'top_brand': {
      'name': 'Top Brand/Model',
      'description': 'Featured in brand-specific listings',
      'icon': '🏆',
      'price': 0.99,
      'duration': 7,
      'category': 'Positioning',
      'playStoreId': 'luway_boost_top_brand',
    },
    'top_recommended': {
      'name': 'Top Recommended',
      'description': 'Featured in recommendations section',
      'icon': '⭐',
      'price': 0.99,
      'duration': 7,
      'category': 'Positioning',
      'playStoreId': 'luway_boost_top_recommended',
    },
    'push_notification': {
      'name': 'Push Notification',
      'description': 'Send notification to interested users',
      'icon': '📱',
      'price': 0.99,
      'duration': 7,
      'category': 'Marketing',
      'playStoreId': 'luway_boost_push_notification',
    },
    'local_boost': {
      'name': 'Local Boost',
      'description': 'Enhanced local visibility in area',
      'icon': '📍',
      'price': 0.99,
      'duration': 7,
      'category': 'Positioning',
      'playStoreId': 'luway_boost_local_boost',
    },
    'label_tags': {
      'name': 'Label Tags',
      'description': 'Special labels like Sale, Best Price, etc.',
      'icon': '🏷️',
      'price': 0.99,
      'duration': 7,
      'category': 'Basic Functions',
      'playStoreId': 'luway_boost_label_tags',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Boost Your Listing',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Item preview
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Row(
              children: [
                // Item image
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[300],
                  ),
                  child: widget.item.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            widget.item.images.first,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.image, color: Colors.grey[600]),
                ),
                SizedBox(width: 16.w),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '\$${widget.item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Boost Options',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Boost options organized by categories
                  _buildCategorizedBoosts(),
                ],
              ),
            ),
          ),

          // Purchase button
          if (_selectedBoost != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${boostOptions[_selectedBoost]!['price'].toStringAsFixed(2)} USD',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _purchaseBoost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Purchase Boost',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

  Widget _buildCategorizedBoosts() {
    // Group boosts by category
    final categories = <String, List<MapEntry<String, Map<String, dynamic>>>>{};

    for (final entry in boostOptions.entries) {
      final category = entry.value['category'] as String;
      categories.putIfAbsent(category, () => []).add(entry);
    }

    return Column(
      children: categories.entries.map((categoryEntry) {
        final categoryName = categoryEntry.key;
        final boosts = categoryEntry.value;

        return Container(
          margin: EdgeInsets.only(bottom: 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getCategoryGradient(categoryName),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Boosts grid (2 columns)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: boosts.length,
                  itemBuilder: (context, index) {
                    final entry = boosts[index];
                    final key = entry.key;
                    final boost = entry.value;

                    return _buildBoostCard(key, boost);
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Color> _getCategoryGradient(String category) {
    switch (category) {
      case 'Classic Badges':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'Border Effects':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'Dynamic Effects':
        return [Colors.purple.shade400, Colors.purple.shade600];
      case 'Creative Effects':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'Utility':
        return [Colors.grey.shade400, Colors.grey.shade600];
      default:
        return [Colors.teal.shade400, Colors.teal.shade600];
    }
  }

  Widget _buildBoostCard(String key, Map<String, dynamic> boost) {
    final isSelected = _selectedBoost == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedBoost == key) {
            _selectedBoost = null;
          } else {
            _selectedBoost = key;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with icon and selection
            Container(
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            boost['icon'],
                            style: TextStyle(fontSize: 20.sp),
                          ),
                        ),
                      ),

                      // Selection indicator
                      Container(
                        width: 20.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check,
                                color: Colors.white, size: 14.sp)
                            : null,
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Title
                  Text(
                    boost['name'],
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Description
                  Text(
                    boost['description'],
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Price and duration
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Column(
                children: [
                  // Price
                  Text(
                    '\$${boost['price'].toStringAsFixed(2)} USD',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),

                  // Duration
                  Text(
                    '${boost['duration']} days',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _purchaseBoost() async {
    if (_selectedBoost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a boost option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedOption = boostOptions[_selectedBoost!]!;

      // Show purchase confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Boost: ${selectedOption['name']}'),
              SizedBox(height: 8.h),
              Text(
                  'Price: \$${selectedOption['price'].toStringAsFixed(2)} USD'),
              SizedBox(height: 8.h),
              Text('Duration: ${selectedOption['duration']} days'),
              SizedBox(height: 16.h),
              Text(
                Platform.isIOS
                    ? 'This will be charged through App Store.'
                    : 'This will be charged through Google Play Store.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Purchase'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use Google Play In-App Purchase Service
      print(
          '🛒 Starting ${Platform.isIOS ? 'App Store' : 'Google Play'} purchase for boost: ${selectedOption['playStoreId']}');

      final success = await _purchaseService.purchaseBoost(_selectedBoost!);

      if (success) {
        // Purchase initiated successfully
        print('✅ Purchase initiated successfully');

        // Generate mock transaction ID for development
        final transactionId =
            'mock_txn_${DateTime.now().millisecondsSinceEpoch}';

        // Create boost record in Firestore with payment verification
        await MarketplaceService.createBoost(
          itemId: widget.item.id,
          boostType: _selectedBoost!,
          duration: selectedOption['duration'],
          price: selectedOption['price'],
          playStoreId: selectedOption['playStoreId'],
          transactionId: transactionId,
        );

        // Show beautiful success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Boost Activated!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Your "${selectedOption['name']}" boost has been successfully activated!'),
                SizedBox(height: 8),
                Text('Duration: ${selectedOption['duration']} days'),
                SizedBox(height: 8),
                Text('Your listing will now have enhanced visibility.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pop(context); // Close boost center screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        throw Exception(
            'Failed to initiate ${Platform.isIOS ? 'App Store' : 'Google Play'} purchase');
      }
    } catch (e) {
      print('❌ Boost purchase error: $e');

      String errorMessage = e.toString();
      if (Platform.isIOS) {
        errorMessage = errorMessage.replaceAll('Google Play', 'App Store');
      }

      // Clean up error message
      if (errorMessage.contains('Failed to create boost:')) {
        errorMessage = errorMessage.replaceAll(
            'Exception: Failed to create boost: Exception: ', '');
        errorMessage =
            errorMessage.replaceAll('Exception: Failed to create boost: ', '');
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      // Show beautiful error dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.isNotEmpty
              ? errorMessage
              : 'Something went wrong with your boost purchase. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
