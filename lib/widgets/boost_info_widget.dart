import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';

class BoostInfoWidget extends StatefulWidget {
  final MarketplaceItem item;

  const BoostInfoWidget({
    super.key,
    required this.item,
  });

  @override
  State<BoostInfoWidget> createState() => _BoostInfoWidgetState();
}

class _BoostInfoWidgetState extends State<BoostInfoWidget> {
  List<Map<String, dynamic>> _activeBoosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveBoosts();
  }

  Future<void> _loadActiveBoosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final boosts = await MarketplaceService.getActiveBoosts(widget.item.id);
      setState(() {
        _activeBoosts = boosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading boosts: $e');
    }
  }

  String _getBoostDisplayName(String boostType) {
    final names = {
      'new_badge': 'New Badge',
      'discount_badge': 'Discount Badge',
      'negotiable_badge': 'Negotiable Badge',
      'delivery_badge': 'Delivery Badge',
      'popular_badge': 'Popular Badge',
      'colored_border': 'Colored Border',
      'animated_border': 'Animated Border',
      'glow_effect': 'Glow Effect',
      'pulsing_card': 'Pulsing Card',
      'shimmer_label': 'Shimmer Label',
      'bounce_load': 'Bounce Effect',
      'triangle_corner': 'Triangle Corner',
      'orbital_star': 'Orbital Star',
      'hologram_effect': 'Hologram Effect',
      'light_ray': 'Light Ray',
      'floating_badge': 'Floating Badge',
      'torn_sticker': 'Torn Sticker',
      'handwritten_sticker': 'Handwritten Sticker',
      'renewal': 'Listing Renewal',
    };
    return names[boostType] ?? boostType;
  }

  String _getBoostIcon(String boostType) {
    final icons = {
      'new_badge': '🆕',
      'discount_badge': '🏷️',
      'negotiable_badge': '💬',
      'delivery_badge': '🚚',
      'popular_badge': '🔥',
      'colored_border': '🖼️',
      'animated_border': '✨',
      'glow_effect': '💫',
      'pulsing_card': '💓',
      'shimmer_label': '⭐',
      'bounce_load': '🏀',
      'triangle_corner': '📐',
      'orbital_star': '🌟',
      'hologram_effect': '🌈',
      'light_ray': '⚡',
      'floating_badge': '🏷️',
      'torn_sticker': '📄',
      'handwritten_sticker': '✍️',
      'renewal': '🔄',
    };
    return icons[boostType] ?? '🎯';
  }

  Color _getBoostColor(String boostType) {
    final colors = {
      'new_badge': Colors.green,
      'discount_badge': Colors.red,
      'negotiable_badge': Colors.yellow.shade700,
      'delivery_badge': Colors.blue,
      'popular_badge': Colors.deepPurple,
      'colored_border': Colors.blue,
      'animated_border': Colors.purple,
      'glow_effect': Colors.cyan,
      'pulsing_card': Colors.pink,
      'shimmer_label': Colors.amber,
      'bounce_load': Colors.orange,
      'triangle_corner': Colors.red,
      'orbital_star': Colors.yellow,
      'hologram_effect': Colors.teal,
      'light_ray': Colors.indigo,
      'floating_badge': Colors.orange,
      'torn_sticker': Colors.yellow,
      'handwritten_sticker': Colors.pink,
      'renewal': Colors.grey,
    };
    return colors[boostType] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Active Boosts',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_activeBoosts.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${_activeBoosts.length}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.h),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _activeBoosts.isEmpty
                    ? _buildEmptyState()
                    : _buildBoostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(
          Icons.rocket_launch_outlined,
          size: 48.sp,
          color: Colors.grey.shade400,
        ),
        SizedBox(height: 16.h),
        Text(
          'No Active Boosts',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'This listing has no active visual effects',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBoostsList() {
    return Column(
      children: [
        Text(
          'Active Boosts (${_activeBoosts.length})',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 16.h),
        
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _activeBoosts.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final boost = _activeBoosts[index];
            return _buildBoostCard(boost);
          },
        ),
      ],
    );
  }

  Widget _buildBoostCard(Map<String, dynamic> boost) {
    final boostType = boost['type'] as String;
    final isActive = boost['isActive'] as bool;
    final expiresAt = (boost['expiresAt'] as dynamic).toDate();
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _getBoostColor(boostType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                _getBoostIcon(boostType),
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBoostDisplayName(boostType),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  daysLeft > 0 
                      ? 'Expires in $daysLeft days'
                      : 'Expired',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: daysLeft > 0 ? Colors.grey.shade600 : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'PAUSED',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
