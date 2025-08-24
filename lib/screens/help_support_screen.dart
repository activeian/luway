import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isSubmittingTicket = false;
  
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I post a car for sale?',
      'answer': 'To post a car for sale, go to the Marketplace tab and tap the "+" button. Fill in all the required information about your vehicle, add photos, and set your price. Your listing will be reviewed and published within 24 hours.',
      'category': 'Selling'
    },
    {
      'question': 'How do I contact a seller?',
      'answer': 'On any listing page, you can tap the "Message Seller" button to start a conversation. You can also call the seller directly if they have provided a phone number.',
      'category': 'Buying'
    },
    {
      'question': 'Is my personal information safe?',
      'answer': 'Yes, we take privacy seriously. Your personal information is encrypted and never shared with third parties without your consent. You control what information is visible on your profile.',
      'category': 'Privacy'
    },
    {
      'question': 'How do I manage my garage?',
      'answer': 'Go to Profile > My Garage to add, edit, or remove vehicles from your personal collection. You can track maintenance, insurance, and other important information for each vehicle.',
      'category': 'Garage'
    },
    {
      'question': 'What are boosts and how do they work?',
      'answer': 'Boosts are premium features that help your listings stand out. They include colored frames, animated borders, top positioning, and special labels. You can purchase boosts through your subscription or individually.',
      'category': 'Premium'
    },
    {
      'question': 'How do I cancel my subscription?',
      'answer': 'You can cancel your subscription anytime by going to Profile > Subscription and tapping "Cancel Subscription". Your premium features will remain active until the end of your billing period.',
      'category': 'Subscription'
    },
    {
      'question': 'Why was my listing rejected?',
      'answer': 'Listings may be rejected for various reasons: incomplete information, poor quality photos, prohibited items, or violation of our community guidelines. You will receive a notification with the specific reason.',
      'category': 'Moderation'
    },
    {
      'question': 'How do I report a suspicious listing?',
      'answer': 'On any listing page, tap the three dots menu and select "Report". Choose the appropriate reason and provide additional details. Our team will review the report within 24 hours.',
      'category': 'Safety'
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7A1E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF6B7A1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Section
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B7A1E), Color(0xFF8B9A3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Suggestions',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Find answers to common questions',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // FAQ Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildFAQList(),
                ],
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList() {
    return Column(
      children: _faqItems.map((faq) => _buildFAQItem(faq)).toList(),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Container(
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
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Container(
          margin: EdgeInsets.only(top: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Color(0xFF6B7A1E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            faq['category'],
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7A1E),
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'Brief description of your issue',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Color(0xFF6B7A1E)),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'Describe your issue in detail...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Color(0xFF6B7A1E)),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingTicket ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B7A1E),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSubmittingTicket
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Ticket',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Live Chat'),
        content: Text('Live chat feature will be available soon. For immediate assistance, please call us or submit a support ticket.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall() async {
    const phoneNumber = 'tel:+1-800-LUWAY-HELP';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      _showErrorDialog('Could not make phone call. Please dial +1-800-LUWAY-HELP manually.');
    }
  }

  void _submitTicket() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in both subject and message fields.');
      return;
    }

    setState(() {
      _isSubmittingTicket = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ticket Submitted'),
          content: Text('Your support ticket has been submitted successfully. We\'ll get back to you within 24 hours.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _subjectController.clear();
                _messageController.clear();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to submit ticket. Please try again.');
    } finally {
      setState(() {
        _isSubmittingTicket = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
