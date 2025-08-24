import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'app_constants.dart';

// App Color Scheme Constants
const Color primaryOlive = Color(0xFFB3B760);
const Color darkGreen = Color(0xFF064232);
const Color primaryBlack = Color(0xFF000000);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  _initializeApp() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    // Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(AppConstants.onboardingCompleted) ?? false;

    if (mounted) {
      if (!onboardingCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        _checkLoginStatus();
      }
    }
  }

  _checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with enhanced styling
              Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOlive.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // App Name with styled text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Lu',
                      style: TextStyle(
                        fontSize: 32.sp,
                        color: primaryBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'Way',
                      style: TextStyle(
                        fontSize: 32.sp,
                        color: primaryOlive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'Global Car Search & Marketplace',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 50.h),

              // Enhanced loading indicator
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: primaryOlive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: CircularProgressIndicator(
                  color: primaryOlive,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
