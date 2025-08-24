import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/subscription.dart';
import '../services/monetization_service.dart';

class ModalSubscribe extends StatefulWidget {
  final VoidCallback? onBasicSelected;
  final VoidCallback? onPremiumSelected;
  final VoidCallback? onProSelected;

  const ModalSubscribe({
    super.key,
    this.onBasicSelected,
    this.onPremiumSelected,
    this.onProSelected,
  });

  @override
  State<ModalSubscribe> createState() => _ModalSubscribeState();
}

class _ModalSubscribeState extends State<ModalSubscribe> {

  static void show(BuildContext context, {
    VoidCallback? onBasicSelected,
    VoidCallback? onPremiumSelected,
    VoidCallback? onProSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalSubscribe(
        onBasicSelected: onBasicSelected,
        onPremiumSelected: onPremiumSelected,
        onProSelected: onProSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Title
            Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            Text(
              'Unlock premium features and grow your automotive business',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Basic Plan
            _buildPlanCard(
              title: 'Basic',
              price: 'Free',
              features: [
                'Add cars to garage',
                'Search vehicles',
                'Basic chat features',
              ],
              isRecommended: false,
              isCurrentPlan: true,
              onTap: widget.onBasicSelected,
            ),
            
            SizedBox(height: 16.h),
            
            // Premium Plan
            _buildPlanCard(
              title: 'Premium',
              price: '€3.99/month',
              features: [
                'Everything in Basic',
                'Add accessories & services',
                'Advanced analytics',
                'Priority support',
              ],
              isRecommended: true,
              isCurrentPlan: false,
              onTap: widget.onPremiumSelected,
            ),
            
            SizedBox(height: 16.h),
            
            // Pro Plan
            _buildPlanCard(
              title: 'Pro',
              price: '€7.99/month',
              features: [
                'Everything in Premium',
                'Free promotion (1x/month)',
                'Advanced marketing tools',
                'Business insights',
              ],
              isRecommended: false,
              isCurrentPlan: false,
              onTap: widget.onProSelected,
            ),
            
            SizedBox(height: 24.h),
            
            // Debug Section
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Debug Controls',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Premium Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Active',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Activate to access Accessories & Services',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: MonetizationService.isDebugPremiumActive,
                        onChanged: (value) {
                          MonetizationService.toggleDebugPremium();
                          setState(() {});
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Boost Toggles
                  Text(
                    'Boost Controls:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Top Recommended Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Recommended', style: TextStyle(fontSize: 13.sp)),
                      Switch(
                        value: MonetizationService.isDebugBoostActive(BoostType.topRecommended, "global_test"),
                        onChanged: (value) {
                          MonetizationService.toggleDebugBoost(BoostType.topRecommended, "global_test");
                          setState(() {});
                        },
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                  
                  // Top Brand/Model Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Brand/Model', style: TextStyle(fontSize: 13.sp)),
                      Switch(
                        value: MonetizationService.isDebugBoostActive(BoostType.topBrandModel, "global_test"),
                        onChanged: (value) {
                          MonetizationService.toggleDebugBoost(BoostType.topBrandModel, "global_test");
                          setState(() {});
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                  
                  // Colored Frame Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Colored Frame', style: TextStyle(fontSize: 13.sp)),
                      Switch(
                        value: MonetizationService.isDebugBoostActive(BoostType.coloredFrame, "global_test"),
                        onChanged: (value) {
                          MonetizationService.toggleDebugBoost(BoostType.coloredFrame, "global_test");
                          setState(() {});
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Footer
            Center(
              child: Text(
                'Cancel anytime • Secure payment • No hidden fees',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isRecommended,
    required bool isCurrentPlan,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended 
                ? Colors.blue 
                : isCurrentPlan 
                    ? Colors.green 
                    : Colors.grey.shade300,
            width: isRecommended || isCurrentPlan ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color: isRecommended 
              ? Colors.blue.shade50 
              : isCurrentPlan 
                  ? Colors.green.shade50 
                  : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (isCurrentPlan) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'CURRENT',
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                if (!isCurrentPlan)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Features
            ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16.sp,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            if (!isCurrentPlan) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecommended ? Colors.blue : Colors.grey.shade200,
                    foregroundColor: isRecommended ? Colors.white : Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Select Plan',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
