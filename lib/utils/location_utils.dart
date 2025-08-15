import 'dart:math' as math;

class LocationUtils {
  /// Calculates the distance between two geographic coordinates using the Haversine formula.
  /// 
  /// [lat1], [lon1]: Latitude and longitude of the first point in decimal degrees
  /// [lat2], [lon2]: Latitude and longitude of the second point in decimal degrees
  /// 
  /// Returns the distance in kilometers
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    // Convert degrees to radians
    final double lat1Rad = _degreesToRadians(lat1);
    final double lon1Rad = _degreesToRadians(lon1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double lon2Rad = _degreesToRadians(lon2);
    
    // Haversine formula
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    
    final double a = math.pow(math.sin(dLat / 2), 2) + 
                     math.cos(lat1Rad) * math.cos(lat2Rad) * 
                     math.pow(math.sin(dLon / 2), 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }
  
  /// Converts degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  /// Checks if a location is within a specified radius of another location
  /// 
  /// [lat1], [lon1]: Latitude and longitude of the center point
  /// [lat2], [lon2]: Latitude and longitude of the point to check
  /// [radiusKm]: The radius in kilometers
  /// 
  /// Returns true if the second point is within the radius of the first point
  static bool isLocationWithinRadius(double lat1, double lon1, double lat2, double lon2, double radiusKm) {
    final double distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }
}