import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = user.email ?? '';
          _countryController.text = data['country'] ?? '';
          _cityController.text = data['city'] ?? '';
          _addressController.text = data['address'] ?? '';
          _profileImageUrl = data['photoURL'];
          _isLoading = false;
        });
      } else {
        // If no document exists, create one with current user data
        await _createUserDocument(user);
        setState(() {
          _emailController.text = user.email ?? '';
          _nicknameController.text = user.displayName ?? '';
          _profileImageUrl = user.photoURL;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserDocument(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'firstName': '',
      'lastName': '',
      'nickname': user.displayName ?? '',
      'phone': '',
      'country': '',
      'city': '',
      'address': '',
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile if nickname changed
      if (_nicknameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nicknameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF6B7A1E),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate changes were made
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7A1E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF6B7A1E),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B7A1E),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF6B7A1E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6B7A1E)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 50.sp,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF6B7A1E),
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Personal Information
                    _buildSectionHeader('Personal Information'),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _nicknameController,
                      label: 'Nickname/Display Name',
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nickname is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Contact Information
                    _buildSectionHeader('Contact Information'),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(value.trim())) {
                            return 'Please enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      enabled: false, // Email cannot be changed
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 32.h),

                    // Location Information
                    _buildSectionHeader('Location'),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _countryController,
                            label: 'Country',
                            icon: Icons.public_outlined,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                    ),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF6B7A1E).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7A1E),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF6B7A1E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Color(0xFF6B7A1E), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
      ),
    );
  }
}
