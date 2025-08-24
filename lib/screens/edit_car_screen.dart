import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/country_service.dart';
import '../widgets/image_picker_widget.dart';

const Color oliveColor = Color(0xFF808000);

class EditCarScreen extends StatefulWidget {
  final Car car;

  const EditCarScreen({super.key, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  CountryInfo? _selectedCountry;
  bool _isForSale = false;
  String? _selectedFuelType;
  String? _selectedTransmission;
  bool _isLoading = false;
  List<String> _carImages = [];

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'Plugin Hybrid',
    'LPG',
    'CNG',
    'Other'
  ];

  final List<String> _transmissionTypes = [
    'Manual',
    'Automatic',
    'Semi-automatic',
    'CVT'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Initialize controllers with existing car data
    _plateController.text = widget.car.plateNumber;
    _brandController.text = widget.car.brand;
    _modelController.text = widget.car.model;
    _isForSale = widget.car.isForSale;
    
    // Initialize sale details if available
    if (widget.car.price != null) {
      _priceController.text = widget.car.price!.toString();
    }
    if (widget.car.description != null) {
      _descriptionController.text = widget.car.description!;
    }
    if (widget.car.year != null) {
      _yearController.text = widget.car.year!.toString();
    }
    if (widget.car.mileage != null) {
      _mileageController.text = widget.car.mileage!.toString();
    }
    if (widget.car.color != null) {
      _colorController.text = widget.car.color!;
    }
    if (widget.car.location != null) {
      _locationController.text = widget.car.location!;
    }
    if (widget.car.phone != null) {
      _phoneController.text = widget.car.phone!;
    }
    
    _selectedFuelType = widget.car.fuelType;
    _selectedTransmission = widget.car.transmission;
    
    // Initialize images
    _carImages = widget.car.images != null ? List<String>.from(widget.car.images!) : [];
    
    // Get country info
    _selectedCountry = CountryService.getCountryByCode(widget.car.countryCode);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _formatPlateNumber() {
    if (_selectedCountry != null) {
      final formatted = CountryService.formatPlateNumber(
        _plateController.text,
        _selectedCountry!.format,
      );
      if (formatted != _plateController.text) {
        _plateController.text = formatted;
        _plateController.selection = TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        );
      }
    }
  }

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create updated car object
      final updatedCar = Car(
        id: widget.car.id,
        plateNumber: _plateController.text.trim().toUpperCase(),
        countryCode: _selectedCountry!.code,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        isForSale: _isForSale,
        ownerId: user.uid,
        createdAt: widget.car.createdAt, // Keep original creation date
        // Sale details
        price: _isForSale && _priceController.text.isNotEmpty 
            ? double.tryParse(_priceController.text)
            : null,
        description: _isForSale && _descriptionController.text.isNotEmpty 
            ? _descriptionController.text.trim()
            : null,
        year: _isForSale && _yearController.text.isNotEmpty 
            ? int.tryParse(_yearController.text)
            : null,
        mileage: _isForSale && _mileageController.text.isNotEmpty 
            ? int.tryParse(_mileageController.text)
            : null,
        fuelType: _isForSale ? _selectedFuelType : null,
        transmission: _isForSale ? _selectedTransmission : null,
        color: _isForSale && _colorController.text.isNotEmpty 
            ? _colorController.text.trim()
            : null,
        location: _isForSale && _locationController.text.isNotEmpty 
            ? _locationController.text.trim()
            : null,
        phone: _isForSale && _phoneController.text.isNotEmpty 
            ? _phoneController.text.trim()
            : null,
        images: _carImages.isNotEmpty ? _carImages : null,
        
        // Preserve all other fields from original car
        bodyType: widget.car.bodyType,
        doors: widget.car.doors,
        condition: widget.car.condition,
        power: widget.car.power,
        vin: widget.car.vin,
        previousOwners: widget.car.previousOwners,
        hasServiceHistory: widget.car.hasServiceHistory,
        hasAccidentHistory: widget.car.hasAccidentHistory,
        urgencyLevel: widget.car.urgencyLevel,
        isPriceNegotiable: widget.car.isPriceNegotiable,
        isVisibleInMarketplace: _isForSale ? widget.car.isVisibleInMarketplace : false, // Key fix here!
        allowContactFromBuyers: widget.car.allowContactFromBuyers,
        notes: widget.car.notes,
        engine: widget.car.engine,
        
        // Safety equipment
        hasABS: widget.car.hasABS,
        hasESP: widget.car.hasESP,
        hasAirbags: widget.car.hasAirbags,
        hasAlarm: widget.car.hasAlarm,
        
        // Comfort equipment
        hasAirConditioning: widget.car.hasAirConditioning,
        hasHeatedSeats: widget.car.hasHeatedSeats,
        hasNavigation: widget.car.hasNavigation,
        hasBluetooth: widget.car.hasBluetooth,
        hasUSB: widget.car.hasUSB,
        hasLeatherSteering: widget.car.hasLeatherSteering,
        
        // Exterior equipment
        hasAlloyWheels: widget.car.hasAlloyWheels,
        hasSunroof: widget.car.hasSunroof,
        hasXenonLights: widget.car.hasXenonLights,
        hasElectricMirrors: widget.car.hasElectricMirrors,
      );

      await CarService.updateCar(widget.car.id, updatedCar);

      print('🚗 Car updated successfully in garage');
      print('📸 Updated car images: ${updatedCar.images?.length ?? 0} images');
      print('💰 Updated price: ${updatedCar.price}');
      print('📋 Updated description: ${updatedCar.description?.substring(0, 50) ?? 'No description'}...');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car updated successfully! Marketplace listing also updated.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating car: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Car',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateCar,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: _isLoading ? Colors.grey : oliveColor,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Selection
                    Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CountryInfo>(
                          isExpanded: true,
                          value: _selectedCountry,
                          hint: const Text('Select Country'),
                          onChanged: (country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                          items: CountryService.countries
                              .map((country) => DropdownMenuItem(
                                    value: country,
                                    child: Row(
                                      children: [
                                        Text(
                                          country.flag,
                                          style: TextStyle(fontSize: 18.sp),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            country.name,
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // License Plate
                    Text(
                      'License Plate',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) => _formatPlateNumber(),
                      decoration: InputDecoration(
                        hintText: _selectedCountry?.format ?? 'Enter license plate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: oliveColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter license plate';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Brand
                    Text(
                      'Brand',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _brandController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter car brand',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: oliveColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter car brand';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Model
                    Text(
                      'Model',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _modelController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter car model',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: oliveColor),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter car model';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Car Images
                    ImagePickerWidget(
                      initialImages: _carImages,
                      onImagesChanged: (images) {
                        setState(() {
                          _carImages = images;
                        });
                      },
                      maxImages: 10,
                      title: 'Car Images',
                    ),

                    SizedBox(height: 24.h),

                    // Sale Toggle
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'For Sale',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Enable this to list your car for sale',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isForSale,
                            onChanged: (value) {
                              setState(() {
                                _isForSale = value;
                              });
                            },
                            activeColor: oliveColor,
                          ),
                        ],
                      ),
                    ),

                    // Sale Details Section
                    if (_isForSale) ...[
                      SizedBox(height: 24.h),
                      Text(
                        'Sale Details',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Price
                      Text(
                        'Price (€)',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter price in euros',
                          prefixText: '€ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(color: oliveColor),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Year and Mileage Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Year',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _yearController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 2020',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(color: oliveColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mileage (km)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextFormField(
                                  controller: _mileageController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 50000',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: const BorderSide(color: oliveColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Fuel Type and Transmission Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fuel Type',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedFuelType,
                                      hint: const Text('Select'),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedFuelType = value;
                                        });
                                      },
                                      items: _fuelTypes.map((fuel) => 
                                        DropdownMenuItem(
                                          value: fuel,
                                          child: Text(fuel),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transmission',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedTransmission,
                                      hint: const Text('Select'),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTransmission = value;
                                        });
                                      },
                                      items: _transmissionTypes.map((trans) => 
                                        DropdownMenuItem(
                                          value: trans,
                                          child: Text(trans),
                                        ),
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Color
                      Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _colorController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Black, White, Red',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(color: oliveColor),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Location
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _locationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'City, State/Region',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(color: oliveColor),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Phone
                      Text(
                        'Contact Phone',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone number for buyers',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(color: oliveColor),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Describe your car, its condition, features, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(color: oliveColor),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 32.h),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateCar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Update Car',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
    );
  }
}
