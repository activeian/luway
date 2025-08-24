import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';
import '../services/monetization_service.dart';

const Color oliveColor = Color(0xFF808000);

class BoostManagementScreen extends StatefulWidget {
  final String? itemId;
  
  const BoostManagementScreen({
    Key? key,
    this.itemId,
  }) : super(key: key);

  @override
  State<BoostManagementScreen> createState() => _BoostManagementScreenState();
}

class _BoostManagementScreenState extends State<BoostManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Boost> _activeBoosts = [];
  List<Boost> _pausedBoosts = [];
  List<Boost> _allBoosts = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _hasSubscription = false;
  String _selectedItemId = 'test_item_123'; // Default test item

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (widget.itemId != null) {
      _selectedItemId = widget.itemId!;
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Check subscription status
      _hasSubscription = await MonetizationService.hasActiveSubscription(_currentUserId);
      
      // Load boosts for the selected item
      _activeBoosts = await MonetizationService.getItemActiveBoosts(_selectedItemId);
      _pausedBoosts = await MonetizationService.getUserPausedBoosts(_currentUserId ?? '');
      _allBoosts = await MonetizationService.getUserAllBoosts(_currentUserId ?? '');
      
      // Filter paused boosts for this item
      _pausedBoosts = _pausedBoosts.where((boost) => boost.itemId == _selectedItemId).toList();
      
    } catch (e) {
      print('Error loading boost data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Boost Management',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Debug controls
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: oliveColor),
            onSelected: (value) async {
              switch (value) {
                case 'toggle_premium':
                  MonetizationService.toggleDebugPremium();
                  await _loadData();
                  break;
                case 'toggle_access':
                  MonetizationService.toggleDebugFullAccess();
                  await _loadData();
                  break;
                case 'refresh':
                  await _loadData();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_premium',
                child: Row(
                  children: [
                    Icon(
                      MonetizationService.isDebugPremiumActive ? Icons.star : Icons.star_border,
                      color: oliveColor,
                    ),
                    SizedBox(width: 8.w),
                    Text('Toggle Debug Premium'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_access',
                child: Row(
                  children: [
                    Icon(
                      MonetizationService.hasDebugFullAccess ? Icons.admin_panel_settings : Icons.security,
                      color: oliveColor,
                    ),
                    SizedBox(width: 8.w),
                    Text('Toggle Full Access'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: oliveColor),
                    SizedBox(width: 8.w),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: oliveColor,
          labelColor: oliveColor,
          unselectedLabelColor: Colors.grey[400],
          tabs: [
            Tab(
              icon: Icon(Icons.rocket_launch),
              text: 'Debug',
            ),
            Tab(
              icon: Icon(Icons.play_circle),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.pause_circle),
              text: 'Paused',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'All',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: oliveColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDebugTab(),
                _buildActiveBoostsTab(),
                _buildPausedBoostsTab(),
                _buildAllBoostsTab(),
              ],
            ),
    );
  }

  Widget _buildDebugTab() {
    final categorizedBoosts = MonetizationService.getCategorizedBoosts(_hasSubscription || MonetizationService.hasDebugFullAccess);
    
    return Column(
      children: [
        // Item ID selector
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Text(
                'Item ID: ',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: _selectedItemId,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  onChanged: (value) {
                    _selectedItemId = value;
                  },
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: oliveColor),
                child: Text('Load'),
              ),
            ],
          ),
        ),
        
        // Status indicators
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator(
                'Premium',
                MonetizationService.isDebugPremiumActive || _hasSubscription,
                Icons.star,
              ),
              _buildStatusIndicator(
                'Full Access',
                MonetizationService.hasDebugFullAccess,
                Icons.admin_panel_settings,
              ),
              _buildStatusIndicator(
                'Subscription',
                _hasSubscription,
                Icons.card_membership,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Boost categories
        Expanded(
          child: ListView(
            children: categorizedBoosts.entries.map((entry) {
              final category = entry.key;
              final boosts = entry.value;
              
              if (boosts.isEmpty) return SizedBox.shrink();
              
              return _buildBoostCategory(category, boosts);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: isActive ? oliveColor : Colors.grey,
          size: 24.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isActive ? oliveColor : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBoostCategory(String category, List<BoostType> boosts) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ExpansionTile(
        title: Text(
          category,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconColor: oliveColor,
        collapsedIconColor: Colors.grey[400],
        children: boosts.map((type) => _buildDebugBoostTile(type)).toList(),
      ),
    );
  }

  Widget _buildDebugBoostTile(BoostType type) {
    final isActive = MonetizationService.isDebugBoostActive(type, _selectedItemId);
    final isPaused = MonetizationService.isDebugBoostPaused(type, _selectedItemId);
    final status = MonetizationService.getDebugBoostStatus(type, _selectedItemId);
    final plan = Boost.boostPlans[type]!;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isActive ? oliveColor : (isPaused ? Colors.orange : Colors.transparent),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isActive ? oliveColor.withOpacity(0.2) : (isPaused ? Colors.orange.withOpacity(0.2) : Colors.grey[700]),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              plan['icon'],
              style: TextStyle(fontSize: 20.sp),
            ),
          ),
        ),
        title: Text(
          plan['name'],
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: TextStyle(
                fontSize: 12.sp,
                color: isActive ? oliveColor : (isPaused ? Colors.orange : Colors.grey[400]),
              ),
            ),
            Text(
              '\$${plan['price'].toStringAsFixed(2)} • ${plan['duration']} days',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPaused)
              IconButton(
                onPressed: () async {
                  await MonetizationService.resumeDebugBoost(type, _selectedItemId);
                  setState(() {});
                },
                icon: Icon(Icons.play_arrow, color: oliveColor),
                tooltip: 'Resume',
              ),
            if (isActive)
              IconButton(
                onPressed: () async {
                  await MonetizationService.pauseDebugBoost(type, _selectedItemId);
                  setState(() {});
                },
                icon: Icon(Icons.pause, color: Colors.orange),
                tooltip: 'Pause',
              ),
            if (!isActive && !isPaused)
              IconButton(
                onPressed: () async {
                  await MonetizationService.activateDebugBoost(type, _selectedItemId);
                  setState(() {});
                },
                icon: Icon(Icons.add_circle, color: oliveColor),
                tooltip: 'Activate',
              ),
            if (isActive || isPaused)
              IconButton(
                onPressed: () async {
                  await MonetizationService.removeDebugBoost(type, _selectedItemId);
                  setState(() {});
                },
                icon: Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBoostsTab() {
    if (_activeBoosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 64.sp, color: Colors.grey[600]),
            SizedBox(height: 16.h),
            Text(
              'No active boosts',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _activeBoosts.length,
      itemBuilder: (context, index) {
        final boost = _activeBoosts[index];
        return _buildBoostCard(boost, isActive: true);
      },
    );
  }

  Widget _buildPausedBoostsTab() {
    if (_pausedBoosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle, size: 64.sp, color: Colors.grey[600]),
            SizedBox(height: 16.h),
            Text(
              'No paused boosts',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _pausedBoosts.length,
      itemBuilder: (context, index) {
        final boost = _pausedBoosts[index];
        return _buildBoostCard(boost, isPaused: true);
      },
    );
  }

  Widget _buildAllBoostsTab() {
    if (_allBoosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64.sp, color: Colors.grey[600]),
            SizedBox(height: 16.h),
            Text(
              'No boost history',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _allBoosts.length,
      itemBuilder: (context, index) {
        final boost = _allBoosts[index];
        return _buildBoostCard(boost);
      },
    );
  }

  Widget _buildBoostCard(Boost boost, {bool isActive = false, bool isPaused = false}) {
    final plan = Boost.boostPlans[boost.type]!;
    final remainingTime = boost.endDate.difference(DateTime.now());
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive ? oliveColor : (isPaused ? Colors.orange : Colors.transparent),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: isActive ? oliveColor.withOpacity(0.2) : (isPaused ? Colors.orange.withOpacity(0.2) : Colors.grey[700]),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Text(
              plan['icon'],
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
        ),
        title: Text(
          plan['name'],
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${boost.itemId}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[400],
              ),
            ),
            if (isActive && remainingTime.inSeconds > 0)
              Text(
                'Expires in ${remainingTime.inDays}d ${remainingTime.inHours % 24}h',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: oliveColor,
                ),
              ),
            if (isPaused)
              Text(
                'Paused - Time saved',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange,
                ),
              ),
            if (!isActive && !isPaused)
              Text(
                'Ended ${DateTime.now().difference(boost.endDate).inDays} days ago',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        trailing: (isActive || isPaused) ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              IconButton(
                onPressed: () async {
                  final success = await MonetizationService.pauseBoost(boost.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Boost paused successfully')),
                    );
                    await _loadData();
                  }
                },
                icon: Icon(Icons.pause, color: Colors.orange),
                tooltip: 'Pause',
              ),
            if (isPaused)
              IconButton(
                onPressed: () async {
                  final success = await MonetizationService.resumeBoost(boost.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Boost resumed successfully')),
                    );
                    await _loadData();
                  }
                },
                icon: Icon(Icons.play_arrow, color: oliveColor),
                tooltip: 'Resume',
              ),
          ],
        ) : null,
      ),
    );
  }
}
