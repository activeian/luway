import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/marketplace_item.dart';
import '../services/recommendation_service.dart';
import '../services/favorites_service.dart';
import '../services/user_behavior_service.dart';
import '../services/marketplace_service.dart';
import '../services/boost_visual_effects.dart';
import '../screens/marketplace_item_detail_screen.dart';

enum RecommendationFilter { all, cars, accessories, services }

enum LayoutType { grid, list }

class SmartRecommendationsWidget extends StatefulWidget {
  const SmartRecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<SmartRecommendationsWidget> createState() =>
      _SmartRecommendationsWidgetState();
}

class _SmartRecommendationsWidgetState
    extends State<SmartRecommendationsWidget> {
  List<MarketplaceItem> _allRecommendations = [];
  List<MarketplaceItem> _filteredRecommendations = [];
  List<MarketplaceItem> _trending = [];
  bool _isLoading = true;
  Map<String, bool> _favoriteStatus = {};

  RecommendationFilter _currentFilter = RecommendationFilter.all;
  LayoutType _layoutType = LayoutType.grid;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('SmartRecommendationsWidget: Loading recommendations...');

      // Load recommendations and trending items in parallel
      final results = await Future.wait([
        RecommendationService.getHomeRecommendations(limit: 20),
        RecommendationService.getTrendingItems(limit: 6),
      ]);

      final recommendations = results[0];
      final trending = results[1];

      print(
          'SmartRecommendationsWidget: Got ${recommendations.length} recommendations');
      print(
          'SmartRecommendationsWidget: Got ${trending.length} trending items');

      // Remove duplicates between trending and recommendations
      final trendingIds = trending.map((item) => item.id).toSet();
      final uniqueRecommendations = recommendations
          .where((item) => !trendingIds.contains(item.id))
          .toList();

      print(
          'SmartRecommendationsWidget: After deduplication: ${uniqueRecommendations.length} unique recommendations');

      // Load favorite status for all items
      final allItems = [...uniqueRecommendations, ...trending];
      final favoriteStatus = <String, bool>{};

      for (final item in allItems) {
        favoriteStatus[item.id] = await FavoritesService.isFavorite(item.id);
      }

      setState(() {
        _allRecommendations = uniqueRecommendations;
        _trending = trending;
        _favoriteStatus = favoriteStatus;
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('SmartRecommendationsWidget: Error loading recommendations: $e');
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case RecommendationFilter.all:
          _filteredRecommendations = _allRecommendations;
          break;
        case RecommendationFilter.cars:
          _filteredRecommendations =
              _allRecommendations.where((item) => item.type == 'car').toList();
          break;
        case RecommendationFilter.accessories:
          _filteredRecommendations = _allRecommendations
              .where((item) => item.type == 'accessory')
              .toList();
          break;
        case RecommendationFilter.services:
          _filteredRecommendations = _allRecommendations
              .where((item) => item.type == 'service')
              .toList();
          break;
      }
    });
  }

  Future<void> _toggleFavorite(String itemId) async {
    final success = await FavoritesService.toggleFavorite(itemId);
    if (success) {
      setState(() {
        _favoriteStatus[itemId] = !(_favoriteStatus[itemId] ?? false);
      });
    }
  }

  void _onItemTap(MarketplaceItem item) {
    // Track item view
    UserBehaviorService.trackItemView(item.id, item);

    // Navigate to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceItemDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFB3B760), // Changed from Colors.blue to olive green
          ),
        ),
      );
    }

    // If no recommendations or trending, show a message
    if (_allRecommendations.isEmpty && _trending.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(
              Icons.recommend,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No Recommendations Yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Browse the marketplace to get personalized recommendations',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                    0xFFB3B760), // Changed from Colors.blue to olive green
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter and Layout Controls
        _buildControlsRow(),

        SizedBox(height: 16.h),

        // Trending Section
        if (_trending.isNotEmpty) ...[
          _buildTrendingSection(),
          SizedBox(height: 24.h),
        ],

        // Recommendations Section
        if (_filteredRecommendations.isNotEmpty) ...[
          _buildRecommendationsSection(),
        ] else if (_currentFilter != RecommendationFilter.all) ...[
          _buildNoResultsMessage(),
        ],

        SizedBox(height: 16.h),

        // Refresh Button
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildControlsRow() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Filter Button
          Expanded(
            child: GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list,
                        size: 16.sp,
                        color: const Color(
                            0xFFB3B760)), // Changed from Colors.blue
                    SizedBox(width: 4.w),
                    Text(
                      _getFilterText(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color:
                            const Color(0xFFB3B760), // Changed from Colors.blue
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Layout Toggle Button
          GestureDetector(
            onTap: _toggleLayout,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Icon(
                _layoutType == LayoutType.grid
                    ? Icons.view_list
                    : Icons.grid_view,
                size: 20.sp,
                color: const Color(0xFFB3B760), // Changed from Colors.blue
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText() {
    switch (_currentFilter) {
      case RecommendationFilter.all:
        return 'All (${_filteredRecommendations.length})';
      case RecommendationFilter.cars:
        return 'Cars (${_filteredRecommendations.length})';
      case RecommendationFilter.accessories:
        return 'Accessories (${_filteredRecommendations.length})';
      case RecommendationFilter.services:
        return 'Services (${_filteredRecommendations.length})';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Recommendations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: RecommendationFilter.values.map((filter) {
              final count = _getFilterCount(filter);
              return RadioListTile<RecommendationFilter>(
                title: Text('${_getFilterName(filter)} ($count)'),
                value: filter,
                groupValue: _currentFilter,
                activeColor:
                    const Color(0xFFB3B760), // Set olive green for radio button
                onChanged: (RecommendationFilter? value) {
                  setState(() {
                    _currentFilter = value!;
                  });
                  _applyFilter();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getFilterName(RecommendationFilter filter) {
    switch (filter) {
      case RecommendationFilter.all:
        return 'All Items';
      case RecommendationFilter.cars:
        return 'Cars';
      case RecommendationFilter.accessories:
        return 'Accessories';
      case RecommendationFilter.services:
        return 'Services';
    }
  }

  int _getFilterCount(RecommendationFilter filter) {
    switch (filter) {
      case RecommendationFilter.all:
        return _allRecommendations.length;
      case RecommendationFilter.cars:
        return _allRecommendations.where((item) => item.type == 'car').length;
      case RecommendationFilter.accessories:
        return _allRecommendations
            .where((item) => item.type == 'accessory')
            .length;
      case RecommendationFilter.services:
        return _allRecommendations
            .where((item) => item.type == 'service')
            .length;
    }
  }

  void _toggleLayout() {
    setState(() {
      _layoutType =
          _layoutType == LayoutType.grid ? LayoutType.list : LayoutType.grid;
    });
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.orange,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Trending Now',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _trending.length,
            itemBuilder: (context, index) {
              final item = _trending[index];
              return _buildTrendingCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend,
              color: const Color(0xFFB3B760), // Changed from Colors.blue
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Recommended for You',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _layoutType == LayoutType.grid
            ? _buildGridLayout()
            : _buildListLayout(),
      ],
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
        childAspectRatio:
            0.7, // Reduced to give more vertical space for content
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

  Widget _buildTrendingCard(MarketplaceItem item) {
    final isFavorite = _favoriteStatus[item.id] ?? false;

    return FutureBuilder<List<String>>(
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        Widget baseCard = Container(
          width: 140.w,
          margin: EdgeInsets.only(right: 12.w),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: InkWell(
              onTap: () => _onItemTap(item),
              borderRadius: BorderRadius.circular(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12.r)),
                        child: item.images.isNotEmpty
                            ? Image.network(
                                item.images.first,
                                height: 90.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 90.h,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 90.h,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                      // Trending Badge
                      Positioned(
                        top: 6.h,
                        left: 6.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(item.id),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            '${item.price.toStringAsFixed(0)} ${item.currency}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(
                                  0xFFB3B760), // Changed from Colors.blue
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return BoostVisualEffects.applyBoostEffects(
            child: baseCard,
            activeBoostTypes: activeBoostTypes,
            isInSmartRecommendations: true,
          );
        }

        return baseCard;
      },
    );
  }

  Widget _buildGridCard(MarketplaceItem item) {
    final isFavorite = _favoriteStatus[item.id] ?? false;

    return FutureBuilder<List<String>>(
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        Widget baseCard = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap: () => _onItemTap(item),
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12.r)),
                      child: item.images.isNotEmpty
                          ? Image.network(
                              item.images.first,
                              height: 100
                                  .h, // Reduced from 120.h to give more space for content
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100.h, // Reduced from 120.h
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 100.h, // Reduced from 120.h
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    // Type Badge
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getTypeColor(item.type.name),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _getTypeLabel(item.type.name),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(item.id),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(6.w), // Reduced padding from 8.w
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min, // Added to prevent overflow
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 11.sp, // Reduced from 12.sp
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h), // Reduced from 4.h
                        Text(
                          item.location ?? 'Unknown Location',
                          style: TextStyle(
                            fontSize: 9.sp, // Reduced from 10.sp
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '${item.price.toStringAsFixed(0)} ${item.currency}',
                          style: TextStyle(
                            fontSize: 12.sp, // Reduced from 13.sp
                            fontWeight: FontWeight.bold,
                            color: const Color(
                                0xFFB3B760), // Changed from Colors.blue to olive green
                          ),
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
            isInSmartRecommendations: true,
          );
        }

        return baseCard;
      },
    );
  }

  Widget _buildListCard(MarketplaceItem item) {
    final isFavorite = _favoriteStatus[item.id] ?? false;

    return FutureBuilder<List<String>>(
      future: MarketplaceService.getActiveBoostTypes(item.id),
      builder: (context, boostSnapshot) {
        final activeBoostTypes = boostSnapshot.data ?? [];

        Widget baseCard = Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap: () => _onItemTap(item),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  // Image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: item.images.isNotEmpty
                            ? Image.network(
                                item.images.first,
                                height: 80.h,
                                width: 80.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 80.h,
                                    width: 80.w,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 80.h,
                                width: 80.w,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                      // Type Badge
                      Positioned(
                        top: 4.h,
                        left: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item.type.name),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _getTypeLabel(item.type.name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: 12.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.location ?? 'Unknown Location',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${item.price.toStringAsFixed(0)} ${item.currency}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(
                                0xFFB3B760), // Changed from Colors.blue
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite button
                  GestureDetector(
                    onTap: () => _toggleFavorite(item.id),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Apply boost effects if any are active
        if (activeBoostTypes.isNotEmpty) {
          return BoostVisualEffects.applyBoostEffects(
            child: baseCard,
            activeBoostTypes: activeBoostTypes,
            isInSmartRecommendations: true,
          );
        }

        return baseCard;
      },
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No ${_getFilterName(_currentFilter)} Found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try changing the filter or browse all recommendations',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentFilter = RecommendationFilter.all;
              });
              _applyFilter();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFB3B760), // Changed from Colors.blue
              foregroundColor: Colors.white,
            ),
            child: const Text('Show All'),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _loadRecommendations,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Recommendations'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB3B760), // Changed from Colors.blue
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return const Color(
            0xFFB3B760); // Changed from Colors.blue to match new color scheme
      case 'accessory':
        return Colors.orange;
      case 'service':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'CAR';
      case 'accessory':
        return 'ACC';
      case 'service':
        return 'SRV';
      default:
        return 'OTHER';
    }
  }
}
