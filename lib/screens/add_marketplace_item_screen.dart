import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_item.dart';
import '../models/car.dart';
import '../services/marketplace_service.dart';
import '../services/map_launcher_service.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/beautiful_message_widget.dart';

const Color oliveColor = Color(0xFFB3B760);

class AddMarketplaceItemScreen extends StatefulWidget {
  final MarketplaceItemType type;
  final Car? selectedCar;

  const AddMarketplaceItemScreen({
    super.key,
    required this.type,
    this.selectedCar,
  });

  @override
  State<AddMarketplaceItemScreen> createState() =>
      _AddMarketplaceItemScreenState();
}

class _AddMarketplaceItemScreenState extends State<AddMarketplaceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  // Car specific controllers
  final _plateNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _enginePowerController = TextEditingController();
  final _engineCapacityController = TextEditingController();
  final _vinController = TextEditingController();
  final _previousOwnersController = TextEditingController();
  final _itpDateController = TextEditingController();
  final _rcaDateController = TextEditingController();
  final _wheelSizeController = TextEditingController();
  final _engineController = TextEditingController();
  final _powerController = TextEditingController();
  final _notesController = TextEditingController();

  ServiceCategory? _selectedServiceCategory;
  AccessoryCategory? _selectedAccessoryCategory;
  String _selectedCurrency = 'USD';
  List<String> _itemImages = [];
  bool _isLoading = false;
  bool _hasSubscription = false;

  // Car specific variables
  String? _selectedBodyType;
  String? _selectedTransmission;
  String? _selectedFuelType;
  String? _selectedCountry;
  String? _selectedColor;
  String? _selectedDoors;
  String? _selectedCondition;
  String? _selectedUrgency = 'Normal';

  bool _hasNavigation = false;
  bool _hasHeatedSeats = false;
  bool _hasAlarm = false;
  bool _isForSale = true;
  bool _isPriceNegotiable = false;
  bool _hasServiceHistory = false;
  bool _hasAccidentHistory = false;
  bool _isVisibleInMarketplace = true;
  bool _allowContactFromBuyers = true;
  bool _hasABS = false;
  bool _hasESP = false;
  bool _hasAirbags = false;
  bool _hasAirConditioning = false;
  bool _hasBluetooth = false;
  bool _hasUSB = false;
  bool _hasLeatherSteering = false;
  bool _hasAlloyWheels = false;
  bool _hasSunroof = false;
  bool _hasXenonLights = false;
  bool _hasElectricMirrors = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
    _initializeCarData();
  }

  void _initializeCarData() {
    if (widget.selectedCar != null) {
      final car = widget.selectedCar!;

      // Build title with available information
      String title = '${car.brand} ${car.model}';
      if (car.year != null) {
        title += ' (${car.year})';
      }
      _titleController.text = title;

      // Build description with car details
      String description = 'Car for sale in excellent condition.\n\n';
      if (car.year != null) description += 'Year: ${car.year}\n';
      if (car.mileage != null) description += 'Mileage: ${car.mileage} km\n';
      if (car.fuelType != null) description += 'Fuel Type: ${car.fuelType}\n';
      if (car.transmission != null)
        description += 'Transmission: ${car.transmission}\n';
      if (car.color != null) description += 'Color: ${car.color}\n';
      if (car.engine != null) description += 'Engine: ${car.engine}\n';
      description += 'License Plate: ${car.plateNumber}\n';
      _descriptionController.text = description;

      // Set location if available
      if (car.location != null && car.location!.isNotEmpty) {
        _locationController.text = car.location!;
      } else {
        _locationController.text = car.countryCode;
      }

      // Set phone if available
      if (car.phone != null && car.phone!.isNotEmpty) {
        _phoneController.text = car.phone!;
      }

      // Pre-populate images if available
      if (car.images != null && car.images!.isNotEmpty) {
        setState(() {
          _itemImages = List.from(car.images!);
        });
      }

      // If car already has a price, pre-populate it
      if (car.price != null) {
        _priceController.text = car.price!.toString();
      }
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _hasSubscription = false;
      });
      return;
    }

    // Allow all users to publish any type of item
    setState(() {
      _hasSubscription = true; // Always true to allow publishing
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _tagsController.dispose();

    // Car specific controllers
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _enginePowerController.dispose();
    _engineCapacityController.dispose();
    _vinController.dispose();
    _previousOwnersController.dispose();
    _itpDateController.dispose();
    _rcaDateController.dispose();
    _wheelSizeController.dispose();
    _engineController.dispose();
    _powerController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Add ${_getTypeTitle()}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.type != MarketplaceItemType.car)
                      _buildSubscriptionCheck(),
                    if (widget.type == MarketplaceItemType.car) ...[
                      _buildCarBasicInfo(),
                      SizedBox(height: 16.h),
                      _buildCarTechnicalSpecs(),
                      SizedBox(height: 16.h),
                      _buildCarEquipmentOptions(),
                      SizedBox(height: 16.h),
                      _buildCarAdditionalInfo(),
                      SizedBox(height: 16.h),
                      _buildImageSection(),
                      SizedBox(height: 16.h),
                      _buildContactInfo(),
                      SizedBox(height: 16.h),
                      _buildCarStatusOptions(),
                    ] else ...[
                      _buildBasicInfo(),
                      SizedBox(height: 16.h),
                      _buildCategorySelection(),
                      SizedBox(height: 16.h),
                      _buildImageSection(),
                      SizedBox(height: 16.h),
                      _buildContactInfo(),
                      SizedBox(height: 16.h),
                      _buildAdditionalInfo(),
                    ],
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCheck() {
    if (widget.type == MarketplaceItemType.car) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _hasSubscription ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              _hasSubscription ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasSubscription ? Icons.check_circle : Icons.warning,
            color: _hasSubscription ? Colors.green : Colors.orange,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'You can add ${_getTypeTitle().toLowerCase()}s - No subscription required!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'Enter item title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your item...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // Price and Currency
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: ['Lei', 'EUR', 'USD'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    if (widget.type == MarketplaceItemType.car) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        if (widget.type == MarketplaceItemType.service)
          DropdownButtonFormField<ServiceCategory>(
            value: _selectedServiceCategory,
            decoration: InputDecoration(
              labelText: 'Service Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: oliveColor, width: 2),
              ),
            ),
            items: ServiceCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child:
                    Text(MarketplaceService.getServiceCategoryName(category)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedServiceCategory = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a service category';
              }
              return null;
            },
          ),
        if (widget.type == MarketplaceItemType.accessory)
          DropdownButtonFormField<AccessoryCategory>(
            value: _selectedAccessoryCategory,
            decoration: InputDecoration(
              labelText: 'Accessory Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: oliveColor, width: 2),
              ),
            ),
            items: AccessoryCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child:
                    Text(MarketplaceService.getAccessoryCategoryName(category)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAccessoryCategory = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an accessory category';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return ImagePickerWidget(
      initialImages: _itemImages,
      onImagesChanged: (images) {
        setState(() {
          _itemImages = images;
        });
      },
      maxImages: 10,
      title: 'Photos',
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            hintText: '+40 XXX XXX XXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Location with Google Maps integration for services
        if (widget.type == MarketplaceItemType.service) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location *',
                    hintText: 'Enter full address for service location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: oliveColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter service location';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: oliveColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: () => MapLauncherService.openMapWithLocation(
                    _locationController.text.trim(),
                    context: context,
                  ),
                  icon: Icon(
                    Icons.directions,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  tooltip: 'Open in ${MapLauncherService.mapAppName}',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Tip: Add a complete address so customers can find your service location easily',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else ...[
          // Standard location field for non-services
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'City, Country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: oliveColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Tags
        TextFormField(
          controller: _tagsController,
          decoration: InputDecoration(
            labelText: 'Tags (Optional)',
            hintText: 'sport, luxury, new (comma separated)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isLoading ||
                  (!_hasSubscription && widget.type != MarketplaceItemType.car))
              ? null
              : _submitItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: oliveColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Add ${_getTypeTitle()}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case MarketplaceItemType.car:
        return 'Car';
      case MarketplaceItemType.accessory:
        return 'Accessory';
      case MarketplaceItemType.service:
        return 'Service';
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BeautifulMessage.showError(context, 'Please log in to add items');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tags
      List<String> tags = [];
      if (_tagsController.text.trim().isNotEmpty) {
        tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      }

      // Create marketplace item based on type
      if (widget.type == MarketplaceItemType.car) {
        if (widget.selectedCar != null) {
          // Listing existing car from garage
          await MarketplaceService.listCarFromGarage(
            carId: widget.selectedCar!.id,
            price: double.parse(_priceController.text),
            currency: _selectedCurrency,
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            additionalImages: _itemImages,
          );
        } else {
          // Creating new car marketplace item with all form data
          await MarketplaceService.addCarDirectToMarketplace(
            // Basic info
            country: _selectedCountry ?? 'RO',
            plateNumber: _plateNumberController.text.trim(),
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            year: _yearController.text.isNotEmpty
                ? int.tryParse(_yearController.text)
                : null,
            mileage: _mileageController.text.isNotEmpty
                ? int.tryParse(_mileageController.text)
                : null,
            price: double.parse(_priceController.text),
            currency: _selectedCurrency,

            // Technical specs
            engine: _engineController.text.trim().isNotEmpty
                ? _engineController.text.trim()
                : null,
            power: _powerController.text.isNotEmpty
                ? int.tryParse(_powerController.text)
                : null,
            fuelType: _selectedFuelType,
            transmission: _selectedTransmission,
            bodyType: _selectedBodyType,
            color: _selectedColor,
            doors: _selectedDoors,
            condition: _selectedCondition,

            // Additional info
            vin: _vinController.text.trim().isNotEmpty
                ? _vinController.text.trim()
                : null,
            previousOwners: _previousOwnersController.text.isNotEmpty
                ? int.tryParse(_previousOwnersController.text)
                : null,
            hasServiceHistory: _hasServiceHistory,
            hasAccidentHistory: _hasAccidentHistory,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,

            // Status options
            isForSale: _isForSale,
            urgencyLevel: _selectedUrgency ?? 'Normal',
            isPriceNegotiable: _isPriceNegotiable,
            isVisibleInMarketplace: _isVisibleInMarketplace,
            allowContactFromBuyers: _allowContactFromBuyers,

            // Equipment features
            hasABS: _hasABS,
            hasESP: _hasESP,
            hasAirbags: _hasAirbags,
            hasAlarm: _hasAlarm,
            hasAirConditioning: _hasAirConditioning,
            hasHeatedSeats: _hasHeatedSeats,
            hasNavigation: _hasNavigation,
            hasBluetooth: _hasBluetooth,
            hasUSB: _hasUSB,
            hasLeatherSteering: _hasLeatherSteering,
            hasAlloyWheels: _hasAlloyWheels,
            hasSunroof: _hasSunroof,
            hasXenonLights: _hasXenonLights,
            hasElectricMirrors: _hasElectricMirrors,

            // Media and contact
            images: _itemImages,
            location: _locationController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );
        }
      } else {
        // For accessories and services
        if (widget.type == MarketplaceItemType.accessory) {
          await MarketplaceService.addAccessory(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.parse(_priceController.text),
            currency: _selectedCurrency,
            category: _selectedAccessoryCategory!,
            images: _itemImages,
            location: _locationController.text.trim(),
            tags: tags,
          );
        } else if (widget.type == MarketplaceItemType.service) {
          await MarketplaceService.addService(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.parse(_priceController.text),
            currency: _selectedCurrency,
            category: _selectedServiceCategory!,
            images: _itemImages,
            location: _locationController.text.trim(),
            tags: tags,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        BeautifulMessage.showSuccess(
            context, '${_getTypeTitle()} added successfully!');
      }
    } catch (e) {
      if (mounted) {
        BeautifulMessage.showError(
            context, 'Error adding ${_getTypeTitle().toLowerCase()}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCarBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔹 Date de bază',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Country selection
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: 'Țară *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          items: ['RO', 'MD', 'BG', 'HU', 'DE', 'FR', 'IT', 'Other']
              .map((country) {
            return DropdownMenuItem(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCountry = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selectați țara';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // License plate
        TextFormField(
          controller: _plateNumberController,
          decoration: InputDecoration(
            labelText: 'Număr de înmatriculare *',
            hintText: 'Ex: B-123-ABC',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Introduceți numărul de înmatriculare';
            }
            return null;
          },
        ),

        SizedBox(height: 16.h),

        // Brand and Model row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Marca *',
                  hintText: 'Ex: BMW',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți marca';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model *',
                  hintText: 'Ex: X5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduceți modelul';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Year and Mileage row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'An fabricație',
                  hintText: '2020',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kilometraj (km)',
                  hintText: '50000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Price and Currency
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Preț *',
                  hintText: '15000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (_isForSale && (value == null || value.trim().isEmpty)) {
                    return 'Introduceți prețul';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Introduceți un preț valid';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Valută',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: ['Lei', 'EUR', 'USD'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarTechnicalSpecs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔹 Date tehnice',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Engine and Power row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _engineController,
                decoration: InputDecoration(
                  labelText: 'Motorizare',
                  hintText: 'Ex: 2.0 TDI',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextFormField(
                controller: _powerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Putere (CP)',
                  hintText: '150',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Fuel Type and Transmission
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFuelType,
                decoration: InputDecoration(
                  labelText: 'Combustibil',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: ['Benzină', 'Diesel', 'Hibrid', 'Electric', 'GPL', 'CNG']
                    .map((fuel) {
                  return DropdownMenuItem(
                    value: fuel,
                    child: Text(fuel),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value;
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTransmission,
                decoration: InputDecoration(
                  labelText: 'Transmisie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items:
                    ['Manuală', 'Automată', 'Semiautomată', 'CVT'].map((trans) {
                  return DropdownMenuItem(
                    value: trans,
                    child: Text(trans),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTransmission = value;
                  });
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Body Type and Color
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedBodyType,
                decoration: InputDecoration(
                  labelText: 'Caroserie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: [
                  'Sedan',
                  'Hatchback',
                  'SUV',
                  'Combi',
                  'Coupe',
                  'Cabriolet',
                  'Monovolum',
                  'Pick-up'
                ].map((body) {
                  return DropdownMenuItem(
                    value: body,
                    child: Text(body),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBodyType = value;
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: InputDecoration(
                  labelText: 'Culoare',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: [
                  'Alb',
                  'Negru',
                  'Gri',
                  'Argintiu',
                  'Albastru',
                  'Roșu',
                  'Verde',
                  'Galben',
                  'Maro',
                  'Altă culoare'
                ].map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedColor = value;
                  });
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Doors and Condition
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDoors,
                decoration: InputDecoration(
                  labelText: 'Număr uși',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: ['2/3', '4/5', 'Altele'].map((doors) {
                  return DropdownMenuItem(
                    value: doors,
                    child: Text(doors),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDoors = value;
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Stare tehnică',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: [
                  'Nouă',
                  'Foarte bună',
                  'Bună',
                  'Acceptabilă',
                  'Pentru piese'
                ].map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarEquipmentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔹 Dotări & Opțiuni',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // Safety Features
        Text(
          'Siguranță',
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
            _buildFeatureChip(
                'ABS', _hasABS, (value) => setState(() => _hasABS = value)),
            _buildFeatureChip(
                'ESP', _hasESP, (value) => setState(() => _hasESP = value)),
            _buildFeatureChip('Airbag-uri', _hasAirbags,
                (value) => setState(() => _hasAirbags = value)),
            _buildFeatureChip('Alarma', _hasAlarm,
                (value) => setState(() => _hasAlarm = value)),
          ],
        ),

        SizedBox(height: 16.h),

        // Comfort Features
        Text(
          'Confort',
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
            _buildFeatureChip('Climatizare', _hasAirConditioning,
                (value) => setState(() => _hasAirConditioning = value)),
            _buildFeatureChip('Incălzire scaune', _hasHeatedSeats,
                (value) => setState(() => _hasHeatedSeats = value)),
            _buildFeatureChip('Navigație', _hasNavigation,
                (value) => setState(() => _hasNavigation = value)),
            _buildFeatureChip('Bluetooth', _hasBluetooth,
                (value) => setState(() => _hasBluetooth = value)),
            _buildFeatureChip(
                'USB', _hasUSB, (value) => setState(() => _hasUSB = value)),
            _buildFeatureChip('Volan piele', _hasLeatherSteering,
                (value) => setState(() => _hasLeatherSteering = value)),
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
            _buildFeatureChip('Jante aliaj', _hasAlloyWheels,
                (value) => setState(() => _hasAlloyWheels = value)),
            _buildFeatureChip('Trapa', _hasSunroof,
                (value) => setState(() => _hasSunroof = value)),
            _buildFeatureChip('Faruri Xenon/LED', _hasXenonLights,
                (value) => setState(() => _hasXenonLights = value)),
            _buildFeatureChip('Oglinzi electrice', _hasElectricMirrors,
                (value) => setState(() => _hasElectricMirrors = value)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: oliveColor.withOpacity(0.3),
      checkmarkColor: oliveColor,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: value ? oliveColor : Colors.black87,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCarAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔹 Informații adiționale',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // VIN Number
        TextFormField(
          controller: _vinController,
          decoration: InputDecoration(
            labelText: 'Cod VIN (opțional)',
            hintText: 'Ex: WVWZZZ1JZ3W386752',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Previous owners
        TextFormField(
          controller: _previousOwnersController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Număr proprietari anteriori',
            hintText: '1',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Service History
        Row(
          children: [
            Checkbox(
              value: _hasServiceHistory,
              onChanged: (value) {
                setState(() {
                  _hasServiceHistory = value ?? false;
                });
              },
              activeColor: oliveColor,
            ),
            Expanded(
              child: Text(
                'Istoric service complet',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),

        // Car accident history
        Row(
          children: [
            Checkbox(
              value: _hasAccidentHistory,
              onChanged: (value) {
                setState(() {
                  _hasAccidentHistory = value ?? false;
                });
              },
              activeColor: oliveColor,
            ),
            Expanded(
              child: Text(
                'Istoric accident',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Additional Notes
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Observații suplimentare',
            hintText: 'Adăugați orice informații relevante...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarStatusOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔹 Status anunț',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),

        // For Sale Toggle
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mașina este de vânzare',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
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

        SizedBox(height: 16.h),

        // Urgency Level (only if for sale)
        if (_isForSale) ...[
          Text(
            'Nivel de urgență vânzare',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _selectedUrgency,
            decoration: InputDecoration(
              labelText: 'Urgența vânzării',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: oliveColor, width: 2),
              ),
            ),
            items: ['Normal', 'Urgentă', 'Foarte urgentă'].map((urgency) {
              return DropdownMenuItem(
                value: urgency,
                child: Text(urgency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUrgency = value;
              });
            },
          ),
          SizedBox(height: 16.h),
        ],

        // Negotiable price (only if for sale)
        if (_isForSale) ...[
          Row(
            children: [
              Checkbox(
                value: _isPriceNegotiable,
                onChanged: (value) {
                  setState(() {
                    _isPriceNegotiable = value ?? false;
                  });
                },
                activeColor: oliveColor,
              ),
              Expanded(
                child: Text(
                  'Preț negociabil',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 16.h),

        // Visibility options
        Text(
          'Opțiuni vizibilitate',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),

        Row(
          children: [
            Checkbox(
              value: _isVisibleInMarketplace,
              onChanged: (value) {
                setState(() {
                  _isVisibleInMarketplace = value ?? false;
                });
              },
              activeColor: oliveColor,
            ),
            Expanded(
              child: Text(
                'Vizibil în marketplace',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Checkbox(
              value: _allowContactFromBuyers,
              onChanged: (value) {
                setState(() {
                  _allowContactFromBuyers = value ?? false;
                });
              },
              activeColor: oliveColor,
            ),
            Expanded(
              child: Text(
                'Permite contactarea de către cumpărători',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),

        if (!_isForSale && !_isVisibleInMarketplace) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange[700], size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Mașina va fi adăugată doar în garaju personal, fără vizibilitate în marketplace.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
