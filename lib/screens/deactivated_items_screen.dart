import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_item.dart';
import '../services/item_deactivation_service.dart';
import '../services/marketplace_service.dart';

const Color oliveColor = Color(0xFFB3B760);

class DeactivatedItemsScreen extends StatefulWidget {
  const DeactivatedItemsScreen({super.key});

  @override
  State<DeactivatedItemsScreen> createState() => _DeactivatedItemsScreenState();
}

class _DeactivatedItemsScreenState extends State<DeactivatedItemsScreen> {
  bool _isLoading = true;
  List<MarketplaceItem> _deactivatedItems = [];
  int _expiringSoonCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDeactivatedItems();
  }

  Future<void> _loadDeactivatedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final items = await ItemDeactivationService.getUserItemsInGracePeriod(user.uid);
        final expiringSoon = await ItemDeactivationService.getItemsExpiringSoonCount(user.uid);
        
        setState(() {
          _deactivatedItems = items;
          _expiringSoonCount = expiringSoon;
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
            content: Text('Error loading deactivated items: $e'),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Deactivated Items',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDeactivatedItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_deactivatedItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_expiringSoonCount > 0) _buildExpiringWarning(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDeactivatedItems,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _deactivatedItems.length,
              itemBuilder: (context, index) {
                final item = _deactivatedItems[index];
                return _buildItemCard(item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80.sp,
            color: Colors.green.shade400,
          ),
          SizedBox(height: 24.h),
          Text(
            'No Deactivated Items',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'All your marketplace items are currently active. Deactivated items with a 30-day grace period would appear here.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringWarning() {
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
            Icons.warning_amber,
            color: Colors.orange[600],
            size: 24.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items Expiring Soon',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  '$_expiringSoonCount item(s) will expire within 7 days. Reactivate them to keep them visible.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MarketplaceItem item) {
    final daysLeft = item.daysUntilExpiry;
    final isExpiringSoon = daysLeft <= 7;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isExpiringSoon
            ? Border.all(color: Colors.orange[300]!, width: 2)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and expiry info
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isExpiringSoon ? Colors.orange[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Deactivated',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isExpiringSoon ? Colors.orange[800] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isExpiringSoon ? Colors.orange[600] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // Item details
            Row(
              children: [
                // Image
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[200],
                  ),
                  child: item.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            item.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 32.sp,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 32.sp,
                        ),
                ),
                SizedBox(width: 16.w),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${item.price} ${item.currency}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: oliveColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Type: ${_getTypeLabel(item.type)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeleteConfirmation(item),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[400]!),
                      foregroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Delete Permanently',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _reactivateItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oliveColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Reactivate',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(MarketplaceItemType type) {
    switch (type) {
      case MarketplaceItemType.car:
        return 'Car';
      case MarketplaceItemType.accessory:
        return 'Accessory';
      case MarketplaceItemType.service:
        return 'Service';
    }
  }

  Future<void> _reactivateItem(MarketplaceItem item) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ItemDeactivationService.reactivateItem(item.id);
      
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} has been reactivated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the list
        await _loadDeactivatedItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reactivate item. Please try again.'),
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

  void _showDeleteConfirmation(MarketplaceItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[600],
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delete Permanently',
                style: TextStyle(fontSize: 18.sp),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete "${item.title}"?',
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'This action cannot be undone. The item will be completely removed from the marketplace.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteItemPermanently(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItemPermanently(MarketplaceItem item) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await MarketplaceService.deleteMarketplaceItem(item.id);
      
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} has been deleted permanently.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the list
        await _loadDeactivatedItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item. Please try again.'),
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
}
