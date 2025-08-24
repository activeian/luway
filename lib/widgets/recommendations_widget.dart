import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/marketplace_item.dart';
import '../services/smart_home_service.dart';
import '../services/favorites_service.dart';
import '../services/user_behavior_service.dart';
import '../services/boost_visual_effects.dart';
import '../services/marketplace_service.dart';
import '../services/distance_service.dart';
import '../screens/marketplace_item_detail_screen.dart';

enum RecommendationFilter { all, car, accessory, service }

enum LayoutType { grid, list }

class RecommendationsWidget extends StatefulWidget {
  const RecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  List<MarketplaceItem> _smartFeed = [];
  List<MarketplaceItem> _filteredRecommendations = [];
  bool _isLoading = true;
  Map<String, bool> _favoriteStatus = {};

  RecommendationFilter _currentFilter = RecommendationFilter.all;
  LayoutType _layoutType = LayoutType.grid;

  @override
  void initState() {
    super.initState();
    _loadSmartFeed();
  }

  Future<void> _loadSmartFeed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('RecommendationsWidget: Loading smart home feed...');

      // Get smart feed with intelligent algorithm
      final smartFeed = await SmartHomeService.getSmartHomeFeed(limit: 12);

      print('RecommendationsWidget: Got ${smartFeed.length} smart feed items');

      // Load favorite status for all items
      final favoriteStatus = <String, bool>{};

      // Use Future.wait to load all favorite statuses in parallel
      await Future.wait(smartFeed.map((item) async {
        final isFavorite = await FavoritesService.isFavorite(item.id);
        favoriteStatus[item.id] = isFavorite;
      }));

      setState(() {
        _smartFeed = smartFeed;
        _favoriteStatus = favoriteStatus;
        _filteredRecommendations = smartFeed;
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      print('Error loading smart feed: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredRecommendations = _smartFeed.where((item) {
        switch (_currentFilter) {
          case RecommendationFilter.car:
            return item.type == MarketplaceItemType.car;
          case RecommendationFilter.accessory:
            return item.type == MarketplaceItemType.accessory;
          case RecommendationFilter.service:
            return item.type == MarketplaceItemType.service;
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smart Recommendations',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  // Layout toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _layoutType = _layoutType == LayoutType.grid
                            ? LayoutType.list
                            : LayoutType.grid;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _layoutType == LayoutType.grid
                            ? Icons.view_list
                            : Icons.grid_view,
                        size: 20.sp,
                        color: const Color(0xFFB3B760), // Add olive green color
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadSmartFeed,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFB3B760), // Changed from blue to olive green
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter tabs
        Container(
          height: 40.h,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All', RecommendationFilter.all),
              _buildFilterChip('Cars', RecommendationFilter.car),
              _buildFilterChip('Accessories', RecommendationFilter.accessory),
              _buildFilterChip('Services', RecommendationFilter.service),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _isLoading
              ? _buildLoadingWidget()
              : _filteredRecommendations.isEmpty
                  ? _buildEmptyWidget()
                  : _layoutType == LayoutType.grid
                      ? _buildGridLayout()
                      : _buildListLayout(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, RecommendationFilter filter) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
        _applyFilter();
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB3B760)
              : Colors.grey[200], // Changed from blue to olive green
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFB3B760),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading smart recommendations...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No recommendations found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your filters or refresh the feed',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadSmartFeed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3B760),
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredRecommendations.length,
      itemBuilder: (context, index) {
        final item = _filteredRecommendations[index];
        return _buildGridCard(item);
      },
    );
  }

  Widget _buildListLayout() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecommendations.length,
      itemBuilder: (context, index) {
        final item = _filteredRecommendations[index];
        return _buildListCard(item);
      },
    );
  }

  Widget _buildGridCard(MarketplaceItem item) {
    final isFavorite = _favoriteStatus[item.id] ?? false;

    return FutureBuilder<List<String>>(
      key: ValueKey('${item.id}_boost_effects'),
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        // Create the base card widget
        Widget baseCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: Container(
                      height: 100.h,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: item.images.isNotEmpty
                          ? Image.network(
                              item.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image_not_supported, size: 40.sp),
                            )
                          : Icon(Icons.directions_car,
                              size: 40.sp, color: Colors.grey),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(item.id),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '€${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB3B760),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      if (item.location != null)
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 9.sp, color: Colors.grey),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: item.type == MarketplaceItemType.service
                                  ? FutureBuilder<double?>(
                                      future: DistanceService
                                          .calculateDistanceToAddress(
                                              item.location!),
                                      builder: (context, distanceSnapshot) {
                                        if (distanceSnapshot.hasData &&
                                            distanceSnapshot.data != null) {
                                          return Text(
                                            '${DistanceService.formatDistance(distanceSnapshot.data!)} • ${item.location!}',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        } else {
                                          return Text(
                                            item.location!,
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                      },
                                    )
                                  : Text(
                                      item.location!,
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return GestureDetector(
            onTap: () => _onItemTap(item),
            child: BoostVisualEffects.applyBoostEffects(
              child: baseCard,
              activeBoostTypes: activeBoostTypes,
              isInSmartRecommendations: true, // Important: Smart feed context
              applyRandomSingle: true, // Apply only ONE random boost per item
            ),
          );
        }

        return GestureDetector(
          onTap: () => _onItemTap(item),
          child: baseCard,
        );
      },
    );
  }

  Widget _buildListCard(MarketplaceItem item) {
    final isFavorite = _favoriteStatus[item.id] ?? false;

    return FutureBuilder<List<String>>(
      key: ValueKey('${item.id}_boost_effects'),
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        // Create the base card widget
        Widget baseCard = Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
                child: Container(
                  width: 120.w,
                  height: 100.h,
                  color: Colors.grey.shade100,
                  child: item.images.isNotEmpty
                      ? Image.network(
                          item.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 30.sp),
                        )
                      : Icon(Icons.directions_car,
                          size: 30.sp, color: Colors.grey),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleFavorite(item.id),
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '€${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB3B760),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (item.location != null)
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 12.sp, color: Colors.grey),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: item.type == MarketplaceItemType.service
                                  ? FutureBuilder<double?>(
                                      future: DistanceService
                                          .calculateDistanceToAddress(
                                              item.location!),
                                      builder: (context, distanceSnapshot) {
                                        if (distanceSnapshot.hasData &&
                                            distanceSnapshot.data != null) {
                                          return Text(
                                            '${DistanceService.formatDistance(distanceSnapshot.data!)} • ${item.location!}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        } else {
                                          return Text(
                                            item.location!,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }
                                      },
                                    )
                                  : Text(
                                      item.location!,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return GestureDetector(
            onTap: () => _onItemTap(item),
            child: BoostVisualEffects.applyBoostEffects(
              child: baseCard,
              activeBoostTypes: activeBoostTypes,
              isInSmartRecommendations: true, // Important: Smart feed context
              applyRandomSingle: true, // Apply only ONE random boost per item
            ),
          );
        }

        return GestureDetector(
          onTap: () => _onItemTap(item),
          child: baseCard,
        );
      },
    );
  }

  Future<void> _toggleFavorite(String itemId) async {
    final success = await FavoritesService.toggleFavorite(itemId);
    if (success && mounted) {
      setState(() {
        _favoriteStatus[itemId] = !(_favoriteStatus[itemId] ?? false);
      });
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update favorites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTap(MarketplaceItem item) async {
    // Track user behavior
    UserBehaviorService.trackItemView(item.id, item);

    // Navigate to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceItemDetailScreen(item: item),
      ),
    );
  }
}
