import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'LuWay';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Global car search and marketplace platform';

  // App Color Scheme
  static const Color primaryOlive = Color(0xFFB3B760);
  static const Color darkGreen = Color(0xFF064232);
  static const Color primaryBlack = Color(0xFF000000);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color warningOrange = Color(0xFFFF8C00);
  static const Color successGreen = primaryOlive;

  // Storage Keys
  static const String onboardingCompleted = 'onboarding_completed';
  static const String languageKey = 'language';
  static const String currencyKey = 'currency';
  static const String notificationsKey = 'notifications';
  static const String darkModeKey = 'darkMode';
  static const String isGuestKey = 'is_guest';

  // Default Values
  static const String defaultLanguage = 'English';
  static const String defaultCurrency = 'EUR';
  static const bool defaultNotifications = true;
  static const bool defaultDarkMode = false;

  // Supported Languages
  static const List<String> supportedLanguages = [
    'English',
    'Română',
    'Français',
    'Deutsch',
    'Español',
    'Italiano',
    'Português',
    'Polski',
    'Nederlands',
    'Svenska'
  ];

  // Supported Currencies
  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'RON',
    'GBP',
    'CHF',
    'PLN',
    'SEK',
    'DKK',
    'NOK',
    'CZK'
  ];

  // Vehicle Categories
  static const List<String> vehicleCategories = [
    'All',
    'Cars',
    'Motorcycles',
    'Trucks',
    'Vans',
    'Buses',
    'Trailers',
    'Agricultural',
    'Construction',
    'Other'
  ];

  // Car Brands (most popular in Europe)
  static const List<String> carBrands = [
    'Audi',
    'BMW',
    'Mercedes-Benz',
    'Volkswagen',
    'Ford',
    'Toyota',
    'Honda',
    'Nissan',
    'Hyundai',
    'Kia',
    'Peugeot',
    'Renault',
    'Citroën',
    'SEAT',
    'Škoda',
    'Volvo',
    'MINI',
    'Fiat',
    'Alfa Romeo',
    'Opel',
    'Mazda',
    'Subaru',
    'Mitsubishi',
    'Lexus',
    'Infiniti',
    'Acura',
    'Cadillac',
    'Chevrolet',
    'Chrysler',
    'Dodge',
    'Jeep',
    'Lincoln',
    'Buick',
    'GMC',
    'Tesla',
    'Porsche',
    'Ferrari',
    'Lamborghini',
    'McLaren',
    'Bentley',
    'Rolls-Royce',
    'Aston Martin',
    'Jaguar',
    'Land Rover',
    'Maserati',
    'Dacia',
    'Lada',
    'Other'
  ];

  // Fuel Types
  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'Plug-in Hybrid',
    'LPG',
    'CNG',
    'Hydrogen',
    'Other'
  ];

  // Transmission Types
  static const List<String> transmissionTypes = [
    'Manual',
    'Automatic',
    'Semi-automatic',
    'CVT'
  ];

  // Color Options
  static const List<String> vehicleColors = [
    'White',
    'Black',
    'Silver',
    'Grey',
    'Blue',
    'Red',
    'Green',
    'Yellow',
    'Orange',
    'Brown',
    'Purple',
    'Pink',
    'Gold',
    'Beige',
    'Other'
  ];

  // Condition Types
  static const List<String> conditionTypes = [
    'New',
    'Used - Excellent',
    'Used - Good',
    'Used - Fair',
    'Used - Poor',
    'Damaged',
    'For Parts'
  ];

  // Price Ranges (in EUR)
  static const List<String> priceRanges = [
    'Under 5,000',
    '5,000 - 10,000',
    '10,000 - 20,000',
    '20,000 - 30,000',
    '30,000 - 50,000',
    '50,000 - 100,000',
    'Over 100,000'
  ];

  // Year Ranges
  static List<String> get yearRanges {
    final currentYear = DateTime.now().year;
    List<String> years = ['Any Year'];
    for (int i = currentYear; i >= 1950; i--) {
      years.add(i.toString());
    }
    return years;
  }

  // Subscription Plans
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'free': {
      'name': 'Free',
      'price': 0,
      'currency': 'EUR',
      'duration': 'Forever',
      'features': [
        'Browse unlimited listings',
        'Basic search filters',
        'Contact sellers',
        'View seller information',
        'Add up to 3 vehicles'
      ],
      'limitations': [
        'Limited to 3 vehicle listings',
        'No priority in search results',
        'Basic analytics only'
      ]
    },
    'premium': {
      'name': 'Premium',
      'price': 9.99,
      'currency': 'EUR',
      'duration': 'Monthly',
      'features': [
        'All Free features',
        'Unlimited vehicle listings',
        'Priority in search results',
        'Advanced analytics',
        'Premium badge on listings',
        'Multiple photos per listing',
        'Export data functionality'
      ],
      'limitations': []
    },
    'business': {
      'name': 'Business',
      'price': 29.99,
      'currency': 'EUR',
      'duration': 'Monthly',
      'features': [
        'All Premium features',
        'Dealer verification badge',
        'Custom branding options',
        'API access',
        'Bulk upload tools',
        'Advanced reporting',
        'Priority customer support',
        'Featured listings'
      ],
      'limitations': []
    }
  };

  // API Endpoints (when implementing real backend)
  static const String baseApiUrl = 'https://api.luway.com/v1';
  static const String vehiclesEndpoint = '/vehicles';
  static const String usersEndpoint = '/users';
  static const String searchEndpoint = '/search';
  static const String messagesEndpoint = '/messages';
  static const String subscriptionsEndpoint = '/subscriptions';

  // Image Configuration
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImagesPerListing = 10;

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int minPrice = 1;
  static const int maxPrice = 10000000;
  static const int minYear = 1950;

  // Chat Configuration
  static const int maxMessageLength = 500;
  static const int messagesPerPage = 50;

  // Search Configuration
  static const int searchResultsPerPage = 20;
  static const int maxSearchHistory = 10;

  // Location Configuration
  static const double defaultLatitude = 50.0755;
  static const double defaultLongitude = 14.4378;
  static const double searchRadiusKm = 50.0;

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please log in again.';
  static const String validationError =
      'Please check your input and try again.';

  // Success Messages
  static const String vehicleAddedSuccess = 'Vehicle added successfully!';
  static const String vehicleUpdatedSuccess = 'Vehicle updated successfully!';
  static const String vehicleDeletedSuccess = 'Vehicle deleted successfully!';
  static const String messageSentSuccess = 'Message sent successfully!';
  static const String profileUpdatedSuccess = 'Profile updated successfully!';
}
