import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;
import 'home_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'widgets/beautiful_message_widget.dart';
import 'app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptPrivacyPolicy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptPrivacyPolicy) {
      _showError('You must accept the Privacy Policy to create an account');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print(
          'Attempting to register user with email: ${_emailController.text.trim()}');

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('User registered successfully: ${userCredential.user?.email}');

      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      print('Display name updated: ${_nameController.text.trim()}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Error during registration: ${e.code} - ${e.message}');
      String message = 'Registration failed';

      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }
      _showError(message);
    } catch (e) {
      print('General error during registration: $e');
      _showError('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      print('Starting Google Sign-In for registration...');

      // Use default GoogleSignIn configuration from google-services.json
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        setState(() => _isLoading = false);
        return;
      }

      print('Google user signed in: ${googleUser.email}');
      print('Google user display name: ${googleUser.displayName}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Failed to get Google auth tokens');
        _showError('Google authentication failed');
        setState(() => _isLoading = false);
        return;
      }

      print('Google auth tokens obtained successfully');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      print(
          'Firebase Google registration successful: ${userCredential.user?.email}');
      print('User display name: ${userCredential.user?.displayName}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Error during Google registration: ${e.code} - ${e.message}');
      _showError('Google registration failed: ${e.message}');
    } catch (e) {
      print('General error during Google registration: $e');
      _showError('Google registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      print('Starting Apple Sign-In for registration...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('Apple credential received');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      print(
          'Firebase Apple registration successful: ${userCredential.user?.email}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign-In Authorization Error: ${e.code} - ${e.message}');
      if (e.code != AuthorizationErrorCode.canceled) {
        _showError('Apple registration failed: ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Error during Apple registration: ${e.code} - ${e.message}');
      _showError('Apple registration failed: ${e.message}');
    } catch (e) {
      print('General error during Apple registration: $e');
      _showError('Apple registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    BeautifulMessage.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),

                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 169, 171, 173),
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
                      SizedBox(height: 16.h),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Join the LuWay community',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16.h),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20.h),

                // Privacy Policy Checkbox
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptPrivacyPolicy,
                        onChanged: (value) {
                          setState(() {
                            _acceptPrivacyPolicy = value ?? false;
                          });
                        },
                        activeColor: AppConstants.primaryOlive,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptPrivacyPolicy = !_acceptPrivacyPolicy;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[700],
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'I have read and accept the '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppConstants.primaryOlive,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PrivacyPolicyScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                  const TextSpan(
                                      text:
                                          '. This includes detailed information about location data usage, payment processing, and data sharing practices.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryOlive,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Create Account',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w600),
                        ),
                ),

                SizedBox(height: 16.h),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                SizedBox(height: 16.h),

                // Apple Sign Up Button (iOS only) - FIRST for Apple guidelines
                if (Platform.isIOS) ...[
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithApple,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      backgroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Google Sign Up Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google_logo.png',
                        height: 20.h,
                        width: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppConstants.primaryOlive,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Terms and Conditions
                Center(
                  child: Text(
                    'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
