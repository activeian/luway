import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  static const String uploadEndpoint = 'https://wzsgame.com/upload.php';

  // Upload image to your server
  Future<String> uploadImage(File imageFile) async {
    try {
      // Compress image if needed (you can add compression logic here)
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      Response response = await _dio.post(
        uploadEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'] as String;
      } else {
        throw Exception('Upload failed: ${response.data['message'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Upload failed: ${e.response!.statusMessage}');
      } else {
        throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      List<String> uploadedUrls = [];
      
      for (File file in imageFiles) {
        String url = await uploadImage(file);
        uploadedUrls.add(url);
      }
      
      return uploadedUrls;
    } catch (e) {
      throw Exception('Multiple upload failed: ${e.toString()}');
    }
  }

  // Validate license plate format
  Future<bool> validateLicensePlate(String licensePlate, String countryCode) async {
    try {
      // You can implement server-side validation
      // For now, just basic client-side validation
      
      if (licensePlate.isEmpty) return false;
      
      // Remove spaces and convert to uppercase
      String cleanPlate = licensePlate.replaceAll(' ', '').toUpperCase();
      
      // Basic validation - contains only letters, numbers, and hyphens
      RegExp regExp = RegExp(r'^[A-Z0-9-]+$');
      return regExp.hasMatch(cleanPlate);
    } catch (e) {
      return false;
    }
  }

  // Get country-specific license plate format
  String? getLicensePlateFormat(String countryCode) {
    // This should match your global_plate.md data
    const Map<String, String> formats = {
      'DE': 'LLL CC CCCC',
      'US': 'CLLL CCC',
      'FR': 'LL-CCC-LL',
      'GB': 'LLCC LLL',
      'IT': 'LL CCC LL',
      'ES': 'CCCC LLL',
      'RO': 'CC CC LLL',
      'AT': 'L-NN LLL',
      'BE': 'C LLL CCC',
      'NL': 'LL-CC-CC',
      'PL': 'LL CCCCC',
      'CH': 'LL CCCCCC',
      // Add more countries as needed
    };
    
    return formats[countryCode];
  }

  // Geocoding service (if you want to get location from coordinates)
  Future<String?> getLocationFromCoordinates(double latitude, double longitude) async {
    try {
      // You can integrate with a geocoding service here
      // For now, return a placeholder
      return 'Location ($latitude, $longitude)';
    } catch (e) {
      return null;
    }
  }

  // Send push notification (if you have your own notification service)
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Implement your push notification logic here
      // This could be a call to your server or Firebase Cloud Functions
      
      Response response = await _dio.post(
        'your-notification-endpoint',
        data: {
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      print('Failed to send push notification: $e');
    }
  }

  // Analytics tracking
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Implement analytics tracking
      // Could be Firebase Analytics, Google Analytics, or custom analytics
      
      print('Event tracked: $eventName with parameters: $parameters');
    } catch (e) {
      print('Failed to track event: $e');
    }
  }

  // Payment processing (for subscriptions)
  Future<Map<String, dynamic>> processPayment({
    required String amount,
    required String currency,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Implement payment processing logic
      // This could integrate with Stripe, PayPal, or Google Play Billing
      
      Response response = await _dio.post(
        'your-payment-endpoint',
        data: {
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
          'metadata': metadata,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Payment failed');
      }
    } catch (e) {
      throw Exception('Payment processing failed: ${e.toString()}');
    }
  }

  // Search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      // Implement search suggestions logic
      // Could be from your server or a third-party service
      
      if (query.length < 2) return [];
      
      // Mock suggestions
      return [
        'BMW X5 2023',
        'Mercedes C-Class',
        'Audi A4',
        'Volkswagen Golf',
        'Ford Focus',
      ].where((suggestion) => 
        suggestion.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Report content
  Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
  }) async {
    try {
      await _dio.post(
        'your-report-endpoint',
        data: {
          'content_id': contentId,
          'content_type': contentType,
          'reason': reason,
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to report content: ${e.toString()}');
    }
  }

  // Get app configuration
  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      Response response = await _dio.get('your-config-endpoint');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get app config');
      }
    } catch (e) {
      // Return default config if server is unreachable
      return {
        'maintenance_mode': false,
        'min_app_version': '1.0.0',
        'supported_countries': ['DE', 'US', 'FR', 'GB', 'IT', 'ES', 'RO'],
        'features': {
          'chat': true,
          'marketplace': true,
          'subscriptions': true,
          'push_notifications': true,
        },
      };
    }
  }
}
