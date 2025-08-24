import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/marketplace_item.dart';
import 'models/subscription.dart';
import 'services/marketplace_service.dart';
import 'services/monetization_service.dart';
import 'services/boost_visual_effects.dart';
import 'services/distance_service.dart';
import 'screens/marketplace_item_detail_screen.dart';
import 'screens/add_marketplace_item_screen.dart';
import 'screens/marketplace_filter_screen.dart';
import 'screens/select_car_for_marketplace_screen.dart';

const Color oliveColor = Color(0xFF808000);

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MarketplaceFilter _currentFilter = MarketplaceFilter();
  bool _isTwoColumnLayout = false; // Add layout toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Marketplace',
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
            icon: Icon(
                _isTwoColumnLayout ? Icons.view_agenda : Icons.view_module),
            onPressed: () {
              setState(() {
                _isTwoColumnLayout = !_isTwoColumnLayout;
              });
            },
            tooltip: _isTwoColumnLayout ? 'Single Column' : 'Two Columns',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: oliveColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: oliveColor,
          tabs: const [
            Tab(text: 'Cars'),
            Tab(text: 'Accessories'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCarsTab(),
          _buildAccessoriesTab(),
          _buildServicesTab(),
        ],
      ),
    );
  }

  Widget _buildCarsTab() {
    return _buildMarketplaceList(
      filter: _currentFilter.copyWith(type: MarketplaceItemType.car),
    );
  }

  Widget _buildAccessoriesTab() {
    return _buildMarketplaceList(
      filter: _currentFilter.copyWith(type: MarketplaceItemType.accessory),
    );
  }

  Widget _buildServicesTab() {
    return _buildMarketplaceList(
      filter: _currentFilter.copyWith(type: MarketplaceItemType.service),
    );
  }

  Widget _buildMarketplaceList({required MarketplaceFilter filter}) {
    return StreamBuilder<List<MarketplaceItem>>(
      stream: MarketplaceService.getMarketplaceItems(filter: filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Color(0xFFB3B760),
          ));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80.sp,
                    color: Colors.red.shade300,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Error loading items',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Please try again later',
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

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80.sp,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Be the first to list an item!',
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

        if (_isTwoColumnLayout) {
          return _buildTwoColumnLayout(items);
        } else {
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMarketplaceItemCard(item);
            },
          );
        }
      },
    );
  }

  Widget _buildMarketplaceItemCard(MarketplaceItem item) {
    return FutureBuilder<List<String>>(
      key: ValueKey('${item.id}_boost_effects'),
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        // Base card widget
        Widget baseCard = Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _navigateToItemDetail(item),
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (item.images.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: Container(
                      height: 200.h,
                      width: double.infinity,
                      child: Image.network(
                        item.images[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.car_rental,
                              size: 48.sp,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '${item.price.toStringAsFixed(0)} ${item.currency}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: oliveColor,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Category badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _getCategoryText(item),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(item),
                          ),
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Description
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 12.h),

                      // Rating and seller info
                      Row(
                        children: [
                          if (item.reviewCount > 0) ...[
                            Icon(
                              Icons.star,
                              size: 16.sp,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${item.averageRating.toStringAsFixed(1)} (${item.reviewCount})',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          Icon(
                            Icons.person,
                            size: 16.sp,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              item.sellerName,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.location != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 16.sp,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(width: 4.w),
                            // Show distance for services, location for others
                            if (item.type == MarketplaceItemType.service)
                              FutureBuilder<double?>(
                                future:
                                    DistanceService.calculateDistanceToAddress(
                                        item.location!),
                                builder: (context, distanceSnapshot) {
                                  if (distanceSnapshot.hasData &&
                                      distanceSnapshot.data != null) {
                                    return Text(
                                      '${DistanceService.formatDistance(distanceSnapshot.data!)} • ${item.location!}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  } else {
                                    // Fallback to just location if distance calculation fails
                                    return Text(
                                      item.location!,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                },
                              )
                            else
                              Text(
                                item.location!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return BoostVisualEffects.applyBoostEffects(
            child: baseCard,
            activeBoostTypes: activeBoostTypes,
            isInSmartRecommendations: false,
            applyRandomSingle: true, // Apply only ONE random boost per item
          );
        }

        return baseCard;
      },
    );
  }

  Color _getCategoryColor(MarketplaceItem item) {
    switch (item.type) {
      case MarketplaceItemType.car:
        return Colors.blue;
      case MarketplaceItemType.accessory:
        return Colors.green;
      case MarketplaceItemType.service:
        return Colors.orange;
    }
  }

  String _getCategoryText(MarketplaceItem item) {
    switch (item.type) {
      case MarketplaceItemType.car:
        return 'Car';
      case MarketplaceItemType.accessory:
        return item.accessoryCategory != null
            ? MarketplaceService.getAccessoryCategoryName(
                item.accessoryCategory!)
            : 'Accessory';
      case MarketplaceItemType.service:
        return item.serviceCategory != null
            ? MarketplaceService.getServiceCategoryName(item.serviceCategory!)
            : 'Service';
    }
  }

  void _navigateToItemDetail(MarketplaceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceItemDetailScreen(item: item),
      ),
    );
  }

  void _showFilterOptions() async {
    final result = await Navigator.push<MarketplaceFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceFilterScreen(
          initialFilter: _currentFilter,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
    }
  }

  void _showAddOptions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Marketplace',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),
            _buildAddOption(
              icon: Icons.directions_car,
              title: 'List a Car',
              subtitle: 'From your garage',
              onTap: () => _navigateToAddItem(MarketplaceItemType.car),
            ),
            SizedBox(height: 16.h),
            _buildAddOption(
              icon: Icons.build,
              title: 'Add Accessory',
              subtitle: 'Requires subscription',
              onTap: () => _navigateToAddItem(MarketplaceItemType.accessory),
            ),
            SizedBox(height: 16.h),
            _buildAddOption(
              icon: Icons.handyman,
              title: 'Add Service',
              subtitle: 'Requires subscription',
              onTap: () => _navigateToAddItem(MarketplaceItemType.service),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: oliveColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: oliveColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
      ),
    );
  }

  void _navigateToAddItem(MarketplaceItemType type) async {
    if (type == MarketplaceItemType.car) {
      // For cars, navigate to car selection screen first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelectCarForMarketplaceScreen(),
        ),
      );
    } else {
      // Allow all users to publish accessories and services
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMarketplaceItemScreen(type: type),
        ),
      );
    }
  }

  Widget _buildTwoColumnLayout(List<MarketplaceItem> items) {
    return FutureBuilder<Map<String, List<Boost>>>(
      future: _getAllItemsBoosts(items),
      builder: (context, boostsSnapshot) {
        final allBoosts = boostsSnapshot.data ?? {};

        // Separate items with animated borders from regular items
        final animatedItems = <MarketplaceItem>[];
        final regularItems = <MarketplaceItem>[];

        for (final item in items) {
          final itemBoosts = allBoosts[item.id] ?? [];
          if (itemBoosts
              .any((boost) => boost.type == BoostType.animatedBorder)) {
            animatedItems.add(item);
          } else {
            regularItems.add(item);
          }
        }

        return CustomScrollView(
          slivers: [
            // Single column section for animated items
            if (animatedItems.isNotEmpty) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Featured Items',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildMarketplaceItemCard(animatedItems[index]);
                    },
                    childCount: animatedItems.length,
                  ),
                ),
              ),
            ],

            // Two column section for regular items
            if (regularItems.isNotEmpty) ...[
              if (animatedItems.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'All Items',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.7, // Made narrower like smart feed
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildCompactMarketplaceItemCard(
                          regularItems[index]);
                    },
                    childCount: regularItems.length,
                  ),
                ),
              ),
            ],

            // Bottom padding
            SliverPadding(
              padding: EdgeInsets.only(bottom: 16.h),
              sliver: SliverToBoxAdapter(child: SizedBox()),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, List<Boost>>> _getAllItemsBoosts(
      List<MarketplaceItem> items) async {
    final Map<String, List<Boost>> result = {};

    for (final item in items) {
      try {
        result[item.id] =
            await MonetizationService.getCombinedActiveBoosts(item.id);
      } catch (e) {
        result[item.id] = [];
      }
    }

    return result;
  }

  Widget _buildCompactMarketplaceItemCard(MarketplaceItem item) {
    return FutureBuilder<List<String>>(
      key: ValueKey('compact_${item.id}_boost_effects'),
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        // Base card widget
        Widget baseCard = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketplaceItemDetailScreen(item: item),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
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
                // Compact image
                if (item.images.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12.r)),
                        image: DecorationImage(
                          image: NetworkImage(item.images.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                // Compact content
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Spacer(),

                        // Price
                        Text(
                          '${item.price.toStringAsFixed(0)} ${item.currency}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8FBC8F),
                          ),
                        ),

                        // Distance for services (compact view)
                        if (item.type == MarketplaceItemType.service &&
                            item.location != null)
                          FutureBuilder<double?>(
                            future: DistanceService.calculateDistanceToAddress(
                                item.location!),
                            builder: (context, distanceSnapshot) {
                              if (distanceSnapshot.hasData &&
                                  distanceSnapshot.data != null) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 10.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        DistanceService.formatDistance(
                                            distanceSnapshot.data!),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return SizedBox.shrink();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return BoostVisualEffects.applyBoostEffects(
            child: baseCard,
            activeBoostTypes: activeBoostTypes,
            isInSmartRecommendations: false,
            applyRandomSingle: true, // Apply only ONE random boost per item
          );
        }

        return baseCard;
      },
    );
  }
}

// Animated Border Wrapper for marketplace items
class AnimatedBorderWrapper extends StatefulWidget {
  final Widget child;

  const AnimatedBorderWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBorderWrapper> createState() => _AnimatedBorderWrapperState();
}

class _AnimatedBorderWrapperState extends State<AnimatedBorderWrapper>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _shimmerController;
  late Animation<double> _borderAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Border rotation animation
    _borderController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Shimmer effect animation
    _shimmerController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _borderAnimation = _borderController.drive(
      Tween<double>(begin: 0.0, end: 1.0),
    );

    _shimmerAnimation = _shimmerController.drive(
      Tween<double>(begin: 0.0, end: 1.0),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_borderController, _shimmerController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            gradient: SweepGradient(
              transform: GradientRotation(_borderAnimation.value * 2 * 3.14159),
              colors: [
                Colors.blue.withOpacity(0.8),
                Colors.purple.withOpacity(0.8),
                Colors.pink.withOpacity(0.8),
                Colors.orange.withOpacity(0.8),
                Colors.blue.withOpacity(0.8),
              ],
            ),
          ),
          padding: EdgeInsets.all(3.w),
          child: Stack(
            children: [
              widget.child,
              // Shimmer overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 - _shimmerAnimation.value, 0.0),
                      end: Alignment(1.0 - _shimmerAnimation.value, 0.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
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

// Extension to add copyWith method to MarketplaceFilter
extension MarketplaceFilterExtension on MarketplaceFilter {
  MarketplaceFilter copyWith({
    MarketplaceItemType? type,
    ServiceCategory? serviceCategory,
    AccessoryCategory? accessoryCategory,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? searchQuery,
    List<String>? tags,

    // Car specific
    String? country,
    String? brand,
    String? model,
    int? minYear,
    int? maxYear,
    String? fuelType,
    String? transmission,
    String? bodyType,
    String? color,
    String? condition,
    int? minMileage,
    int? maxMileage,
    int? minPower,
    int? maxPower,
    String? doors,

    // Equipment
    bool? hasABS,
    bool? hasESP,
    bool? hasAirbags,
    bool? hasAirConditioning,
    bool? hasNavigation,
    bool? hasHeatedSeats,
    bool? hasAlarm,
    bool? hasBluetooth,
    bool? hasUSB,
    bool? hasLeatherSteering,
    bool? hasAlloyWheels,
    bool? hasSunroof,
    bool? hasXenonLights,
    bool? hasElectricMirrors,

    // Status
    bool? isForSale,
    bool? isPriceNegotiable,
    bool? hasServiceHistory,
    bool? hasAccidentHistory,
  }) {
    return MarketplaceFilter(
      type: type ?? this.type,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      accessoryCategory: accessoryCategory ?? this.accessoryCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,

      // Car specific
      country: country ?? this.country,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      bodyType: bodyType ?? this.bodyType,
      color: color ?? this.color,
      condition: condition ?? this.condition,
      minMileage: minMileage ?? this.minMileage,
      maxMileage: maxMileage ?? this.maxMileage,
      minPower: minPower ?? this.minPower,
      maxPower: maxPower ?? this.maxPower,
      doors: doors ?? this.doors,

      // Equipment
      hasABS: hasABS ?? this.hasABS,
      hasESP: hasESP ?? this.hasESP,
      hasAirbags: hasAirbags ?? this.hasAirbags,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      hasNavigation: hasNavigation ?? this.hasNavigation,
      hasHeatedSeats: hasHeatedSeats ?? this.hasHeatedSeats,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      hasBluetooth: hasBluetooth ?? this.hasBluetooth,
      hasUSB: hasUSB ?? this.hasUSB,
      hasLeatherSteering: hasLeatherSteering ?? this.hasLeatherSteering,
      hasAlloyWheels: hasAlloyWheels ?? this.hasAlloyWheels,
      hasSunroof: hasSunroof ?? this.hasSunroof,
      hasXenonLights: hasXenonLights ?? this.hasXenonLights,
      hasElectricMirrors: hasElectricMirrors ?? this.hasElectricMirrors,

      // Status
      isForSale: isForSale ?? this.isForSale,
      isPriceNegotiable: isPriceNegotiable ?? this.isPriceNegotiable,
      hasServiceHistory: hasServiceHistory ?? this.hasServiceHistory,
      hasAccidentHistory: hasAccidentHistory ?? this.hasAccidentHistory,
    );
  }
}
