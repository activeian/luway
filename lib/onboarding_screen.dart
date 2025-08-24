import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleted, true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Find Any Vehicle',
      description:
          'Search for any car by license plate number. Contact owners instantly when you need to.',
      imagePath: 'assets/images/onboarding_1.png',
      icon: Icons.search,
    ),
    OnboardingPage(
      title: 'Global Marketplace',
      description:
          'Buy and sell cars, accessories, and services. Connect with automotive enthusiasts worldwide.',
      imagePath: 'assets/images/onboarding_2.png',
      icon: Icons.store,
    ),
    OnboardingPage(
      title: 'Instant Communication',
      description:
          'Chat directly with car owners. Resolve parking issues, accidents, or simply connect.',
      imagePath: 'assets/images/onboarding_3.png',
      icon: Icons.chat,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(_pages[index]);
              },
            ),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo at top
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 158, 159, 160),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 120.h,
                width: 120.w,
                fit: BoxFit.contain,
              ),
            ),
          ),

          SizedBox(height: 60.h),

          // Main illustration
          Container(
            width: 200.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              page.icon,
              size: 100.sp,
              color: Colors.blue,
            ),
          ),

          SizedBox(height: 40.h),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildIndicator(index == _currentPage),
            ),
          ),

          SizedBox(height: 32.h),

          // Buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                const Expanded(flex: 1, child: SizedBox()),
              SizedBox(width: 16.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryOlive,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: isActive ? 24.w : 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}
