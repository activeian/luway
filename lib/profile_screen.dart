import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'screens/my_garage_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/my_listings_screen.dart';
// import 'screens/subscription_screen.dart'; // Temporary disabled
import 'screens/payment_history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/help_support_screen.dart';
import 'services/car_service.dart';
import 'services/marketplace_service.dart';
// import 'services/monetization_service.dart'; // Temporary disabled
import 'services/view_tracking_service.dart';
// import 'models/subscription.dart'; // Temporary disabled

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isGuest = false;
  User? _currentUser;
  int _carsCount = 0;
  int _totalViews = 0;
  double _averageRating = 0.0;
  bool _isLoadingStats = false;
  // Subscription? _activeSubscription; // Temporary disabled

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() {
    _currentUser = FirebaseAuth.instance.currentUser;
    _isGuest = _currentUser == null;
    if (!_isGuest) {
      _loadUserStatistics();
      // _loadUserSubscription(); // Temporary disabled
    }
  }

  // Future<void> _loadUserSubscription() async {
  //   if (_currentUser == null) return;

  //   try {
  //     final subscription = await MonetizationService.getUserActiveSubscription(_currentUser!.uid);
  //     setState(() {
  //       _activeSubscription = subscription;
  //     });
  //   } catch (e) {
  //     print('Error loading subscription: $e');
  //   }
  // }

  Future<void> _loadUserStatistics() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Load cars count
      final cars = await CarService.getUserCars(_currentUser!.uid);
      _carsCount = cars.length;

      // Load real total views using ViewTrackingService
      final realTotalViews =
          await ViewTrackingService.getUserTotalViews(_currentUser!.uid);
      _totalViews = realTotalViews;

      // Load marketplace items for rating calculation
      final items = await MarketplaceService.getUserItems(_currentUser!.uid);

      // Calculate average rating from user's marketplace items
      final itemsWithRating = items.where((item) => item.averageRating > 0);
      if (itemsWithRating.isNotEmpty) {
        _averageRating = itemsWithRating.fold<double>(
                0, (sum, item) => sum + item.averageRating) /
            itemsWithRating.length;
      } else {
        _averageRating = 0.0;
      }

      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        // Use default values on error
        _carsCount = 0;
        _totalViews = 0;
        _averageRating = 0.0;
      });
      print('Error loading user statistics: $e');
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    // If profile was updated, refresh the data
    if (result == true) {
      _checkUserStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isGuest ? _buildGuestProfile() : _buildUserProfile(),
    );
  }

  Widget _buildGuestProfile() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          CircleAvatar(
            radius: 50.r,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.person,
              size: 60.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Guest User',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Limited access to features',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3B760),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Login to Access Full Features',
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(height: 32.h),
          _buildLimitedFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFB3B760), const Color(0xFF064232)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  backgroundColor: Colors.white,
                  child: _currentUser?.photoURL == null
                      ? Text(
                          _currentUser?.displayName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB3B760),
                          ),
                        )
                      : null,
                ),
                SizedBox(height: 16.h),
                Text(
                  _currentUser?.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Premium Member', // TODO: Get actual subscription status
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Edit Profile Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _editProfile(),
                icon: Icon(Icons.edit, size: 18.sp),
                label: Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF6B7A1E),
                  side: BorderSide(color: Color(0xFF6B7A1E)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Statistics Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Cars',
                        _isLoadingStats ? '-' : '$_carsCount',
                        Icons.directions_car)),
                SizedBox(width: 12.w),
                Expanded(
                    child: _buildStatCard(
                        'Views',
                        _isLoadingStats ? '-' : '$_totalViews',
                        Icons.visibility)),
                SizedBox(width: 12.w),
                Expanded(
                    child: _buildStatCard(
                        'Rating',
                        _isLoadingStats
                            ? '-'
                            : _averageRating.toStringAsFixed(1),
                        Icons.star)),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Menu Items
          _buildMenuItem(
            icon: Icons.garage,
            title: 'My Garage',
            subtitle: 'Manage your vehicles',
            onTap: () => _navigateToMyGarage(),
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Your saved listings',
            onTap: () => _navigateToFavorites(),
          ),
          _buildMenuItem(
            icon: Icons.list_alt,
            title: 'My Listings',
            subtitle: 'Active marketplace listings',
            onTap: () => _navigateToMyListings(),
          ),

          // Subscription Section - Temporary disabled
          // _buildSubscriptionMenuItem(),

          _buildMenuItem(
            icon: Icons.receipt_long,
            title: 'Payment History',
            subtitle: 'View transaction history',
            onTap: () => _navigateToPaymentHistory(),
          ),
          _buildMenuItem(
            icon: Icons.analytics,
            title: 'Analytics',
            subtitle: 'View detailed statistics',
            onTap: () => _navigateToAnalytics(),
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get assistance',
            onTap: () => _navigateToHelpSupport(),
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => _logout(),
            isDestructive: true,
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildLimitedFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you can do as a guest:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        _buildFeatureItem('✅ Search for vehicles', true),
        _buildFeatureItem('✅ Start conversations', true),
        _buildFeatureItem('❌ Save chat history', false),
        _buildFeatureItem('❌ Add vehicles to garage', false),
        _buildFeatureItem('❌ Post marketplace listings', false),
        _buildFeatureItem('❌ Access premium features', false),
      ],
    );
  }

  Widget _buildFeatureItem(String text, bool available) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: available ? Colors.green : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: const Color(0xFFB3B760)),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDestructive
              ? const Color(0xFF064232).withOpacity(0.1)
              : const Color(0xFFB3B760).withOpacity(0.1),
          child: Icon(
            icon,
            color: isDestructive
                ? const Color(0xFF064232)
                : const Color(0xFFB3B760),
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFF064232) : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _navigateToMyGarage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyGarageScreen()),
    );
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }

  void _navigateToMyListings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyListingsScreen()),
    );
  }

  // Widget _buildSubscriptionMenuItem() {
  //   return GestureDetector(
  //     onTap: () => _navigateToSubscriptions(),
  //     child: Container(
  //       margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
  //       padding: EdgeInsets.all(16.w),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12.r),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withOpacity(0.1),
  //             spreadRadius: 1,
  //             blurRadius: 5,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 40.w,
  //             height: 40.h,
  //             decoration: BoxDecoration(
  //               color: _activeSubscription != null ? const Color(0xFF007AFF) : Colors.grey[300],
  //               borderRadius: BorderRadius.circular(10.r),
  //             ),
  //             child: Icon(
  //               Icons.diamond,
  //               color: _activeSubscription != null ? Colors.white : Colors.grey[600],
  //               size: 20.sp,
  //             ),
  //           ),
  //           SizedBox(width: 16.w),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   _activeSubscription != null
  //                     ? 'Active Subscription'
  //                     : 'Get Premium',
  //                   style: TextStyle(
  //                     fontSize: 16.sp,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 SizedBox(height: 2.h),
  //                 Text(
  //                   _activeSubscription != null
  //                     ? _getSubscriptionDescription()
  //                     : 'Unlock all premium features',
  //                   style: TextStyle(
  //                     fontSize: 14.sp,
  //                     color: Colors.grey[600],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           if (_activeSubscription != null)
  //             Container(
  //               padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
  //               decoration: BoxDecoration(
  //                 color: Colors.green,
  //                 borderRadius: BorderRadius.circular(6.r),
  //               ),
  //               child: Text(
  //                 'ACTIVE',
  //                 style: TextStyle(
  //                   fontSize: 11.sp,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           SizedBox(width: 8.w),
  //           Icon(
  //             Icons.arrow_forward_ios,
  //             size: 16.sp,
  //             color: Colors.grey[400],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // String _getSubscriptionDescription() {
  //   if (_activeSubscription == null) return '';

  //   switch (_activeSubscription!.type) {
  //     case SubscriptionType.monthly:
  //       return 'Monthly Premium - \$4.99/month';
  //     case SubscriptionType.annual:
  //       return 'Annual Premium - \$24.99/year';
  //     case SubscriptionType.lifetime:
  //       return 'Lifetime Premium - One-time purchase';
  //   }
  // }

  // void _navigateToSubscriptions() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const SubscriptionScreen(),
  //     ),
  //   );
  // }

  void _navigateToPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentHistoryScreen(),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsScreen(),
      ),
    );
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064232)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
