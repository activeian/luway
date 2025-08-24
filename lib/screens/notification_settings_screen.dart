import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color oliveColor = Color(0xFFB3B760);

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _messageNotifications = true;
  bool _favoriteNotifications = true;
  bool _priceUpdateNotifications = true;
  bool _dailySummaryNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  String _dailySummaryTime = '20:00';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _messageNotifications = prefs.getBool('message_notifications') ?? true;
        _favoriteNotifications =
            prefs.getBool('favorite_notifications') ?? true;
        _priceUpdateNotifications =
            prefs.getBool('price_update_notifications') ?? true;
        _dailySummaryNotifications =
            prefs.getBool('daily_summary_notifications') ?? true;
        _soundEnabled = prefs.getBool('notification_sound') ?? true;
        _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
        _dailySummaryTime = prefs.getString('daily_summary_time') ?? '20:00';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('message_notifications', _messageNotifications);
      await prefs.setBool('favorite_notifications', _favoriteNotifications);
      await prefs.setBool(
          'price_update_notifications', _priceUpdateNotifications);
      await prefs.setBool(
          'daily_summary_notifications', _dailySummaryNotifications);
      await prefs.setBool('notification_sound', _soundEnabled);
      await prefs.setBool('notification_vibration', _vibrationEnabled);
      await prefs.setString('daily_summary_time', _dailySummaryTime);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setările au fost salvate'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving notification settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eroare la salvarea setărilor'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
            child: CircularProgressIndicator(
          color: Color(0xFFB3B760),
        )),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: oliveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Push Notifications Section
            _buildSection(
              title: 'Notifications Push',
              children: [
                _buildSwitchTile(
                  title: 'New messages',
                  subtitle: 'Receive notifications for new messages',
                  value: _messageNotifications,
                  onChanged: (value) {
                    setState(() {
                      _messageNotifications = value;
                    });
                  },
                  icon: Icons.message,
                ),
                _buildSwitchTile(
                  title: 'Listings added to favorites',
                  subtitle: 'When someone adds your listings to favorites',
                  value: _favoriteNotifications,
                  onChanged: (value) {
                    setState(() {
                      _favoriteNotifications = value;
                    });
                  },
                  icon: Icons.favorite,
                ),
                _buildSwitchTile(
                  title: 'Price changes',
                  subtitle: 'When price changes on favorited listings',
                  value: _priceUpdateNotifications,
                  onChanged: (value) {
                    setState(() {
                      _priceUpdateNotifications = value;
                    });
                  },
                  icon: Icons.trending_down,
                ),
                _buildSwitchTile(
                  title: 'Daily summary',
                  subtitle: 'Daily statistics about your listings',
                  value: _dailySummaryNotifications,
                  onChanged: (value) {
                    setState(() {
                      _dailySummaryNotifications = value;
                    });
                  },
                  icon: Icons.analytics,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Sound & Vibration Section
            _buildSection(
              title: 'Sound & Vibration',
              children: [
                _buildSwitchTile(
                  title: 'Notification sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  icon: Icons.volume_up,
                ),
                _buildSwitchTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                  icon: Icons.vibration,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Schedule Section
            _buildSection(
              title: 'Schedule',
              children: [
                _buildTimeTile(
                  title: 'Daily summary time',
                  subtitle: 'When to receive daily summary',
                  time: _dailySummaryTime,
                  enabled: _dailySummaryNotifications,
                  onTimeChanged: (time) {
                    setState(() {
                      _dailySummaryTime = time;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Info Section
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: oliveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: oliveColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: oliveColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'About notifications',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: oliveColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Notifications help you stay updated with activity in LuWay. You can customize which notifications you receive and when you receive them.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: oliveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: oliveColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: oliveColor,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required String time,
    required bool enabled,
    required ValueChanged<String> onTimeChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: oliveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.schedule,
          color: enabled ? oliveColor : Colors.grey,
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: GestureDetector(
        onTap: enabled ? () => _showTimePicker(onTimeChanged) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: enabled
                ? oliveColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: enabled
                  ? oliveColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: enabled ? oliveColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(ValueChanged<String> onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_dailySummaryTime.split(':')[0]),
        minute: int.parse(_dailySummaryTime.split(':')[1]),
      ),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeChanged(formattedTime);
    }
  }
}
