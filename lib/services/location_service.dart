import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer; // For logging
import '../utils/location_utils.dart';
import '../models/issue_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  // Add this flag to track permission requests
  bool _isRequestingPermission = false;
  
  // Cache for user's current position
  Position? _cachedPosition;
  DateTime? _lastPositionTime;
  
  // Constants
  static const double defaultProximityRadiusKm = 10.0; // Default radius for proximity filtering
  
  Future<Position?> getCurrentPosition({bool useCache = true}) async {
    // Check if we can use cached position (cache valid for 5 minutes)
    if (useCache && _cachedPosition != null && _lastPositionTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastPositionTime!).inMinutes < 5) {
        return _cachedPosition;
      }
    }
    
    // Check if permission is already granted first
    PermissionStatus currentStatus = await Permission.locationWhenInUse.status;
    
    if (currentStatus.isGranted) {
      // Permission already granted, proceed directly
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        // Update cache
        _cachedPosition = position;
        _lastPositionTime = DateTime.now();
        
        return position;
      } catch (e, s) {
        developer.log('Error getting location: $e', name: 'LocationService', error: e, stackTrace: s);
        throw Exception('Failed to get current location: ${e.toString()}');
      }
    }
    
    // Need to request permission
    if (_isRequestingPermission) {
      // Wait for the existing request to complete
      throw Exception('A location permission request is already in progress');
    }
    
    try {
      _isRequestingPermission = true;
      PermissionStatus status = await Permission.locationWhenInUse.request();
      
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          developer.log('Location permission permanently denied.', name: 'LocationService');
        } else {
          developer.log('Location permission denied.', name: 'LocationService');
        }
        throw Exception('Location permission not granted. Status: $status');
      }
      
      // Permission granted, get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Update cache
      _cachedPosition = position;
      _lastPositionTime = DateTime.now();
      
      return position;
    } catch (e, s) {
      developer.log('Error in permission or location: $e', name: 'LocationService', error: e, stackTrace: s);
      throw Exception('Failed to get current location: ${e.toString()}');
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Construct a more readable address
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
        
        return addressParts.where((part) => part.isNotEmpty).join(', ');
      }
    } catch (e, s) {
      developer.log('Error getting address: $e', name: 'LocationService', error: e, stackTrace: s);
    }
    return "Address details not found";
  }
  
  /// Fetches issues within a specified radius of the user's current location
  /// 
  /// [radiusKm]: The radius in kilometers (defaults to 10km)
  /// [query]: Optional Firestore query to filter issues further
  /// 
  /// Returns a list of issues within the specified radius
  Future<List<Issue>> getIssuesWithinRadius({double radiusKm = defaultProximityRadiusKm, Query? query}) async {
    try {
      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        throw Exception('Could not determine current location');
      }
      
      // Fetch all issues (or filtered by query)
      final baseQuery = query ?? FirebaseFirestore.instance.collection('issues');
      final snapshot = await baseQuery.get();
      
      // Filter issues by distance
      final List<Issue> nearbyIssues = [];
      for (final doc in snapshot.docs) {
        final issue = Issue.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        
        // Check if issue is within radius
        final isNearby = LocationUtils.isLocationWithinRadius(
          position.latitude,
          position.longitude,
          issue.location.latitude,
          issue.location.longitude,
          radiusKm
        );
        
        if (isNearby) {
          nearbyIssues.add(issue);
        }
      }
      
      return nearbyIssues;
    } catch (e, s) {
      developer.log('Error fetching nearby issues: $e', name: 'LocationService', error: e, stackTrace: s);
      throw Exception('Failed to fetch nearby issues: ${e.toString()}');
    }
  }
  
  /// Fetches issues within a specified radius of a given location
  /// 
  /// [latitude], [longitude]: The coordinates of the center point
  /// [radiusKm]: The radius in kilometers
  /// [query]: Optional Firestore query to filter issues further
  /// 
  /// Returns a list of issues within the specified radius
  Future<List<Issue>> getIssuesWithinRadiusOfLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    Query? query
  }) async {
    try {
      // Fetch all issues (or filtered by query)
      final baseQuery = query ?? FirebaseFirestore.instance.collection('issues');
      final snapshot = await baseQuery.get();
      
      // Filter issues by distance
      final List<Issue> nearbyIssues = [];
      for (final doc in snapshot.docs) {
        final issue = Issue.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        
        // Check if issue is within radius
        final isNearby = LocationUtils.isLocationWithinRadius(
          latitude,
          longitude,
          issue.location.latitude,
          issue.location.longitude,
          radiusKm
        );
        
        if (isNearby) {
          nearbyIssues.add(issue);
        }
      }
      
      return nearbyIssues;
    } catch (e, s) {
      developer.log('Error fetching nearby issues: $e', name: 'LocationService', error: e, stackTrace: s);
      throw Exception('Failed to fetch nearby issues: ${e.toString()}');
    }
  }
}
