import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/car_service.dart';
import '../services/country_service.dart';
import '../models/car.dart';
import '../screens/car_details_screen.dart';

class CarSearchBar extends StatefulWidget {
  final String hintText;
  final CountryInfo? currentCountry;

  const CarSearchBar({
    super.key,
    this.hintText = 'Search by plate number...',
    this.currentCountry,
  });

  @override
  State<CarSearchBar> createState() => _CarSearchBarState();
}

class _CarSearchBarState extends State<CarSearchBar> {
  final TextEditingController _controller = TextEditingController();
  List<Car> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Car> results = await CarService.searchCarsByPlate(
        query,
        currentCountryCode: widget.currentCountry?.code,
      );

      setState(() {
        _searchResults = results;
        _showResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _isSearching = false;
      });
    }
  }

  void _hideResults() {
    setState(() => _showResults = false);
  }

  void _showCarDetails(Car car) {
    _hideResults();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarDetailsScreen(car: car),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 24.w,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            _controller.clear();
                            _hideResults();
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
        
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final car = _searchResults[index];
                final country = CountryService.getCountryByCode(car.countryCode);
                
                return ListTile(
                  onTap: () => _showCarDetails(car),
                  leading: Container(
                    width: 48.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          country?.flag ?? '🌍',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        Text(
                          car.countryCode,
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    car.plateNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16.sp,
                    ),
                  ),
                  subtitle: Text(
                    '${car.brand} ${car.model}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (car.isForSale) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'For Sale',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16.w,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        if (_showResults && _searchResults.isEmpty && !_isSearching)
          Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: Colors.grey[600],
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  'No cars found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
