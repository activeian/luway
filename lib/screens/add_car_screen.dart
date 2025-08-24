import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/country_service.dart';
import '../widgets/image_picker_widget.dart';

const Color oliveColor = Color(0xFF808000);

class AddCarScreen extends StatefulWidget {
  final Car? carToEdit;
  
  const AddCarScreen({super.key, this.carToEdit});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  
  // Sale details controllers
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Extended car details controllers
  final _engineController = TextEditingController();
  final _powerController = TextEditingController();
  final _vinController = TextEditingController();
  final _previousOwnersController = TextEditingController();
  final _notesController = TextEditingController();

  CountryInfo? _selectedCountry;
  bool _isForSale = false;
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  bool _isInMarketplace = false;
  bool _isCheckingMarketplace = false;
  
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedColor;
  String? _selectedBodyType;
  String? _selectedDoors;
  String? _selectedCondition;
  String? _selectedUrgency = 'Normal';
  
  // Equipment features
  bool _hasABS = false;
  bool _hasESP = false;
  bool _hasAirbags = false;
  bool _hasAlarm = false;
  bool _hasAirConditioning = false;
  bool _hasHeatedSeats = false;
  bool _hasNavigation = false;
  bool _hasBluetooth = false;
  bool _hasUSB = false;
  bool _hasLeatherSteering = false;
  bool _hasAlloyWheels = false;
  bool _hasSunroof = false;
  bool _hasXenonLights = false;
  bool _hasElectricMirrors = false;
  
  // Status options
  bool _isPriceNegotiable = false;
  bool _hasServiceHistory = false;
  bool _hasAccidentHistory = false;
  bool _isVisibleInMarketplace = true;
  bool _allowContactFromBuyers = true;
  
  List<String> _carImages = [];

  final List<String> _fuelTypes = ['Gasoline', 'Petrol', 'Diesel', 'Electric', 'Hybrid', 'Plugin Hybrid', 'LPG', 'CNG'];
  final List<String> _transmissions = ['Manual', 'Automat', 'Automatic', 'CVT', 'Semi-Automat'];
  final List<String> _colors = ['Black', 'White', 'Silver', 'Gray', 'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Brown', 'Other color'];
  final List<String> _bodyTypes = ['Sedan', 'Hatchback', 'SUV', 'Combi', 'Coupe', 'Cabrio', 'Pick-up', 'Van', 'Monovolum'];
  final List<String> _doorOptions = ['2', '3', '4', '5'];
  final List<String> _conditionOptions = ['New', 'Very good', 'Good', 'Fair', 'For parts'];
  final List<String> _urgencyOptions = ['Normal', 'Urgent', 'Very urgent'];

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
    
    // If editing an existing car, initialize with its data
    if (widget.carToEdit != null) {
      _initializeEditMode();
      _checkMarketplaceStatus();
    }
  }

  void _initializeEditMode() {
    final car = widget.carToEdit!;
    
    // Basic information
    _plateController.text = car.plateNumber;
    _brandController.text = car.brand;
    _modelController.text = car.model;
    _isForSale = car.isForSale;
    
    // Extended information
    if (car.price != null) _priceController.text = car.price!.toString();
    if (car.description != null) _descriptionController.text = car.description!;
    if (car.year != null) _yearController.text = car.year!.toString();
    if (car.mileage != null) _mileageController.text = car.mileage!.toString();
    if (car.location != null) _locationController.text = car.location!;
    if (car.phone != null) _phoneController.text = car.phone!;
    if (car.engine != null) _engineController.text = car.engine!;
    if (car.power != null) _powerController.text = car.power!.toString();
    if (car.vin != null) _vinController.text = car.vin!;
    if (car.previousOwners != null) _previousOwnersController.text = car.previousOwners!.toString();
    if (car.notes != null) _notesController.text = car.notes!;
    
    // Dropdowns
    _selectedFuelType = car.fuelType;
    _selectedTransmission = car.transmission;
    _selectedColor = car.color;
    _selectedBodyType = car.bodyType;
    _selectedDoors = car.doors;
    _selectedCondition = car.condition;
    _selectedUrgency = car.urgencyLevel;
    
    // Boolean values
    _isPriceNegotiable = car.isPriceNegotiable;
    _isVisibleInMarketplace = car.isVisibleInMarketplace;
    _allowContactFromBuyers = car.allowContactFromBuyers;
    _hasServiceHistory = car.hasServiceHistory;
    _hasAccidentHistory = car.hasAccidentHistory;
    
    // Safety equipment
    _hasABS = car.hasABS;
    _hasESP = car.hasESP;
    _hasAirbags = car.hasAirbags;
    _hasAlarm = car.hasAlarm;
    
    // Comfort equipment
    _hasAirConditioning = car.hasAirConditioning;
    _hasHeatedSeats = car.hasHeatedSeats;
    _hasNavigation = car.hasNavigation;
    _hasBluetooth = car.hasBluetooth;
    _hasUSB = car.hasUSB;
    _hasLeatherSteering = car.hasLeatherSteering;
    
    // Exterior equipment
    _hasAlloyWheels = car.hasAlloyWheels;
    _hasSunroof = car.hasSunroof;
    _hasXenonLights = car.hasXenonLights;
    _hasElectricMirrors = car.hasElectricMirrors;
    
    // Images
    _carImages = car.images != null ? List<String>.from(car.images!) : [];
  }

  Future<void> _checkMarketplaceStatus() async {
    if (widget.carToEdit == null) return;
    
    setState(() => _isCheckingMarketplace = true);
    
    try {
      bool isInMarketplace = await CarService.isCarInMarketplace(widget.carToEdit!.id);
      if (mounted) {
        setState(() {
          _isInMarketplace = isInMarketplace;
          _isCheckingMarketplace = false;
        });
      }
    } catch (e) {
      print('Error checking marketplace status: $e');
      if (mounted) {
        setState(() => _isCheckingMarketplace = false);
      }
    }
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
    _locationController.dispose();
    _phoneController.dispose();
    _engineController.dispose();
    _powerController.dispose();
    _vinController.dispose();
    _previousOwnersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    
    try {
      CountryInfo? detected = await CountryService.detectCurrentCountry();
      if (detected != null && mounted) {
        setState(() => _selectedCountry = detected);
      }
    } catch (e) {
      print('Error detecting location: $e');
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => CountryPickerModal(
        onCountrySelected: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
          _plateController.clear(); // Clear plate when country changes
        },
      ),
    );
  }

  void _onPlateChanged(String value) {
    if (_selectedCountry != null) {
      String formatted = CountryService.formatPlateNumber(value, _selectedCountry!.format);
      if (formatted != value) {
        _plateController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  Future<void> _addCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if plate number already exists (only when adding new car)
      if (widget.carToEdit == null) {
        bool exists = await CarService.isPlateNumberExists(
          _plateController.text,
          _selectedCountry!.code,
        );

        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This plate number already exists')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        setState(() => _isLoading = false);
        return;
      }

      Car car = Car(
        id: widget.carToEdit?.id ?? '',
        plateNumber: _plateController.text.toUpperCase(),
        countryCode: _selectedCountry!.code,
        brand: _brandController.text,
        model: _modelController.text,
        isForSale: _isForSale,
        ownerId: user.uid,
        createdAt: widget.carToEdit?.createdAt ?? DateTime.now(),
        
        // Basic car information
        price: _isForSale && _priceController.text.isNotEmpty 
            ? double.tryParse(_priceController.text) 
            : null,
        description: (_isForSale || widget.carToEdit != null) && _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        year: _yearController.text.isNotEmpty 
            ? int.tryParse(_yearController.text) 
            : null,
        mileage: _mileageController.text.isNotEmpty 
            ? int.tryParse(_mileageController.text) 
            : null,
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        color: _selectedColor,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        images: _carImages.isNotEmpty ? _carImages : null,
        
        // Extended car details
        engine: _engineController.text.isNotEmpty ? _engineController.text : null,
        bodyType: _selectedBodyType,
        doors: _selectedDoors,
        condition: _selectedCondition,
        power: _powerController.text.isNotEmpty ? int.tryParse(_powerController.text) : null,
        vin: _vinController.text.isNotEmpty ? _vinController.text : null,
        previousOwners: _previousOwnersController.text.isNotEmpty ? int.tryParse(_previousOwnersController.text) : null,
        hasServiceHistory: _hasServiceHistory,
        hasAccidentHistory: _hasAccidentHistory,
        urgencyLevel: _selectedUrgency,
        isPriceNegotiable: _isPriceNegotiable,
        isVisibleInMarketplace: _isForSale ? _isVisibleInMarketplace : false,
        allowContactFromBuyers: _allowContactFromBuyers,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        
        // Safety equipment
        hasABS: _hasABS,
        hasESP: _hasESP,
        hasAirbags: _hasAirbags,
        hasAlarm: _hasAlarm,
        
        // Comfort equipment
        hasAirConditioning: _hasAirConditioning,
        hasHeatedSeats: _hasHeatedSeats,
        hasNavigation: _hasNavigation,
        hasBluetooth: _hasBluetooth,
        hasUSB: _hasUSB,
        hasLeatherSteering: _hasLeatherSteering,
        
        // Exterior equipment
        hasAlloyWheels: _hasAlloyWheels,
        hasSunroof: _hasSunroof,
        hasXenonLights: _hasXenonLights,
        hasElectricMirrors: _hasElectricMirrors,
      );

      if (widget.carToEdit != null) {
        // Update existing car
        await CarService.updateCar(widget.carToEdit!.id, car);
      } else {
        // Add new car
        await CarService.addCar(car);
      }

      if (mounted) {
        // Stop loading state first
        setState(() => _isLoading = false);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.carToEdit != null ? 'Car updated successfully!' : 'Car added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Wait a bit for the user to see the success message, then navigate back
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.carToEdit != null ? 'update' : 'add'} car: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFeatureChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: Colors.black.withOpacity(0.2),
      checkmarkColor: Colors.black,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: value ? Colors.black : Colors.black87,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.carToEdit != null ? 'Edit Car' : 'Add Car',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading || _isCheckingMarketplace)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _addCar,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Marketplace status message
            if (_isInMarketplace && widget.carToEdit != null) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'This car is currently listed in the marketplace. Any changes will be reflected in your listing.',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Country and Plate Number Row
            Row(
              children: [
                // Country Selector
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    width: 80.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: _isDetectingLocation
                        ? Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedCountry?.flag ?? '🌍',
                                style: TextStyle(fontSize: 20.sp),
                              ),
                              if (_selectedCountry != null)
                                Text(
                                  _selectedCountry!.code,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Plate Number Input
                Expanded(
                  child: TextFormField(
                    controller: _plateController,
                    onChanged: _onPlateChanged,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Plate Number',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: _selectedCountry?.format ?? 'Select country first',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      prefixIcon: Icon(Icons.confirmation_number, color: Colors.grey[600]),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter plate number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Brand
            TextFormField(
              controller: _brandController,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Brand',
                labelStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                prefixIcon: Icon(Icons.directions_car, color: Colors.grey[600]),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter brand';
                }
                return null;
              },
            ),

            SizedBox(height: 16.h),

            // Model
            TextFormField(
              controller: _modelController,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Model',
                labelStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                prefixIcon: Icon(Icons.car_rental, color: Colors.grey[600]),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter model';
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

            // For Sale Toggle
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.sell, color: Colors.grey[600]),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'List for Sale',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isForSale,
                    onChanged: (value) => setState(() => _isForSale = value),
                    activeColor: Colors.black,
                  ),
                ],
              ),
            ),

            // Car Details (shown when editing or when for sale)
            if (_isForSale || widget.carToEdit != null) ...[
              SizedBox(height: 24.h),
              Text(
                widget.carToEdit != null ? 'Car Details' : 'Sale Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),

              // Price (only shown when for sale)
              if (_isForSale) ...[
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Price (USD)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Year and Mileage Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Mileage (km)',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.speed, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Fuel Type
              DropdownButtonFormField<String>(
                value: _selectedFuelType,
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.local_gas_station, color: Colors.grey[600]),
                ),
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.black),
                items: _fuelTypes.map((fuel) => DropdownMenuItem<String>(
                  value: fuel,
                  child: Text(fuel),
                )).toList(),
                onChanged: (value) => setState(() => _selectedFuelType = value),
              ),

              SizedBox(height: 16.h),

              // Transmission
              DropdownButtonFormField<String>(
                value: _selectedTransmission,
                decoration: InputDecoration(
                  labelText: 'Transmission',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.settings, color: Colors.grey[600]),
                ),
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.black),
                items: _transmissions.map((trans) => DropdownMenuItem<String>(
                  value: trans,
                  child: Text(trans),
                )).toList(),
                onChanged: (value) => setState(() => _selectedTransmission = value),
              ),

              SizedBox(height: 16.h),

              // Color
              DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: InputDecoration(
                  labelText: 'Color',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.palette, color: Colors.grey[600]),
                ),
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.black),
                items: _colors.map((color) => DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                )).toList(),
                onChanged: (value) => setState(() => _selectedColor = value),
              ),

              SizedBox(height: 16.h),

              // Location
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 16.h),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 16.h),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 24.h),

              // Technical Specifications
              Text(
                '🔹 Technical Specifications',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),

              // Engine and Power row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _engineController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Engine',
                        hintText: 'Ex: 2.0 TDI',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.build, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _powerController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Power (HP)',
                        hintText: '150',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.speed, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Body Type and Doors row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBodyType,
                      decoration: InputDecoration(
                        labelText: 'Body Type',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.directions_car, color: Colors.grey[600]),
                      ),
                      items: _bodyTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedBodyType = value),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDoors,
                      decoration: InputDecoration(
                        labelText: 'Number of Doors',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.door_front_door, color: Colors.grey[600]),
                      ),
                      items: _doorOptions.map((doors) {
                        return DropdownMenuItem(
                          value: doors,
                          child: Text(doors),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDoors = value),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Condition
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.star, color: Colors.grey[600]),
                ),
                items: _conditionOptions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCondition = value),
              ),

              SizedBox(height: 24.h),

              // Equipment Features
              Text(
                '🔹 Equipment Features',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),

              // Safety Features
              Text(
                'Safety',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildFeatureChip('ABS', _hasABS, (value) => setState(() => _hasABS = value)),
                  _buildFeatureChip('ESP', _hasESP, (value) => setState(() => _hasESP = value)),
                  _buildFeatureChip('Airbags', _hasAirbags, (value) => setState(() => _hasAirbags = value)),
                  _buildFeatureChip('Alarm', _hasAlarm, (value) => setState(() => _hasAlarm = value)),
                ],
              ),

              SizedBox(height: 16.h),

              // Comfort Features
              Text(
                'Comfort',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildFeatureChip('Air Conditioning', _hasAirConditioning, (value) => setState(() => _hasAirConditioning = value)),
                  _buildFeatureChip('Heated Seats', _hasHeatedSeats, (value) => setState(() => _hasHeatedSeats = value)),
                  _buildFeatureChip('Navigation', _hasNavigation, (value) => setState(() => _hasNavigation = value)),
                  _buildFeatureChip('Bluetooth', _hasBluetooth, (value) => setState(() => _hasBluetooth = value)),
                  _buildFeatureChip('USB', _hasUSB, (value) => setState(() => _hasUSB = value)),
                  _buildFeatureChip('Leather Steering', _hasLeatherSteering, (value) => setState(() => _hasLeatherSteering = value)),
                ],
              ),

              SizedBox(height: 16.h),

              // Exterior Features
              Text(
                'Exterior',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildFeatureChip('Alloy Wheels', _hasAlloyWheels, (value) => setState(() => _hasAlloyWheels = value)),
                  _buildFeatureChip('Sunroof', _hasSunroof, (value) => setState(() => _hasSunroof = value)),
                  _buildFeatureChip('Xenon Lights', _hasXenonLights, (value) => setState(() => _hasXenonLights = value)),
                  _buildFeatureChip('Electric Mirrors', _hasElectricMirrors, (value) => setState(() => _hasElectricMirrors = value)),
                ],
              ),

              SizedBox(height: 24.h),

              // Additional Information
              Text(
                '🔹 Additional Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),

              // VIN and Previous Owners row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vinController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'VIN Code (optional)',
                        hintText: 'Ex: WVWZZZ1JZ3W386752',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.assignment, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _previousOwnersController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Previous Owners',
                        hintText: '1',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        prefixIcon: Icon(Icons.people, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Service and Accident History
              Row(
                children: [
                  Checkbox(
                    value: _hasServiceHistory,
                    onChanged: (value) {
                      setState(() {
                        _hasServiceHistory = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Service history available',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Checkbox(
                    value: _hasAccidentHistory,
                    onChanged: (value) {
                      setState(() {
                        _hasAccidentHistory = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Accident history',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Additional observations',
                  hintText: 'Add any relevant information...',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.note, color: Colors.grey[600]),
                ),
              ),

              SizedBox(height: 24.h),

              // Listing Options (only shown when for sale)
              if (_isForSale) ...[
                Text(
                  '🔹 Listing Options',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.h),

              // Price Negotiable
              Row(
                children: [
                  Checkbox(
                    value: _isPriceNegotiable,
                    onChanged: (value) {
                      setState(() {
                        _isPriceNegotiable = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Negotiable price',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),

              // Visible in Marketplace
              Row(
                children: [
                  Checkbox(
                    value: _isVisibleInMarketplace,
                    onChanged: (value) {
                      setState(() {
                        _isVisibleInMarketplace = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Visible in marketplace',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),

              // Allow Contact
              Row(
                children: [
                  Checkbox(
                    value: _allowContactFromBuyers,
                    onChanged: (value) {
                      setState(() {
                        _allowContactFromBuyers = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Allow buyer contact',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Urgency Level
              DropdownButtonFormField<String>(
                value: _selectedUrgency,
                decoration: InputDecoration(
                  labelText: 'Sale urgency',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.priority_high, color: Colors.grey[600]),
                ),
                items: _urgencyOptions.map((urgency) {
                  return DropdownMenuItem(
                    value: urgency,
                    child: Text(urgency),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedUrgency = value),
              ),
              ],
            ],

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// CountryPickerModal widget
class CountryPickerModal extends StatefulWidget {
  final Function(CountryInfo) onCountrySelected;

  const CountryPickerModal({
    super.key,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerModal> createState() => _CountryPickerModalState();
}

class _CountryPickerModalState extends State<CountryPickerModal> {
  List<CountryInfo> _countries = [];
  List<CountryInfo> _filteredCountries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCountries() async {
    try {
      setState(() {
        _countries = CountryService.countries;
        _filteredCountries = CountryService.countries;
      });
    } catch (e) {
      print('Error loading countries: $e');
    }
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries.where((country) {
          return country.name.toLowerCase().contains(query.toLowerCase()) ||
                 country.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Title
          Text(
            'Select Country',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Search field
          TextField(
            controller: _searchController,
            onChanged: _filterCountries,
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: Text(
                    country.flag,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '${country.code} • ${country.format}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                  ),
                  onTap: () => widget.onCountrySelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
