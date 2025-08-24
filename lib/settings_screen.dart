import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFB3B760).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: const Color(0xFFB3B760)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: const Color(0xFFB3B760),
                    child: user?.photoURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: Image.network(
                              user!.photoURL!,
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Guest User',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // App Settings
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Configure notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Support & Information
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      'Support & Information',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'About',
                    subtitle:
                        '${AppConstants.appName} v${AppConstants.appVersion}',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: AppConstants.appName,
                        applicationVersion: AppConstants.appVersion,
                        applicationLegalese:
                            '© 2024 ${AppConstants.appName}. All rights reserved.',
                        children: [
                          Text(AppConstants.appDescription),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Account Actions
            if (user != null)
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                                'Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _signOut();
                                },
                                child: Text(
                                  'Sign Out',
                                  style:
                                      TextStyle(color: const Color(0xFF064232)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFF064232)),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
