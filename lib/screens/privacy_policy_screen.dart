import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: () => _launchPrivacyUrl(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy for LuWay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Car Owner Finder & Auto Marketplace',
                    style: TextStyle(
                      color: const Color(0xFFBBBBBB),
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(Icons.update, color: const Color(0xFF4A9EFF), size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Last Updated: August 3, 2025',
                        style: TextStyle(
                          color: const Color(0xFF4A9EFF),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () => _launchEmail(),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: const Color(0xFF4A9EFF), size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Contact: info.studio085@gmail.com',
                          style: TextStyle(
                            color: const Color(0xFF4A9EFF),
                            fontSize: 14.sp,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Privacy Policy Content
            _buildSection(
              '1. INTRODUCTION',
              'Welcome to LuWay, the ultimate automotive platform that combines license plate owner discovery with a comprehensive auto marketplace. This Privacy Policy explains in detail how we collect, use, process, and protect your personal information when you use our mobile application and related services.\n\nBy using LuWay, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy.',
            ),
            
            _buildSection(
              '2. INFORMATION WE COLLECT',
              '• Personal Information: Full name, email address, phone number, profile photo\n• Authentication Data: Encrypted passwords, OAuth tokens from Google Sign-In\n• Payment Information: Credit card details, PayPal information, transaction history\n• Vehicle Information: License plate numbers, vehicle details, ownership records\n• Location Data: GPS coordinates, addresses, navigation routes',
            ),
            
            _buildLocationSection(),
            
            _buildSection(
              '4. PAYMENT AND FINANCIAL INFORMATION',
              '• Payment Data Collection: Encrypted card numbers, alternative payments, billing addresses\n• Payment Security: PCI DSS compliance, end-to-end encryption, fraud detection\n• Financial Analytics: Spending patterns, market trends, revenue tracking',
            ),
            
            _buildSection(
              '5. DATA SHARING AND DISCLOSURE',
              '• Service Providers: Payment processors, cloud storage, analytics services\n• Legal Compliance: Law enforcement when required, government agencies\n• Business Partners: Automotive dealers, service providers, insurance companies\n• Data We Never Share: Complete license plate databases, personal location history',
            ),
            
            _buildSection(
              '6. DATA SECURITY MEASURES',
              '• Technical Safeguards: AES-256 encryption, multi-factor authentication, 24/7 monitoring\n• Physical Security: Military-grade data centers, encrypted storage devices\n• Employee Security: Background checks, training programs, access limitations',
            ),
            
            _buildSection(
              '7. YOUR PRIVACY RIGHTS',
              '• Access Rights: Data portability, account information, usage history\n• Control Rights: Data correction, deletion, processing restriction\n• Location Controls: Permission management, precision settings, anonymous usage',
            ),
            
            _buildSection(
              '8. CONTACT INFORMATION',
              'For questions about this Privacy Policy or our data practices:',
            ),
            
            // Contact Cards
            _buildContactCard(),
            
            SizedBox(height: 20.h),
            
            // Full Policy Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A9EFF), Color(0xFF007AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Complete Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Read the full detailed privacy policy with all sections and technical specifications',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () => _showFullPrivacyPolicy(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF007AFF),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Read Full Policy',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF4A9EFF),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFF6B6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: const Color(0xFFFF6B6B), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '3. LOCATION DATA USAGE (DETAILED)',
                style: TextStyle(
                  color: const Color(0xFFFF6B6B),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildLocationItem(
            'Precise Location (ACCESS_FINE_LOCATION)',
            'GPS coordinates for distance calculations to automotive services, address details for marketplace listings, real-time navigation during active sessions.',
          ),
          SizedBox(height: 8.h),
          _buildLocationItem(
            'Approximate Location (ACCESS_COARSE_LOCATION)',
            'City/region for marketplace filtering, network-based location when GPS unavailable, regional services and content.',
          ),
          SizedBox(height: 8.h),
          _buildLocationItem(
            'Background Location (ACCESS_BACKGROUND_LOCATION)',
            'Navigation continuity during active sessions ONLY. We NEVER use background location for tracking, advertising, or data collection.',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String title, String description) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: TextStyle(
              color: const Color(0xFFBBBBBB),
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF4A9EFF)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _launchEmail(),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: const Color(0xFF4A9EFF), size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'info.studio085@gmail.com',
                          style: TextStyle(
                            color: const Color(0xFF4A9EFF),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, color: const Color(0xFF4A9EFF), size: 16.sp),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _launchPrivacyUrl(),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.web, color: const Color(0xFF4A9EFF), size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy Website',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'https://wzsgame.com/privacy.html',
                          style: TextStyle(
                            color: const Color(0xFF4A9EFF),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, color: const Color(0xFF4A9EFF), size: 16.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FullPrivacyPolicyScreen(),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info.studio085@gmail.com',
      query: 'subject=LuWay Privacy Policy Inquiry',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPrivacyUrl() async {
    final Uri url = Uri.parse('https://wzsgame.com/privacy.html');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class FullPrivacyPolicyScreen extends StatelessWidget {
  const FullPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Complete Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Text(
            _getFullPrivacyPolicyText(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  String _getFullPrivacyPolicyText() {
    return '''Privacy Policy for LuWay - Car Owner Finder & Auto Marketplace

Last Updated: August 3, 2025
Effective Date: August 3, 2025

Contact Information:
- Website Privacy Policy: https://wzsgame.com/privacy.html
- Email: info.studio085@gmail.com
- App Name: LuWay - Car Owner Finder & Auto Marketplace

1. INTRODUCTION
Welcome to LuWay, the ultimate automotive platform that combines license plate owner discovery with a comprehensive auto marketplace. This Privacy Policy explains in detail how we collect, use, process, and protect your personal information when you use our mobile application and related services.

By using LuWay, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy. If you do not agree with any part of this policy, please do not use our application.

2. INFORMATION WE COLLECT

2.1 Personal Information
- Account Information: Full name, email address, phone number, profile photo
- Authentication Data: Encrypted passwords, OAuth tokens from Google Sign-In
- Identity Verification: Government-issued ID numbers for marketplace verification
- Payment Information: Credit card details, PayPal information, transaction history
- Communication Records: Messages, support tickets, feedback submissions

2.2 Location Information (DETAILED)
We collect various types of location data to provide core application functionality:

2.2.1 Precise Location (ACCESS_FINE_LOCATION)
- GPS Coordinates: Exact latitude and longitude for distance calculations to automotive services
- Address Details: Street-level addresses for marketplace listings and service locations
- Real-time Navigation: Current position during active navigation to service providers
- Service Area Mapping: Precise location boundaries for service provider coverage areas
- Emergency Contact: Location sharing for urgent license plate owner contact situations

2.2.2 Approximate Location (ACCESS_COARSE_LOCATION)
- City/Region: General area for marketplace filtering and regional content
- Network-based Location: Cell tower and Wi-Fi positioning when GPS unavailable
- Regional Services: Area-specific automotive services and legal requirements

2.2.3 Background Location (ACCESS_BACKGROUND_LOCATION)
- Navigation Continuity: Maintains GPS accuracy during active navigation sessions only
- Service Proximity Alerts: Notifications when approaching booked service locations
- Emergency Response: Enhanced accuracy for urgent license plate contact situations
- IMPORTANT: We NEVER use background location for tracking, advertising, or data collection purposes

2.3 Vehicle Information
- License Plate Numbers: Plates searched and owned vehicles registered
- Vehicle Details: Make, model, year, VIN numbers, modification history
- Ownership Records: Registration documents, insurance information
- Maintenance History: Service records, repair documentation, warranty information

2.4 Marketplace Data
- Listing Information: Product descriptions, pricing, availability status
- Transaction Records: Purchase history, payment methods, delivery tracking
- Review System: Ratings, comments, seller feedback, dispute resolutions
- Search History: Products viewed, filters applied, saved searches

2.5 Technical Information
- Device Data: Device ID, operating system, app version, hardware specifications
- Usage Analytics: Screen interactions, feature usage patterns, session duration
- Performance Metrics: App crashes, loading times, error reports
- Network Information: IP address, connection type, network provider

3. HOW WE USE YOUR INFORMATION

3.1 Core Application Functions
- License Plate Lookup: Connecting car owners for parking, emergencies, and community building
- Marketplace Operations: Facilitating vehicle sales, auto parts trading, and service bookings
- Location Services: Calculating distances, providing directions, and matching regional services
- Payment Processing: Handling transactions, managing subscriptions, processing refunds

3.2 Service Enhancement
- Personalization: Customizing content based on location, search history, and preferences
- Recommendations: Suggesting relevant vehicles, parts, and services
- Performance Optimization: Improving app speed, reliability, and user experience
- Security Monitoring: Detecting fraud, preventing abuse, protecting user accounts

3.3 Communication
- Service Notifications: Updates on bookings, listings, and account activity
- Marketing Communications: Promotional offers, new features, community updates
- Support Services: Customer service, technical assistance, dispute resolution
- Legal Communications: Terms updates, policy changes, compliance notifications

4. LOCATION DATA USAGE (COMPREHENSIVE DETAIL)

4.1 Distance Calculation Services
- Real-time Measurements: GPS-powered distance calculation to automotive service providers
- Service Radius: Determining which mechanics, dealerships, and parts suppliers serve your area
- Travel Time Estimates: Providing accurate arrival times for service appointments
- Route Optimization: Finding the most efficient paths to multiple automotive destinations

4.2 Google Maps Integration
- Navigation Services: One-tap directions to seller meetups and service locations
- Address Verification: Confirming service provider locations and marketplace pickup points
- Street View Integration: Visual confirmation of business locations and seller meeting spots
- Traffic-aware Routing: Real-time traffic integration for accurate travel estimates

4.3 Regional Content Delivery
- Local Regulations: Displaying region-specific automotive laws and requirements
- Currency Localization: Showing prices in local currency with real-time conversion
- Language Adaptation: Providing content in local languages and cultural contexts
- Emergency Services: Connecting to local automotive emergency and towing services

4.4 Privacy Controls for Location
- Granular Permissions: Choose between precise, approximate, or no location sharing
- Temporary Sharing: Location access limited to active app sessions only
- Anonymous Mode: Location services without personal identification
- Manual Override: Option to manually enter addresses instead of GPS location

5. PAYMENT AND FINANCIAL INFORMATION

5.1 Payment Data Collection
- Credit Card Information: Encrypted card numbers, expiration dates, CVV codes
- Alternative Payments: PayPal, Google Pay, Apple Pay, bank transfer details
- Billing Addresses: Required for payment verification and tax compliance
- Transaction History: Complete records of all marketplace purchases and service payments

5.2 Payment Security
- PCI DSS Compliance: Industry-standard payment card data protection
- Encryption: End-to-end encryption for all financial transactions
- Fraud Detection: Advanced algorithms to identify and prevent fraudulent activities
- Secure Storage: Payment information stored in certified, secure data centers

5.3 Financial Analytics
- Spending Patterns: Analysis of purchase behavior for personalized recommendations
- Market Trends: Aggregate pricing data to inform market value estimates
- Revenue Tracking: For sellers, comprehensive sales analytics and profit reporting
- Tax Reporting: Generating necessary tax documents for marketplace transactions

6. DATA SHARING AND DISCLOSURE

6.1 Service Providers
- Payment Processors: Stripe, PayPal, and other certified payment services
- Cloud Storage: Google Cloud Platform, AWS for secure data storage
- Analytics Services: Firebase Analytics, Google Analytics for app improvement
- Mapping Services: Google Maps API for location and navigation services

6.2 Legal Compliance
- Law Enforcement: When required by valid legal processes or court orders
- Government Agencies: Compliance with automotive registration and taxation requirements
- Regulatory Bodies: Adherence to consumer protection and marketplace regulations
- Emergency Situations: Sharing location data for emergency response services

6.3 Business Partners
- Automotive Dealers: Verified dealer information for marketplace integration
- Service Providers: Certified mechanics and service centers for quality assurance
- Insurance Companies: Optional integration for coverage verification and claims
- Financial Institutions: For advanced payment options and credit services

6.4 Data We Never Share
- Complete License Plate Databases: We never sell or share comprehensive plate information
- Personal Location History: Historical location data remains strictly confidential
- Private Communications: Messages between users are never shared with third parties
- Financial Details: Complete financial information is never shared without explicit consent

7. DATA SECURITY MEASURES

7.1 Technical Safeguards
- Encryption: AES-256 encryption for data at rest, TLS 1.3 for data in transit
- Access Controls: Multi-factor authentication and role-based access limitations
- Security Monitoring: 24/7 monitoring for suspicious activities and potential breaches
- Regular Audits: Quarterly security assessments by independent third-party experts

7.2 Physical Security
- Data Centers: Military-grade security at certified data storage facilities
- Hardware Protection: Encrypted storage devices with secure destruction protocols
- Access Logs: Comprehensive logging of all physical and digital access attempts
- Backup Security: Encrypted backups stored in geographically diverse locations

7.3 Employee Security
- Background Checks: Comprehensive screening for all employees with data access
- Training Programs: Regular security awareness and data protection training
- Access Limitations: Strict need-to-know basis for accessing user information
- Confidentiality Agreements: Legal obligations for all staff regarding data protection

8. DATA RETENTION POLICIES

8.1 Account Information
- Active Accounts: Data retained as long as account remains active
- Inactive Accounts: Data deleted after 3 years of inactivity with prior notification
- Deleted Accounts: Most data permanently deleted within 30 days of account deletion
- Legal Retention: Some data retained longer for legal compliance and dispute resolution

8.2 Location Data
- Real-time Location: Immediately deleted after navigation session completion
- Search History: Location-based searches retained for 6 months for service improvement
- Service Locations: Business addresses retained indefinitely for marketplace functionality
- Emergency Contacts: Location data for emergency situations retained for 1 year

8.3 Financial Records
- Transaction Data: Retained for 7 years for tax and legal compliance
- Payment Methods: Credit card information deleted immediately after transaction completion
- Billing History: Retained for 5 years for accounting and dispute resolution
- Tax Documents: Retained permanently or as required by applicable tax laws

9. YOUR PRIVACY RIGHTS

9.1 Access Rights
- Data Portability: Download all your personal data in machine-readable format
- Account Information: View and edit all account details and preferences
- Usage History: Access complete history of app usage and interactions
- Data Sources: Information about where we obtained your personal data

9.2 Control Rights
- Data Correction: Update incorrect or outdated personal information
- Data Deletion: Request permanent deletion of your personal data
- Processing Restriction: Limit how we use your data for specific purposes
- Marketing Opt-out: Unsubscribe from promotional communications at any time

9.3 Location Controls
- Permission Management: Granular control over location access permissions
- Location History: View and delete location search and navigation history
- Precision Settings: Choose between precise and approximate location sharing
- Anonymous Usage: Use location services without personal identification

CONTACT FOR QUESTIONS:
If you have any questions about this Privacy Policy or our data practices, please contact us at info.studio085@gmail.com or visit https://wzsgame.com/privacy.html for additional information.

This Privacy Policy is effective as of August 3, 2025, and will remain in effect except with respect to any changes in its provisions in the future, which will be in effect immediately after being posted on this page.''';
  }
}
