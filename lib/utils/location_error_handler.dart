import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class LocationErrorHandler {
  /// Handles location service errors and provides appropriate user feedback
  static String handleLocationError(dynamic error) {
    developer.log('Location error: ${error.toString()}', name: 'LocationErrorHandler');
    
    if (error is LocationServiceDisabledException) {
      return 'Location services are disabled. Please enable location services in your device settings.';
    } else if (error is PermissionDeniedException) {
      return 'Location permission denied. Please grant location permission to use this feature.';
    } else if (error is TimeoutException) {
      return 'Location request timed out. Please try again.';
    } else {
      return 'Error determining location: ${error.toString()}';
    }
  }

  /// Shows a dialog with options to enable location services
  static Future<void> showLocationServiceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'This app requires location services to provide you with nearby issues. '
            'Please enable location services to continue.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OPEN SETTINGS'),
              onPressed: () {
                Navigator.of(context).pop();
                openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog with options to grant location permission
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs access to your location to show issues near you. '
            'Please grant location permission to continue.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('NOT NOW'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OPEN SETTINGS'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Opens location settings on the device
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens app settings on the device
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Provides a fallback mechanism when location is unavailable
  static Widget buildLocationUnavailableWidget(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Location services unavailable',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We need your location to show nearby issues',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}