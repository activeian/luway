import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:country_picker/country_picker.dart';
import 'widgets/beautiful_message_widget.dart';
import 'app_constants.dart';
import 'screens/add_car_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildAddCarTab(), // Direct integration of AddCarScreen
    );
  }

  Widget _buildAddCarTab() {
    return const AddCarScreen();
  }

  // Accessories and services are now only available through marketplace with Pro subscription
  // This keeps the Add screen focused on car additions only
}

// Add Car Form (kept for backward compatibility - actual functionality is in AddCarScreen)
class AddCarForm extends StatefulWidget {
  const AddCarForm({super.key});

  @override
  State<AddCarForm> createState() => _AddCarFormState();
}

class _AddCarFormState extends State<AddCarForm> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  Country? _selectedCountry;
  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  Future<void> _submitCar() async {
    if (!_formKey.currentState!.validate() || _selectedCountry == null) {
      BeautifulMessage.showWarning(
          context, 'Please fill all fields and select country');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement car submission logic
      // Check if plate exists, validate ownership, etc.

      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        BeautifulMessage.showSuccess(context, 'Car added successfully!');

        // Clear form
        _plateController.clear();
        _makeController.clear();
        _modelController.clear();
        _yearController.clear();
        setState(() {
          _selectedCountry = null;
        });
      }
    } catch (e) {
      if (mounted) {
        BeautifulMessage.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Country Selection
            InkWell(
              onTap: _selectCountry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCountry == null
                            ? 'Select Country'
                            : '${_selectedCountry!.flagEmoji} ${_selectedCountry!.name}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _selectedCountry == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // License Plate
            TextFormField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: 'License Plate Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.confirmation_number),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter license plate number';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Make
            TextFormField(
              controller: _makeController,
              decoration: InputDecoration(
                labelText: 'Make (e.g., BMW)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.directions_car),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter car make';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Model
            TextFormField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Model (e.g., X5)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.model_training),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter car model';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Year
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter year';
                }
                final year = int.tryParse(value);
                if (year == null ||
                    year < 1900 ||
                    year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),

            SizedBox(height: 32.h),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCar,
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
                      'Add Car',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
            ),

            SizedBox(height: 16.h),

            // Info Text
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Note: If this license plate is already registered, you can send a transfer request to the current owner.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder forms for accessories and services
class AddAccessoryForm extends StatelessWidget {
  const AddAccessoryForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Add Accessory Form\n(Coming Soon)',
        style: TextStyle(fontSize: 16.sp),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AddServiceForm extends StatelessWidget {
  const AddServiceForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Add Service Form\n(Coming Soon)',
        style: TextStyle(fontSize: 16.sp),
        textAlign: TextAlign.center,
      ),
    );
  }
}
