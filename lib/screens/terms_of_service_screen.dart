import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: const Color(0xFFB3B760),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB3B760),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.h),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the LuWay mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use our App.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'LuWay is a mobile application that allows users to buy, sell, and browse automobiles. Our platform facilitates connections between buyers and sellers of vehicles.',
            ),
            
            _buildSection(
              '3. User Accounts',
              'To use certain features of the App, you must create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
            ),
            
            _buildSection(
              '4. User Content',
              'Users may post vehicle listings, photos, and other content. You retain ownership of your content but grant LuWay a license to use, display, and distribute your content within the App.',
            ),
            
            _buildSection(
              '5. Prohibited Activities',
              'Users are prohibited from: posting false or misleading information, engaging in fraudulent activities, violating any applicable laws, harassing other users, or attempting to circumvent App security measures.',
            ),
            
            _buildSection(
              '6. Payment and Fees',
              'LuWay may charge fees for certain premium features. All fees are clearly disclosed before purchase. Payments are processed through secure third-party payment providers.',
            ),
            
            _buildSection(
              '7. Privacy',
              'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.',
            ),
            
            _buildSection(
              '8. Disclaimers',
              'LuWay is provided "as is" without warranties of any kind. We do not guarantee the accuracy of listings or the reliability of users. Vehicle transactions are between buyers and sellers.',
            ),
            
            _buildSection(
              '9. Limitation of Liability',
              'LuWay shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App or any vehicle transactions.',
            ),
            
            _buildSection(
              '10. Termination',
              'We may terminate or suspend your account at any time for violation of these Terms. You may delete your account at any time through the App settings.',
            ),
            
            _buildSection(
              '11. Changes to Terms',
              'We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the new Terms.',
            ),
            
            _buildSection(
              '12. Contact Us',
              'If you have any questions about these Terms, please contact us through the App support section or email us at support@luway.app.',
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
