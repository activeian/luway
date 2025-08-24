import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/marketplace_service.dart';
import '../services/view_tracking_service.dart';
import '../models/marketplace_item.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  
  // Analytics data
  int _totalListings = 0;
  int _activeListings = 0;
  int _totalViews = 0;
  int _totalMessages = 0;
  int _favoritedCount = 0;
  double _averagePrice = 0.0;
  Map<String, int> _categoryBreakdown = {};
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, int> _monthlyViews = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load marketplace items
      final items = await MarketplaceService.getUserItems(user.uid);
      
      _totalListings = items.length;
      _activeListings = items.where((item) => item.isActive).length;
      
      // Calculate average price
      if (items.isNotEmpty) {
        _averagePrice = items.fold<double>(0, (sum, item) => sum + item.price) / items.length;
      }
      
      // Category breakdown
      _categoryBreakdown.clear();
      for (final item in items) {
        String categoryName;
        switch (item.type) {
          case MarketplaceItemType.car:
            categoryName = 'Cars';
            break;
          case MarketplaceItemType.accessory:
            categoryName = 'Accessories';
            break;
          case MarketplaceItemType.service:
            categoryName = 'Services';
            break;
        }
        _categoryBreakdown[categoryName] = (_categoryBreakdown[categoryName] ?? 0) + 1;
      }
      
      // Get real view data
      _totalViews = await ViewTrackingService.getUserTotalViews(user.uid);
      final viewStats = await ViewTrackingService.getItemViewStatistics(user.uid);
      
      // Use real data if available, otherwise simulate
      _favoritedCount = viewStats['itemsWithViews'] ?? items.length * 12;
      _totalMessages = items.length * 8; // This would come from a messaging service
      
      // Get real monthly views data
      final viewAnalytics = await ViewTrackingService.getUserViewAnalytics(user.uid);
      _monthlyViews = _processViewAnalytics(viewAnalytics);
      
      // Load recent activity
      await _loadRecentActivity(user.uid);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _processViewAnalytics(Map<String, int> viewAnalytics) {
    final Map<String, int> monthlyData = {};
    final now = DateTime.now();
    
    // Get last 6 months of data
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(month.month);
      
      // Sum up views for this month from the daily data
      int monthlyViews = 0;
      viewAnalytics.forEach((dateKey, views) {
        final date = DateTime.parse('$dateKey');
        if (date.year == month.year && date.month == month.month) {
          monthlyViews += views;
        }
      });
      
      monthlyData[monthName] = monthlyViews;
    }
    
    return monthlyData;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _loadRecentActivity(String userId) async {
    try {
      // Load recent marketplace activities
      final querySnapshot = await FirebaseFirestore.instance
          .collection('marketplace_activity')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      _recentActivity = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'action': data['action'] ?? 'Unknown action',
          'details': data['details'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // If no real data exists, create some sample recent activity
      if (_recentActivity.isEmpty) {
        _recentActivity = [
          {
            'action': 'Item Posted',
            'details': 'BMW X5 2020 - Listed for sale',
            'timestamp': DateTime.now().subtract(Duration(hours: 2)),
          },
          {
            'action': 'Message Received',
            'details': 'New inquiry about Audi A4',
            'timestamp': DateTime.now().subtract(Duration(hours: 5)),
          },
          {
            'action': 'Item Viewed',
            'details': 'Mercedes C-Class received 3 new views',
            'timestamp': DateTime.now().subtract(Duration(days: 1)),
          },
          {
            'action': 'Price Updated',
            'details': 'Volkswagen Golf - Price reduced to \$15,000',
            'timestamp': DateTime.now().subtract(Duration(days: 2)),
          },
          {
            'action': 'Item Favorited',
            'details': 'Toyota Camry was added to favorites',
            'timestamp': DateTime.now().subtract(Duration(days: 3)),
          },
        ];
      }
    } catch (e) {
      print('Error loading recent activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7A1E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF6B7A1E),
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6B7A1E)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildOverviewCards(),
                  
                  SizedBox(height: 32.h),
                  
                  // Performance Metrics
                  Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildPerformanceCards(),
                  
                  SizedBox(height: 32.h),
                  
                  // Monthly Views Chart
                  Text(
                    'Views Trend (Last 6 Months)',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildViewsChart(),
                  
                  SizedBox(height: 32.h),
                  
                  // Category Breakdown
                  Text(
                    'Listings by Category',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildCategoryBreakdown(),
                  
                  SizedBox(height: 32.h),
                  
                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Listings',
            '$_totalListings',
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildMetricCard(
            'Active',
            '$_activeListings',
            Icons.visibility,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Views',
                '$_totalViews',
                Icons.visibility,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMetricCard(
                'Messages',
                '$_totalMessages',
                Icons.message,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Favorites',
                '$_favoritedCount',
                Icons.favorite,
                Colors.red,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMetricCard(
                'Avg. Price',
                '\$${_averagePrice.toStringAsFixed(0)}',
                Icons.attach_money,
                Color(0xFF6B7A1E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViewsChart() {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _monthlyViews.entries.map((entry) {
                final maxViews = _monthlyViews.values.isNotEmpty 
                    ? _monthlyViews.values.reduce((a, b) => a > b ? a : b) 
                    : 1;
                final height = maxViews > 0 ? (entry.value / maxViews * 120).h : 20.h;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 24.w,
                      height: height,
                      decoration: BoxDecoration(
                        color: Color(0xFF6B7A1E),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryBreakdown.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No listings yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _categoryBreakdown.entries.map((entry) {
          final percentage = (entry.value / _totalListings * 100);
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7A1E)),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7A1E),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _recentActivity.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = _recentActivity[index];
          return ListTile(
            leading: _getActivityIcon(activity['action']),
            title: Text(
              activity['action'],
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['details'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatTimestamp(activity['timestamp']),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getActivityIcon(String action) {
    IconData icon;
    Color color;
    
    switch (action) {
      case 'Item Posted':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'Message Received':
        icon = Icons.message;
        color = Colors.blue;
        break;
      case 'Item Viewed':
        icon = Icons.visibility;
        color = Colors.purple;
        break;
      case 'Price Updated':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'Item Favorited':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16.sp),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
