import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const Map<String, String> _countryCodeMap = {
    'Romania': 'RO',
    'Moldova': 'MD',
    'Bulgaria': 'BG',
    'Hungary': 'HU',
    'Germany': 'DE',
    'France': 'FR',
    'Italy': 'IT',
    'Spain': 'ES',
    'United Kingdom': 'GB',
    'Poland': 'PL',
    'Czech Republic': 'CZ',
    'Slovakia': 'SK',
    'Austria': 'AT',
    'Serbia': 'RS',
    'Croatia': 'HR',
    'Slovenia': 'SI',
    'Ukraine': 'UA',
    'Greece': 'GR',
    'Turkey': 'TR',
    'Netherlands': 'NL',
    'Belgium': 'BE',
    'Switzerland': 'CH',
    'Portugal': 'PT',
    'Denmark': 'DK',
    'Sweden': 'SE',
    'Norway': 'NO',
    'Finland': 'FI',
  };

  static const List<String> _supportedCountries = [
    'RO', 'MD', 'BG', 'HU', 'DE', 'FR', 'IT', 'ES', 'GB', 'PL', 
    'CZ', 'SK', 'AT', 'RS', 'HR', 'SI', 'UA', 'GR', 'TR', 'NL', 
    'BE', 'CH', 'PT', 'DK', 'SE', 'NO', 'FI', 'Other'
  ];

  static const List<String> _fuelTypes = [
    'Gasoline', 'Petrol', 'Diesel', 'Hybrid', 'Electric', 'LPG', 'CNG', 'Other'
  ];

  static const List<String> _transmissionTypes = [
    'Manual', 'Automatic', 'Automat', 'CVT', 'Semi-automatic'
  ];

  static const List<String> _bodyTypes = [
    'Sedan', 'Hatchback', 'SUV', 'Coupe', 'Convertible', 'Wagon', 
    'Pickup', 'Van', 'Minivan', 'Crossover', 'Other'
  ];

  static const List<String> _conditionTypes = [
    'New', 'Used', 'Certified Pre-Owned', 'For Parts', 'Salvage'
  ];

  static const List<String> _doorOptions = [
    '2', '3', '4', '5'
  ];

  static const List<String> _colorOptions = [
    'Black', 'White', 'Silver', 'Gray', 'Red', 'Blue', 'Green', 
    'Yellow', 'Orange', 'Brown', 'Gold', 'Purple', 'Other'
  ];

  /// Detect user's country automatically based on location
  static Future<String> detectUserCountry() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return _getDefaultCountryByLocale();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return _getDefaultCountryByLocale();
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      // Get country from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        if (country != null && _countryCodeMap.containsKey(country)) {
          print('Detected country from GPS: $country -> ${_countryCodeMap[country]}');
          return _countryCodeMap[country]!;
        }
      }

      print('Could not determine country from GPS, using locale fallback');
      return _getDefaultCountryByLocale();
    } catch (e) {
      print('Error detecting country: $e');
      return _getDefaultCountryByLocale();
    }
  }

  /// Get default country based on device locale
  static String _getDefaultCountryByLocale() {
    try {
      final locale = Platform.localeName; // e.g., "en_US", "ro_RO"
      final countryCode = locale.split('_').last.toUpperCase();
      
      if (_supportedCountries.contains(countryCode)) {
        print('Using country from locale: $countryCode');
        return countryCode;
      }
      
      // Special handling for common locales
      switch (countryCode) {
        case 'US':
        case 'CA':
          return 'Other';
        default:
          return 'RO'; // Default to Romania
      }
    } catch (e) {
      print('Error getting locale: $e');
      return 'RO'; // Default to Romania
    }
  }

  /// Get list of supported countries
  static List<String> getSupportedCountries() => List.from(_supportedCountries);

  /// Get fuel types with legacy support
  static List<String> getFuelTypes() => List.from(_fuelTypes);

  /// Get transmission types with legacy support
  static List<String> getTransmissionTypes() => List.from(_transmissionTypes);

  /// Get body types
  static List<String> getBodyTypes() => List.from(_bodyTypes);

  /// Get condition types
  static List<String> getConditionTypes() => List.from(_conditionTypes);

  /// Get door options
  static List<String> getDoorOptions() => List.from(_doorOptions);

  /// Get color options
  static List<String> getColorOptions() => List.from(_colorOptions);

  /// Get display name for country code
  static String getCountryDisplayName(String countryCode) {
    final entry = _countryCodeMap.entries.firstWhere(
      (entry) => entry.value == countryCode,
      orElse: () => MapEntry(countryCode, countryCode),
    );
    return entry.key;
  }

  /// Get popular car brands by country
  static List<String> getPopularBrandsByCountry(String countryCode) {
    switch (countryCode) {
      case 'RO':
      case 'MD':
        return ['Dacia', 'Volkswagen', 'Opel', 'Ford', 'Skoda', 'BMW', 'Audi', 'Mercedes-Benz', 'Renault', 'Peugeot'];
      case 'DE':
        return ['BMW', 'Mercedes-Benz', 'Audi', 'Volkswagen', 'Opel', 'Porsche', 'Ford', 'Skoda'];
      case 'FR':
        return ['Renault', 'Peugeot', 'Citroën', 'Volkswagen', 'BMW', 'Mercedes-Benz', 'Audi', 'Ford'];
      case 'IT':
        return ['Fiat', 'Alfa Romeo', 'Lancia', 'Ferrari', 'Lamborghini', 'Maserati', 'Volkswagen', 'BMW'];
      default:
        return ['Volkswagen', 'BMW', 'Mercedes-Benz', 'Audi', 'Ford', 'Opel', 'Skoda', 'Renault', 'Peugeot', 'Toyota'];
    }
  }

  /// Check if coordinates are within a country
  static Future<bool> isLocationInCountry(double latitude, double longitude, String countryCode) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        return country != null && _countryCodeMap[country] == countryCode;
      }
      return false;
    } catch (e) {
      print('Error checking location: $e');
      return false;
    }
  }

  /// Get city name from coordinates
  static Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.locality ?? placemark.administrativeArea ?? placemark.subAdministrativeArea;
      }
      return null;
    } catch (e) {
      print('Error getting city: $e');
      return null;
    }
  }
}
