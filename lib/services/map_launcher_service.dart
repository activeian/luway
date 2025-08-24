import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapLauncherService {
  /// Opens the appropriate map application based on the platform
  /// iOS: Apple Maps
  /// Android: Google Maps
  static Future<void> openMapWithLocation(String address,
      {BuildContext? context}) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);

      if (Platform.isIOS) {
        await _openAppleMaps(encodedAddress, context: context);
      } else {
        await _openGoogleMaps(encodedAddress, context: context);
      }
    } catch (e) {
      print('Error opening map: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Opens the appropriate map application with navigation/directions
  /// iOS: Apple Maps with directions
  /// Android: Google Maps with directions
  static Future<void> openMapWithDirections(String address,
      {BuildContext? context}) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);

      if (Platform.isIOS) {
        await _openAppleMapsWithDirections(encodedAddress, context: context);
      } else {
        await _openGoogleMapsWithDirections(encodedAddress, context: context);
      }
    } catch (e) {
      print('Error opening map with directions: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map application for directions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open Apple Maps on iOS
  static Future<void> _openAppleMaps(String encodedAddress,
      {BuildContext? context}) async {
    final urls = [
      // Apple Maps with search query
      'maps:?q=$encodedAddress',
      // Alternative Apple Maps URL
      'http://maps.apple.com/?q=$encodedAddress',
      // Fallback to Safari with Apple Maps web
      'https://maps.apple.com/?q=$encodedAddress',
    ];

    bool launched = await _tryLaunchUrls(urls);

    if (!launched) {
      // Final fallback to Google Maps web
      final fallbackUrl = 'https://maps.google.com/maps?q=$encodedAddress';
      final uri = Uri.parse(fallbackUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Apple Maps with directions on iOS
  static Future<void> _openAppleMapsWithDirections(String encodedAddress,
      {BuildContext? context}) async {
    final urls = [
      // Apple Maps with directions
      'maps:?daddr=$encodedAddress&dirflg=d',
      // Alternative Apple Maps directions
      'http://maps.apple.com/?daddr=$encodedAddress',
      // Fallback to Apple Maps web with directions
      'https://maps.apple.com/?daddr=$encodedAddress',
    ];

    bool launched = await _tryLaunchUrls(urls);

    if (!launched) {
      // Final fallback to Google Maps web with directions
      final fallbackUrl = 'https://maps.google.com/maps?daddr=$encodedAddress';
      final uri = Uri.parse(fallbackUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Google Maps on Android
  static Future<void> _openGoogleMaps(String encodedAddress,
      {BuildContext? context}) async {
    final urls = [
      // Google Maps app with search
      'geo:0,0?q=$encodedAddress',
      // Alternative Google Maps app URL
      'google.navigation:q=$encodedAddress',
      // Google Maps web URL
      'https://maps.google.com/?q=$encodedAddress',
      // Google Maps API URL
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    ];

    bool launched = await _tryLaunchUrls(urls);

    if (!launched) {
      // Final fallback to browser
      final fallbackUrl =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      final uri = Uri.parse(fallbackUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Google Maps with directions on Android
  static Future<void> _openGoogleMapsWithDirections(String encodedAddress,
      {BuildContext? context}) async {
    final urls = [
      // Google Maps navigation
      'google.navigation:q=$encodedAddress',
      // Google Maps with directions
      'https://maps.google.com/maps?daddr=$encodedAddress',
      // Google Maps API with directions
      'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
    ];

    bool launched = await _tryLaunchUrls(urls);

    if (!launched) {
      // Final fallback to browser with directions
      final fallbackUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress';
      final uri = Uri.parse(fallbackUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Try to launch URLs in order until one succeeds
  static Future<bool> _tryLaunchUrls(List<String> urls) async {
    for (String urlString in urls) {
      try {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          return true;
        }
      } catch (e) {
        print('Failed to launch $urlString: $e');
        continue;
      }
    }
    return false;
  }

  /// Get the platform-appropriate map application name
  static String get mapAppName {
    return Platform.isIOS ? 'Apple Maps' : 'Google Maps';
  }

  /// Check if maps can be opened on this platform
  static Future<bool> canOpenMaps() async {
    if (Platform.isIOS) {
      // Check if Apple Maps is available
      final uri = Uri.parse('maps:');
      return await canLaunchUrl(uri);
    } else {
      // Check if Google Maps or web browser is available
      final geoUri = Uri.parse('geo:0,0?q=test');
      final webUri = Uri.parse('https://maps.google.com');
      return await canLaunchUrl(geoUri) || await canLaunchUrl(webUri);
    }
  }
}
