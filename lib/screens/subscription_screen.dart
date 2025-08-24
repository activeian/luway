import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';
import '../services/monetization_service.dart';
import '../services/google_play_purchase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool showAsModal;
  final String? fromFeature; // 'services' or 'accessories'

  const SubscriptionScreen({
    super.key,
    this.showAsModal = false,
    this.fromFeature,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  Subscription? _currentSubscription;
  final GooglePlayPurchaseService _purchaseService =
      GooglePlayPurchaseService();

  @override
  void initState() {
    super.initState();
    _initializePurchaseService();
    _loadCurrentSubscription();
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
  }

  Future<void> _loadCurrentSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final subscription =
          await MonetizationService.getUserActiveSubscription(user.uid);
      setState(() {
        _currentSubscription = subscription;
      });
    }
  }

  Future<void> _purchaseSubscription(SubscriptionType type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Map subscription type to purchase service type
      String subscriptionKey;
      switch (type) {
        case SubscriptionType.monthly:
          subscriptionKey = 'monthly';
          break;
        case SubscriptionType.annual:
          subscriptionKey = 'annual';
          break;
        case SubscriptionType.lifetime:
          subscriptionKey = 'lifetime';
          break;
      }

      print('🛒 Starting Google Play subscription purchase: $subscriptionKey');

      final success =
          await _purchaseService.purchaseSubscription(subscriptionKey);

      if (success) {
        // Purchase initiated successfully - actual completion will be handled by the purchase stream
        print('✅ Subscription purchase initiated successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Subscription purchase initiated! Processing through Google Play...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );

        // Note: Actual subscription creation should happen after purchase verification
        // in the GooglePlayPurchaseService._handleSuccessfulPurchase method
        await _loadCurrentSubscription();

        // If opened as modal, close it
        if (widget.showAsModal) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to initiate Google Play subscription purchase');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: widget.showAsModal
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => _showDebugDialog(context),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Controls',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFFB3B760),
            ))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header message
                  if (widget.fromFeature != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 48.sp,
                            color: Colors.blue.shade600,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Premium Feature Required',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Access to ${widget.fromFeature} requires an active subscription',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Current subscription status
                  if (_currentSubscription != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48.sp,
                            color: Colors.green.shade600,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Active Subscription',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            _currentSubscription!.type
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!_currentSubscription!.isLifetime) ...[
                            SizedBox(height: 4.h),
                            Text(
                              'Expires: ${_formatDate(_currentSubscription!.endDate!)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Subscription plans
                  Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Unlock premium features and boost your listings',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Subscription cards
                  ...SubscriptionType.values.map((type) {
                    final plan = Subscription.subscriptionPlans[type]!;
                    final isCurrentPlan = _currentSubscription?.type == type;
                    final isPopular = type == SubscriptionType.annual;

                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isCurrentPlan
                                    ? Colors.green.shade300
                                    : isPopular
                                        ? Colors.blue.shade300
                                        : Colors.grey.shade200,
                                width: isCurrentPlan || isPopular ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: TextStyle(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          if (type != SubscriptionType.lifetime)
                                            Text(
                                              '${plan['duration']} days',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${plan['price']}',
                                          style: TextStyle(
                                            fontSize: 28.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                        if (type ==
                                            SubscriptionType.annual) ...[
                                          Text(
                                            'Save 50%',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.red.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16.h),

                                // Benefits
                                ...plan['benefits'].map<Widget>((benefit) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 16.sp,
                                          color: Colors.green.shade600,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            benefit,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                SizedBox(height: 20.h),

                                // Purchase button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isCurrentPlan
                                        ? null
                                        : () => _purchaseSubscription(type),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentPlan
                                          ? Colors.grey.shade300
                                          : isPopular
                                              ? Colors.blue.shade600
                                              : const Color(0xFF8FBC8F),
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    child: Text(
                                      isCurrentPlan
                                          ? 'Current Plan'
                                          : 'Choose Plan',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 24.h),

                                // Debug/Testing Section
                                Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.bug_report,
                                              color: Colors.orange,
                                              size: 20.sp),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Testing Controls',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 16.h),

                                      // Premium Testing Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Premium Access',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  'Test Accessories & Services access',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: MonetizationService
                                                .isDebugPremiumActive,
                                            onChanged: (value) {
                                              MonetizationService
                                                  .toggleDebugPremium();
                                              setState(() {});
                                            },
                                            activeColor: Colors.blue,
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 16.h),

                                      // Divider
                                      Container(
                                        height: 1.h,
                                        color: Colors.orange.shade200,
                                      ),

                                      SizedBox(height: 16.h),

                                      // Boost Testing Section
                                      Text(
                                        'Boost Testing (Free for Testing)',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),

                                      SizedBox(height: 12.h),

                                      // Top Recommended Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Top Recommended',
                                                  style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                Text(
                                                  'Show items as top recommended (\$0 test)',
                                                  style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: MonetizationService
                                                .isDebugBoostActive(
                                                    BoostType.topRecommended,
                                                    'global_test'),
                                            onChanged: (value) async {
                                              await MonetizationService
                                                  .toggleDebugBoost(
                                                      BoostType.topRecommended,
                                                      'global_test');
                                              setState(() {});
                                            },
                                            activeColor: Colors.purple,
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8.h),

                                      // Top Brand/Model Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Top Brand/Model',
                                                  style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                Text(
                                                  'Show items as top brand/model (\$0 test)',
                                                  style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: MonetizationService
                                                .isDebugBoostActive(
                                                    BoostType.topBrandModel,
                                                    "global_test"),
                                            onChanged: (value) async {
                                              await MonetizationService
                                                  .toggleDebugBoost(
                                                      BoostType.topBrandModel,
                                                      "global_test");
                                              setState(() {});
                                            },
                                            activeColor: Colors.red,
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8.h),

                                      // Colored Frame Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Colored Frame',
                                                  style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                Text(
                                                  'Show items with colored frame (\$0 test)',
                                                  style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: MonetizationService
                                                .isDebugBoostActive(
                                                    BoostType.coloredFrame,
                                                    "global_test"),
                                            onChanged: (value) async {
                                              await MonetizationService
                                                  .toggleDebugBoost(
                                                      BoostType.coloredFrame,
                                                      "global_test");
                                              setState(() {});
                                            },
                                            activeColor: Colors.orange,
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8.h),

                                      // Label Tags Toggle
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Label Tags',
                                                  style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                                Text(
                                                  'Add labels like "Sale", "New" (\$0 test)',
                                                  style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: MonetizationService
                                                .isDebugBoostActive(
                                                    BoostType.labelTags,
                                                    "global_test"),
                                            onChanged: (value) async {
                                              await MonetizationService
                                                  .toggleDebugBoost(
                                                      BoostType.labelTags,
                                                      "global_test");
                                              setState(() {});
                                            },
                                            activeColor: Colors.pink,
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 12.h),

                                      // Status indicator
                                      if (MonetizationService
                                              .isDebugPremiumActive ||
                                          MonetizationService
                                              .isDebugBoostActive(
                                                  BoostType.topRecommended,
                                                  "global_test") ||
                                          MonetizationService
                                              .isDebugBoostActive(
                                                  BoostType.topBrandModel,
                                                  "global_test") ||
                                          MonetizationService
                                              .isDebugBoostActive(
                                                  BoostType.coloredFrame,
                                                  "global_test") ||
                                          MonetizationService
                                              .isDebugBoostActive(
                                                  BoostType.labelTags,
                                                  "global_test")) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            border: Border.all(
                                                color: Colors.green.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 16.sp),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  'Testing mode active! You can now test features at \$0 cost.',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color:
                                                        Colors.green.shade800,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ), // Popular badge
                          if (isPopular)
                            Positioned(
                              top: -1,
                              left: 20.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'MOST POPULAR',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Current plan badge
                          if (isCurrentPlan)
                            Positioned(
                              top: -1,
                              left: 20.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  SizedBox(height: 24.h),

                  // Terms and conditions
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '• Subscriptions auto-renew unless cancelled\n'
                          '• Cancel anytime in your account settings\n'
                          '• No refunds for partial periods\n'
                          '• Lifetime subscription is one-time payment\n'
                          '• Premium features require active subscription',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
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

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8.w),
              Text('Debug Controls'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Toggle these for testing purposes:',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16.h),

              // Premium Toggle
              SwitchListTile(
                title: Text('Premium Active'),
                subtitle: Text('Simulate premium subscription'),
                value: MonetizationService.isDebugPremiumActive,
                onChanged: (value) {
                  MonetizationService.toggleDebugPremium();
                  setDialogState(() {});
                  setState(() {}); // Refresh main screen
                },
                activeColor: Colors.blue,
              ),

              Divider(),

              // Boost Toggles
              Text(
                'Boost Simulations:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),

              SwitchListTile(
                title: Text('Top Recommended'),
                subtitle: Text('Show item as top recommended'),
                value: MonetizationService.isDebugBoostActive(
                    BoostType.topRecommended, "global_test"),
                onChanged: (value) async {
                  await MonetizationService.toggleDebugBoost(
                      BoostType.topRecommended, "global_test");
                  setDialogState(() {});
                  setState(() {}); // Refresh main screen
                },
                activeColor: Colors.purple,
              ),

              SwitchListTile(
                title: Text('Top Brand/Model'),
                subtitle: Text('Show item as top brand/model'),
                value: MonetizationService.isDebugBoostActive(
                    BoostType.topBrandModel, "global_test"),
                onChanged: (value) async {
                  await MonetizationService.toggleDebugBoost(
                      BoostType.topBrandModel, "global_test");
                  setDialogState(() {});
                  setState(() {}); // Refresh main screen
                },
                activeColor: Colors.red,
              ),

              SwitchListTile(
                title: Text('Colored Frame'),
                subtitle: Text('Show item with colored frame'),
                value: MonetizationService.isDebugBoostActive(
                    BoostType.coloredFrame, "global_test"),
                onChanged: (value) async {
                  await MonetizationService.toggleDebugBoost(
                      BoostType.coloredFrame, "global_test");
                  setDialogState(() {});
                  setState(() {}); // Refresh main screen
                },
                activeColor: Colors.orange,
              ),

              SwitchListTile(
                title: Text('Label Tags'),
                subtitle: Text('Add labels like "Sale", "New"'),
                value: MonetizationService.isDebugBoostActive(
                    BoostType.labelTags, "global_test"),
                onChanged: (value) async {
                  await MonetizationService.toggleDebugBoost(
                      BoostType.labelTags, "global_test");
                  setDialogState(() {});
                  setState(() {}); // Refresh main screen
                },
                activeColor: Colors.pink,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
