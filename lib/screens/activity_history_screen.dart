import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _allActivities = [];
  List<Map<String, dynamic>> _marketplaceActivities = [];
  List<Map<String, dynamic>> _garageActivities = [];
  List<Map<String, dynamic>> _socialActivities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadActivityHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load real activities from Firestore
      await _loadRealActivities(user.uid);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity history: $e');
      // Fall back to sample data on error
      await _generateSampleActivities(user.uid);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRealActivities(String userId) async {
    try {
      // Load marketplace activities
      final marketplaceQuery = await FirebaseFirestore.instance
          .collection('marketplace_activity')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final List<Map<String, dynamic>> realActivities = [];

      for (final doc in marketplaceQuery.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        realActivities.add({
          'id': doc.id,
          'type': 'marketplace',
          'action': data['action'] ?? 'unknown',
          'title': _getActivityTitle(data['action'] ?? '', data['details'] ?? ''),
          'description': data['details'] ?? 'No details available',
          'timestamp': timestamp,
          'icon': _getActivityIcon(data['action'] ?? ''),
          'color': _getActivityColor(data['action'] ?? ''),
        });
      }

      // If no real activities found, use sample data
      if (realActivities.isEmpty) {
        await _generateSampleActivities(userId);
      } else {
        _allActivities = realActivities;
        _categorizeActivities();
      }
    } catch (e) {
      print('Error loading real activities: $e');
      throw e;
    }
  }

  String _getActivityTitle(String action, String details) {
    switch (action) {
      case 'item_viewed':
        return 'Item received new view';
      case 'item_posted':
        return 'Posted new item';
      case 'item_sold':
        return 'Item sold successfully';
      case 'price_updated':
        return 'Updated item price';
      case 'message_received':
        return 'Received new message';
      default:
        return details.isNotEmpty ? details : 'Activity';
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'item_viewed':
        return Icons.visibility;
      case 'item_posted':
        return Icons.add_circle;
      case 'item_sold':
        return Icons.sell;
      case 'price_updated':
        return Icons.edit;
      case 'message_received':
        return Icons.message;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'item_viewed':
        return Colors.blue;
      case 'item_posted':
        return Colors.green;
      case 'item_sold':
        return Colors.green.shade700;
      case 'price_updated':
        return Colors.purple;
      case 'message_received':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _categorizeActivities() {
    _marketplaceActivities = _allActivities.where((activity) => activity['type'] == 'marketplace').toList();
    _garageActivities = _allActivities.where((activity) => activity['type'] == 'garage').toList();
    _socialActivities = _allActivities.where((activity) => activity['type'] == 'social').toList();
  }

  Future<void> _generateSampleActivities(String userId) async {
    final now = DateTime.now();
    
    _allActivities = [
      {
        'id': '1',
        'type': 'marketplace',
        'action': 'item_posted',
        'title': 'Posted BMW X5 2020',
        'description': 'Listed your BMW X5 2020 for \$45,000',
        'timestamp': now.subtract(Duration(hours: 2)),
        'icon': Icons.add_circle,
        'color': Colors.green,
      },
      {
        'id': '2',
        'type': 'social',
        'action': 'message_sent',
        'title': 'Sent message to John Doe',
        'description': 'Replied to inquiry about Audi A4',
        'timestamp': now.subtract(Duration(hours: 5)),
        'icon': Icons.message,
        'color': Colors.blue,
      },
      {
        'id': '3',
        'type': 'garage',
        'action': 'car_added',
        'title': 'Added Mercedes C-Class to garage',
        'description': 'Mercedes C-Class 2019 - Personal vehicle',
        'timestamp': now.subtract(Duration(days: 1)),
        'icon': Icons.garage,
        'color': Colors.orange,
      },
      {
        'id': '4',
        'type': 'marketplace',
        'action': 'price_updated',
        'title': 'Updated price for Volkswagen Golf',
        'description': 'Reduced price from \$18,000 to \$15,000',
        'timestamp': now.subtract(Duration(days: 2)),
        'icon': Icons.edit,
        'color': Colors.purple,
      },
      {
        'id': '5',
        'type': 'social',
        'action': 'item_favorited',
        'title': 'Someone favorited your listing',
        'description': 'Toyota Camry 2021 was added to favorites',
        'timestamp': now.subtract(Duration(days: 3)),
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'id': '6',
        'type': 'marketplace',
        'action': 'item_viewed',
        'title': 'Your listing was viewed',
        'description': 'Honda Civic 2020 received 5 new views',
        'timestamp': now.subtract(Duration(days: 4)),
        'icon': Icons.visibility,
        'color': Colors.teal,
      },
      {
        'id': '7',
        'type': 'garage',
        'action': 'maintenance_added',
        'title': 'Added maintenance record',
        'description': 'Oil change for BMW X5 - 45,000 miles',
        'timestamp': now.subtract(Duration(days: 5)),
        'icon': Icons.build,
        'color': Colors.brown,
      },
      {
        'id': '8',
        'type': 'social',
        'action': 'message_received',
        'title': 'Received message from Sarah Smith',
        'description': 'New inquiry about Ford Mustang',
        'timestamp': now.subtract(Duration(days: 6)),
        'icon': Icons.mail,
        'color': Colors.indigo,
      },
      {
        'id': '9',
        'type': 'marketplace',
        'action': 'item_sold',
        'title': 'Item sold successfully',
        'description': 'Nissan Altima 2018 sold for \$16,500',
        'timestamp': now.subtract(Duration(days: 7)),
        'icon': Icons.sell,
        'color': Colors.green.shade700,
      },
      {
        'id': '10',
        'type': 'garage',
        'action': 'insurance_updated',
        'title': 'Updated insurance information',
        'description': 'Renewed insurance for Mercedes C-Class',
        'timestamp': now.subtract(Duration(days: 8)),
        'icon': Icons.security,
        'color': Colors.deepOrange,
      },
    ];

    
    // Filter activities by type
    _categorizeActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity History',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7A1E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF6B7A1E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF6B7A1E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF6B7A1E),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Marketplace'),
            Tab(text: 'Garage'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6B7A1E)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(_allActivities),
                _buildActivityList(_marketplaceActivities),
                _buildActivityList(_garageActivities),
                _buildActivityList(_socialActivities),
              ],
            ),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your activities will appear here',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivityHistory,
      color: Color(0xFF6B7A1E),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity, index == 0, activities);
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isFirst, List<Map<String, dynamic>> allActivities) {
    final timestamp = activity['timestamp'] as DateTime;
    final isToday = _isToday(timestamp);
    final isYesterday = _isYesterday(timestamp);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        if (isFirst || _shouldShowDateHeader(activity, allActivities)) ...[
          if (!isFirst) SizedBox(height: 24.h),
          Text(
            isToday ? 'Today' : isYesterday ? 'Yesterday' : _formatDate(timestamp),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        
        // Activity card
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
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
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: (activity['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity['icon'],
                color: activity['color'],
                size: 24.sp,
              ),
            ),
            title: Text(
              activity['title'],
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  activity['description'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Spacer(),
                    _buildActivityTypeChip(activity['type']),
                  ],
                ),
              ],
            ),
            onTap: () => _showActivityDetails(activity),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTypeChip(String type) {
    Color color;
    String label;
    
    switch (type) {
      case 'marketplace':
        color = Colors.blue;
        label = 'Marketplace';
        break;
      case 'garage':
        color = Colors.orange;
        label = 'Garage';
        break;
      case 'social':
        color = Colors.green;
        label = 'Social';
        break;
      default:
        color = Colors.grey;
        label = 'Other';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(Map<String, dynamic> activity, List<Map<String, dynamic>> allActivities) {
    final currentTimestamp = activity['timestamp'] as DateTime;
    final currentIndex = allActivities.indexOf(activity);
    
    if (currentIndex == 0) return true;
    
    final previousTimestamp = allActivities[currentIndex - 1]['timestamp'] as DateTime;
    return !_isSameDay(currentTimestamp, previousTimestamp);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and title
                    Row(
                      children: [
                        Container(
                          width: 56.w,
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'],
                            color: activity['color'],
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'],
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _formatFullTimestamp(activity['timestamp']),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Description
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      activity['description'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Activity type
                    Row(
                      children: [
                        Text(
                          'Category: ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        _buildActivityTypeChip(activity['type']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullTimestamp(DateTime date) {
    return '${_formatDate(date)} at ${_formatTime(date)}';
  }
}
