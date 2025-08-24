import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/marketplace_item.dart';
import '../services/favorites_service.dart';
import '../screens/marketplace_item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<MarketplaceItem> _favoriteItems = [];
  List<MarketplaceItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  MarketplaceItemType? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await FavoritesService.getFavoriteItems();
      setState(() {
        _favoriteItems = favorites;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(String itemId) async {
    final success = await FavoritesService.removeFromFavorites(itemId);
    if (success) {
      setState(() {
        _favoriteItems.removeWhere((item) => item.id == itemId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onItemTap(MarketplaceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceItemDetailScreen(item: item),
      ),
    ).then((_) {
      // Refresh favorites when returning from detail screen
      _loadFavorites();
    });
  }

  String _getItemTypeDisplay(MarketplaceItemType type) {
    switch (type) {
      case MarketplaceItemType.car:
        return 'Car';
      case MarketplaceItemType.accessory:
        return 'Accessory';
      case MarketplaceItemType.service:
        return 'Service';
    }
  }

  void _applyFilters() {
    _filteredItems = _favoriteItems.where((item) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!item.title.toLowerCase().contains(searchLower) &&
            !item.description.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      // Apply type filter
      if (_selectedType != null && item.type != _selectedType) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<MarketplaceItemType?>(
              title: const Text('All Types'),
              value: null,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
            ...MarketplaceItemType.values.map((type) => RadioListTile<MarketplaceItemType?>(
              title: Text(_getTypeDisplayName(type)),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(MarketplaceItemType type) {
    switch (type) {
      case MarketplaceItemType.car:
        return 'Cars';
      case MarketplaceItemType.accessory:
        return 'Accessories';
      case MarketplaceItemType.service:
        return 'Services';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
          ),
          if (_favoriteItems.isNotEmpty)
            IconButton(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8FBC8F),
              ),
            )
          : _favoriteItems.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Search bar at the top
                    Container(
                      padding: EdgeInsets.all(16.w),
                      color: Colors.grey[50],
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search favorites...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                    _applyFilters();
                                  });
                                },
                              )
                            : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.r),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildFavoritesList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add listings to favorites to see them here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FBC8F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: const Text('Explorează anunțurile'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          color: Colors.grey[50],
          child: Text(
            '${_filteredItems.length} saved listings',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return _buildFavoriteCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(MarketplaceItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: item.images.isNotEmpty
                    ? Image.network(
                        item.images.first,
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80.w,
                            height: 80.h,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80.w,
                        height: 80.h,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8FBC8F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        _getItemTypeDisplay(item.type),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF8FBC8F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    
                    // Title
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
                    
                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    
                    // Price and rating
                    Row(
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} ${item.currency}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8FBC8F),
                          ),
                        ),
                        const Spacer(),
                        if (item.averageRating > 0) ...[
                          Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 14.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            item.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Location and date
                    if (item.location != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12.sp,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            item.location!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Remove button
              IconButton(
                onPressed: () => _showRemoveDialog(item),
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(MarketplaceItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from favorites'),
        content: Text('Sigur vrei să elimini "${item.title}" din favorite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromFavorites(item.id);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
