import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DistanceService {
  static Position? _currentPosition;
  static DateTime? _lastLocationUpdate;
  static const Duration _locationCacheTime = Duration(minutes: 5);

  /// Get current position with caching
  static Future<Position?> getCurrentPosition() async {
    // Check if we have a recent cached position
    if (_currentPosition != null && 
        _lastLocationUpdate != null && 
        DateTime.now().difference(_lastLocationUpdate!) < _locationCacheTime) {
      return _currentPosition;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      _lastLocationUpdate = DateTime.now();

      return _currentPosition;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Calculate distance between user and a location string (address)
  static Future<double?> calculateDistanceToAddress(String address) async {
    try {
      Position? userPosition = await getCurrentPosition();
      if (userPosition == null) return null;

      // Get coordinates from address
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      Location targetLocation = locations.first;
      
      // Calculate distance in meters
      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );

      // Convert to kilometers
      return distanceInMeters / 1000;
    } catch (e) {
      print('Error calculating distance to address: $e');
      return null;
    }
  }

  /// Calculate distance between user and coordinates
  static Future<double?> calculateDistanceToCoordinates(
    double latitude, 
    double longitude
  ) async {
    try {
      Position? userPosition = await getCurrentPosition();
      if (userPosition == null) return null;

      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        latitude,
        longitude,
      );

      // Convert to kilometers
      return distanceInMeters / 1000;
    } catch (e) {
      print('Error calculating distance to coordinates: $e');
      return null;
    }
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Get location coordinates from address string
  static Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Calculate distance between two addresses
  static Future<double?> calculateDistanceBetweenAddresses(
    String address1, 
    String address2
  ) async {
    try {
      List<Location> locations1 = await locationFromAddress(address1);
      List<Location> locations2 = await locationFromAddress(address2);
      
      if (locations1.isEmpty || locations2.isEmpty) return null;

      double distanceInMeters = Geolocator.distanceBetween(
        locations1.first.latitude,
        locations1.first.longitude,
        locations2.first.latitude,
        locations2.first.longitude,
      );

      return distanceInMeters / 1000;
    } catch (e) {
      print('Error calculating distance between addresses: $e');
      return null;
    }
  }

  /// Clear cached position (useful for testing or forced refresh)
  static void clearCache() {
    _currentPosition = null;
    _lastLocationUpdate = null;
  }
}
