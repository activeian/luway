import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'marketplace_screen.dart';
import 'add_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/notifications_screen.dart';
import 'profile_screen.dart';
import 'components/search_bar.dart';
import 'services/country_service.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'widgets/recommendations_widget.dart';
import 'settings_screen.dart';

// App Color Scheme Constants
const Color primaryOlive = Color(0xFFB3B760);
const Color darkGreen = Color(0xFF064232);
const Color primaryBlack = Color(0xFF000000);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const MarketplaceScreen(),
    const AddScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  Widget _buildChatIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Icon(Icons.chat);
    }

    return StreamBuilder<int>(
      stream: ChatService.getTotalUnreadMessageCount(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            const Icon(Icons.chat),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryOlive,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: _buildChatIcon(),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Tab Content
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();
  bool _isGuest = false;
  CountryInfo? _currentCountry;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _getCurrentCountry();
  }

  void _checkUserStatus() {
    _isGuest = FirebaseAuth.instance.currentUser == null;
  }

  void _getCurrentCountry() async {
    try {
      _currentCountry = await CountryService.detectCurrentCountry();
      setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Lu',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              TextSpan(
                text: 'Way',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryOlive,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notifications button
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationsCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, color: primaryOlive),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.w,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: primaryOlive),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest Warning
            if (_isGuest)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You\'re browsing as guest. Some features are limited.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search Section
            Text(
              'Car Search',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: primaryBlack,
              ),
            ),
            SizedBox(height: 12.h),

            CarSearchBar(
              hintText: 'Search by license plate (min 2 characters)...',
              currentCountry: _currentCountry,
            ),

            SizedBox(height: 24.h),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: primaryBlack,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.directions_car,
                    title: 'Add Car',
                    subtitle: 'Register your vehicle',
                    onTap: () {
                      // Navigate to Add screen
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._currentIndex = 2;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.store,
                    title: 'Browse',
                    subtitle: 'Explore marketplace',
                    onTap: () {
                      // Navigate to Marketplace
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._currentIndex = 1;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Smart Recommendations
            const RecommendationsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: primaryOlive.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: primaryOlive.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.sp, color: primaryOlive),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: primaryBlack,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
