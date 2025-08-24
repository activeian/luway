import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';
import '../services/location_service.dart';
import '../services/country_service.dart';

const Color oliveColor = Color(0xFFB3B760);

class MarketplaceFilterScreen extends StatefulWidget {
  final MarketplaceFilter? initialFilter;
  final MarketplaceItemType? filterType;

  const MarketplaceFilterScreen({
    super.key,
    this.initialFilter,
    this.filterType,
  });

  @override
  State<MarketplaceFilterScreen> createState() => _MarketplaceFilterScreenState();
}

class _MarketplaceFilterScreenState extends State<MarketplaceFilterScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Car specific controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _minYearController = TextEditingController();
  final _maxYearController = TextEditingController();
  final _minMileageController = TextEditingController();
  final _maxMileageController = TextEditingController();
  final _minPowerController = TextEditingController();
  final _maxPowerController = TextEditingController();

  MarketplaceItemType? _selectedType;
  ServiceCategory? _selectedServiceCategory;
  AccessoryCategory? _selectedAccessoryCategory;
  List<String> _selectedTags = [];
  
  // Car specific filters
  CountryInfo? _selectedCountryInfo;
  String? _selectedFuelType;
  String? _selectedTransmission;
  String? _selectedBodyType;
  String? _selectedColor;
  String? _selectedCondition;
  String? _selectedDoors;
  
  // Equipment filters
  bool _hasABS = false;
  bool _hasESP = false;
  bool _hasAirbags = false;
  bool _hasAirConditioning = false;
  bool _hasNavigation = false;
  bool _hasHeatedSeats = false;
  bool _hasAlarm = false;
  bool _hasBluetooth = false;
  bool _hasUSB = false;
  bool _hasLeatherSteering = false;
  bool _hasAlloyWheels = false;
  bool _hasSunroof = false;
  bool _hasXenonLights = false;
  bool _hasElectricMirrors = false;
  
  // Status filters
  bool _isForSale = false;
  bool _isPriceNegotiable = false;
  bool _hasServiceHistory = false;
  bool _hasNoAccidentHistory = false;
  
  bool _isDetectingCountry = false;

  @override
  void initState() {
    super.initState();
    _initializeFromFilter();
  }

  void _initializeFromFilter() {
    if (widget.initialFilter != null) {
      final filter = widget.initialFilter!;
      _searchController.text = filter.searchQuery ?? '';
      _selectedType = filter.type;
      _minPriceController.text = filter.minPrice?.toString() ?? '';
      _maxPriceController.text = filter.maxPrice?.toString() ?? '';
      _locationController.text = filter.location ?? '';
      _selectedServiceCategory = filter.serviceCategory;
      _selectedAccessoryCategory = filter.accessoryCategory;
      _selectedTags = List.from(filter.tags);
      
      // Car specific filters
      _selectedCountryInfo = filter.country != null 
          ? CountryService.countries.firstWhere(
              (c) => c.code == filter.country,
              orElse: () => CountryService.countries.first,
            )
          : null;
      _brandController.text = filter.brand ?? '';
      _modelController.text = filter.model ?? '';
      _minYearController.text = filter.minYear?.toString() ?? '';
      _maxYearController.text = filter.maxYear?.toString() ?? '';
      _selectedFuelType = filter.fuelType;
      _selectedTransmission = filter.transmission;
      _selectedBodyType = filter.bodyType;
      _selectedColor = filter.color;
      _selectedCondition = filter.condition;
      _minMileageController.text = filter.minMileage?.toString() ?? '';
      _maxMileageController.text = filter.maxMileage?.toString() ?? '';
      _minPowerController.text = filter.minPower?.toString() ?? '';
      _maxPowerController.text = filter.maxPower?.toString() ?? '';
      _selectedDoors = filter.doors;
      
      // Equipment filters
      _hasABS = filter.hasABS ?? false;
      _hasESP = filter.hasESP ?? false;
      _hasAirbags = filter.hasAirbags ?? false;
      _hasAirConditioning = filter.hasAirConditioning ?? false;
      _hasNavigation = filter.hasNavigation ?? false;
      _hasHeatedSeats = filter.hasHeatedSeats ?? false;
      _hasAlarm = filter.hasAlarm ?? false;
      _hasBluetooth = filter.hasBluetooth ?? false;
      _hasUSB = filter.hasUSB ?? false;
      _hasLeatherSteering = filter.hasLeatherSteering ?? false;
      _hasAlloyWheels = filter.hasAlloyWheels ?? false;
      _hasSunroof = filter.hasSunroof ?? false;
      _hasXenonLights = filter.hasXenonLights ?? false;
      _hasElectricMirrors = filter.hasElectricMirrors ?? false;
      
      // Status filters
      _isForSale = filter.isForSale ?? false;
      _isPriceNegotiable = filter.isPriceNegotiable ?? false;
      _hasServiceHistory = filter.hasServiceHistory ?? false;
      _hasNoAccidentHistory = filter.hasAccidentHistory == false;
    }
    
    if (widget.filterType != null) {
      _selectedType = widget.filterType;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    _minMileageController.dispose();
    _maxMileageController.dispose();
    _minPowerController.dispose();
    _maxPowerController.dispose();
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
        title: Text(
          'Filter Items',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  SizedBox(height: 24.h),
                  _buildTypeSection(),
                  SizedBox(height: 24.h),
                  _buildPriceSection(),
                  SizedBox(height: 24.h),
                  _buildLocationSection(),
                  SizedBox(height: 24.h),
                  if (_selectedType != null && _selectedType != MarketplaceItemType.car) _buildCategorySection(),
                  if (_selectedType == MarketplaceItemType.car) ...[
                    SizedBox(height: 24.h),
                    _buildCarSpecificFilters(),
                  ],
                  SizedBox(height: 24.h),
                  _buildTagsSection(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by title, description or tags...',
            prefixIcon: const Icon(Icons.search),
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

  Widget _buildTypeSection() {
    if (widget.filterType != null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Type',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          children: MarketplaceItemType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? type : null;
                  // Reset category selections when type changes
                  _selectedServiceCategory = null;
                  _selectedAccessoryCategory = null;
                });
              },
              selectedColor: oliveColor.withOpacity(0.2),
              checkmarkColor: oliveColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Price',
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
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Price',
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
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Enter city or country...',
            prefixIcon: const Icon(Icons.location_on),
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

  Widget _buildCategorySection() {
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
        
        if (_selectedType == MarketplaceItemType.service)
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
            items: [
              const DropdownMenuItem<ServiceCategory>(
                value: null,
                child: Text('All Categories'),
              ),
              ...ServiceCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(MarketplaceService.getServiceCategoryName(category)),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedServiceCategory = value;
              });
            },
          ),
        
        if (_selectedType == MarketplaceItemType.accessory)
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
            items: [
              const DropdownMenuItem<AccessoryCategory>(
                value: null,
                child: Text('All Categories'),
              ),
              ...AccessoryCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(MarketplaceService.getAccessoryCategoryName(category)),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAccessoryCategory = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildCarSpecificFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Filters',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),
        
        // Country filter with auto-detection
        _buildCountrySection(),
        SizedBox(height: 16.h),
        
        // Brand and Model
        _buildBrandModelSection(),
        SizedBox(height: 16.h),
        
        // Year range
        _buildYearSection(),
        SizedBox(height: 16.h),
        
        // Technical specifications
        _buildTechnicalSpecsSection(),
        SizedBox(height: 16.h),
        
        // Mileage and Power
        _buildMileagePowerSection(),
        SizedBox(height: 16.h),
        
        // Equipment features
        _buildEquipmentSection(),
        SizedBox(height: 16.h),
        
        // Status filters
        _buildStatusSection(),
      ],
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Country',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: _isDetectingCountry ? null : _detectCountry,
              icon: _isDetectingCountry 
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.location_on, size: 16.sp),
              label: Text('Auto-detect'),
              style: TextButton.styleFrom(
                foregroundColor: oliveColor,
                textStyle: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _showCountryPicker,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                if (_selectedCountryInfo != null) ...[
                  Text(
                    _selectedCountryInfo!.flag,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _selectedCountryInfo!.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.language, color: Colors.grey.shade500),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Select country...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandModelSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _brandController,
            decoration: InputDecoration(
              labelText: 'Brand',
              hintText: 'e.g. BMW, Mercedes...',
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
            controller: _modelController,
            decoration: InputDecoration(
              labelText: 'Model',
              hintText: 'e.g. X5, C-Class...',
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
    );
  }

  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year Range',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minYearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'From',
                  hintText: '2000',
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
                controller: _maxYearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'To',
                  hintText: '2024',
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
      ],
    );
  }

  Widget _buildTechnicalSpecsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Technical Specifications',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Fuel Type
        DropdownButtonFormField<String>(
          value: _selectedFuelType,
          decoration: InputDecoration(
            labelText: 'Fuel Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...LocationService.getFuelTypes().map((fuel) {
              return DropdownMenuItem(value: fuel, child: Text(fuel));
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFuelType = value;
            });
          },
        ),
        SizedBox(height: 12.h),
        
        // Transmission
        DropdownButtonFormField<String>(
          value: _selectedTransmission,
          decoration: InputDecoration(
            labelText: 'Transmission',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: oliveColor, width: 2),
            ),
          ),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('Any')),
            ...LocationService.getTransmissionTypes().map((transmission) {
              return DropdownMenuItem(value: transmission, child: Text(transmission));
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTransmission = value;
            });
          },
        ),
        SizedBox(height: 12.h),
        
        // Body Type and other specs in a row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedBodyType,
                decoration: InputDecoration(
                  labelText: 'Body Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('Any')),
                  ...LocationService.getBodyTypes().map((body) {
                    return DropdownMenuItem(value: body, child: Text(body));
                  }),
                ],
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
                value: _selectedDoors,
                decoration: InputDecoration(
                  labelText: 'Doors',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: oliveColor, width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('Any')),
                  ...LocationService.getDoorOptions().map((doors) {
                    return DropdownMenuItem(value: doors, child: Text('$doors doors'));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDoors = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMileagePowerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mileage & Power',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Mileage range
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minMileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Mileage (km)',
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
                controller: _maxMileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Mileage (km)',
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
        SizedBox(height: 12.h),
        
        // Power range
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPowerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Power (HP)',
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
                controller: _maxPowerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Power (HP)',
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
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment Features',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Safety equipment
        Text(
          'Safety',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildEquipmentChip('ABS', _hasABS, (value) => setState(() => _hasABS = value)),
            _buildEquipmentChip('ESP', _hasESP, (value) => setState(() => _hasESP = value)),
            _buildEquipmentChip('Airbags', _hasAirbags, (value) => setState(() => _hasAirbags = value)),
            _buildEquipmentChip('Alarm', _hasAlarm, (value) => setState(() => _hasAlarm = value)),
          ],
        ),
        
        SizedBox(height: 12.h),
        Text(
          'Comfort',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildEquipmentChip('A/C', _hasAirConditioning, (value) => setState(() => _hasAirConditioning = value)),
            _buildEquipmentChip('Navigation', _hasNavigation, (value) => setState(() => _hasNavigation = value)),
            _buildEquipmentChip('Heated Seats', _hasHeatedSeats, (value) => setState(() => _hasHeatedSeats = value)),
            _buildEquipmentChip('Bluetooth', _hasBluetooth, (value) => setState(() => _hasBluetooth = value)),
            _buildEquipmentChip('USB', _hasUSB, (value) => setState(() => _hasUSB = value)),
            _buildEquipmentChip('Leather Steering', _hasLeatherSteering, (value) => setState(() => _hasLeatherSteering = value)),
          ],
        ),
        
        SizedBox(height: 12.h),
        Text(
          'Exterior',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildEquipmentChip('Alloy Wheels', _hasAlloyWheels, (value) => setState(() => _hasAlloyWheels = value)),
            _buildEquipmentChip('Sunroof', _hasSunroof, (value) => setState(() => _hasSunroof = value)),
            _buildEquipmentChip('Xenon Lights', _hasXenonLights, (value) => setState(() => _hasXenonLights = value)),
            _buildEquipmentChip('Electric Mirrors', _hasElectricMirrors, (value) => setState(() => _hasElectricMirrors = value)),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: oliveColor.withOpacity(0.2),
      checkmarkColor: oliveColor,
      labelStyle: TextStyle(
        fontSize: 12.sp,
        color: value ? oliveColor : Colors.grey[700],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status & History',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildEquipmentChip('For Sale', _isForSale, (value) => setState(() => _isForSale = value)),
            _buildEquipmentChip('Price Negotiable', _isPriceNegotiable, (value) => setState(() => _isPriceNegotiable = value)),
            _buildEquipmentChip('Service History', _hasServiceHistory, (value) => setState(() => _hasServiceHistory = value)),
            _buildEquipmentChip('No Accidents', _hasNoAccidentHistory, (value) => setState(() => _hasNoAccidentHistory = value)),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Common tags
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            'new', 'used', 'luxury', 'sport', 'family', 'commercial', 'vintage', 'rare'
          ].map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: oliveColor.withOpacity(0.2),
              checkmarkColor: oliveColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: oliveColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: Text(
                'Apply Filters',
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

  String _getTypeLabel(MarketplaceItemType type) {
    switch (type) {
      case MarketplaceItemType.car:
        return 'Cars';
      case MarketplaceItemType.accessory:
        return 'Accessories';
      case MarketplaceItemType.service:
        return 'Services';
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: CountryPickerModal(
          onCountrySelected: (country) {
            setState(() {
              _selectedCountryInfo = country;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _locationController.clear();
      _selectedType = widget.filterType; // Keep initial type if provided
      _selectedServiceCategory = null;
      _selectedAccessoryCategory = null;
      _selectedTags.clear();
      
      // Clear car specific filters
      _selectedCountryInfo = null;
      _brandController.clear();
      _modelController.clear();
      _minYearController.clear();
      _maxYearController.clear();
      _selectedFuelType = null;
      _selectedTransmission = null;
      _selectedBodyType = null;
      _selectedColor = null;
      _selectedCondition = null;
      _minMileageController.clear();
      _maxMileageController.clear();
      _minPowerController.clear();
      _maxPowerController.clear();
      _selectedDoors = null;
      
      // Clear equipment filters
      _hasABS = false;
      _hasESP = false;
      _hasAirbags = false;
      _hasAirConditioning = false;
      _hasNavigation = false;
      _hasHeatedSeats = false;
      _hasAlarm = false;
      _hasBluetooth = false;
      _hasUSB = false;
      _hasLeatherSteering = false;
      _hasAlloyWheels = false;
      _hasSunroof = false;
      _hasXenonLights = false;
      _hasElectricMirrors = false;
      
      // Clear status filters
      _isForSale = false;
      _isPriceNegotiable = false;
      _hasServiceHistory = false;
      _hasNoAccidentHistory = false;
    });
  }

  void _applyFilters() {
    final filter = MarketplaceFilter(
      searchQuery: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      type: _selectedType,
      minPrice: _minPriceController.text.isNotEmpty ? double.tryParse(_minPriceController.text) : null,
      maxPrice: _maxPriceController.text.isNotEmpty ? double.tryParse(_maxPriceController.text) : null,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      serviceCategory: _selectedServiceCategory,
      accessoryCategory: _selectedAccessoryCategory,
      tags: _selectedTags,
      
      // Car specific filters
      country: _selectedCountryInfo?.code,
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      model: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
      minYear: _minYearController.text.isNotEmpty ? int.tryParse(_minYearController.text) : null,
      maxYear: _maxYearController.text.isNotEmpty ? int.tryParse(_maxYearController.text) : null,
      fuelType: _selectedFuelType,
      transmission: _selectedTransmission,
      bodyType: _selectedBodyType,
      color: _selectedColor,
      condition: _selectedCondition,
      minMileage: _minMileageController.text.isNotEmpty ? int.tryParse(_minMileageController.text) : null,
      maxMileage: _maxMileageController.text.isNotEmpty ? int.tryParse(_maxMileageController.text) : null,
      minPower: _minPowerController.text.isNotEmpty ? int.tryParse(_minPowerController.text) : null,
      maxPower: _maxPowerController.text.isNotEmpty ? int.tryParse(_maxPowerController.text) : null,
      doors: _selectedDoors,
      
      // Equipment filters (only if selected)
      hasABS: _hasABS ? true : null,
      hasESP: _hasESP ? true : null,
      hasAirbags: _hasAirbags ? true : null,
      hasAirConditioning: _hasAirConditioning ? true : null,
      hasNavigation: _hasNavigation ? true : null,
      hasHeatedSeats: _hasHeatedSeats ? true : null,
      hasAlarm: _hasAlarm ? true : null,
      hasBluetooth: _hasBluetooth ? true : null,
      hasUSB: _hasUSB ? true : null,
      hasLeatherSteering: _hasLeatherSteering ? true : null,
      hasAlloyWheels: _hasAlloyWheels ? true : null,
      hasSunroof: _hasSunroof ? true : null,
      hasXenonLights: _hasXenonLights ? true : null,
      hasElectricMirrors: _hasElectricMirrors ? true : null,
      
      // Status filters (only if selected)
      isForSale: _isForSale ? true : null,
      isPriceNegotiable: _isPriceNegotiable ? true : null,
      hasServiceHistory: _hasServiceHistory ? true : null,
      hasAccidentHistory: _hasNoAccidentHistory ? false : null,
    );

    Navigator.pop(context, filter);
  }

  Future<void> _detectCountry() async {
    setState(() {
      _isDetectingCountry = true;
    });

    try {
      final detectedCountry = await CountryService.detectCurrentCountry();
      setState(() {
        _selectedCountryInfo = detectedCountry;
        _isDetectingCountry = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected country: ${detectedCountry?.name ?? 'Unknown'}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDetectingCountry = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not detect country automatically'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
                    '${country.code} • License plate format: ${country.format}',
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
