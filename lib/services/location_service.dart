/// Coordinates for location queries.
class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  final double latitude;
  final double longitude;
  final String cityName;

  /// Default fallback location (Chicago, IL).
  static const defaultLocation = LocationCoordinates(
    latitude: 41.8781,
    longitude: -87.6298,
    cityName: 'Chicago, IL (Default)',
  );
}

/// Service managing location access and default city fallbacks.
class LocationService {
  /// Fetches current location coordinates or returns [LocationCoordinates.defaultLocation]
  /// if permission is denied or device location is unavailable.
  Future<LocationCoordinates> getCurrentLocation({
    String? manualCityOverride,
  }) async {
    if (manualCityOverride != null && manualCityOverride.isNotEmpty) {
      return LocationCoordinates(
        latitude: 41.8781,
        longitude: -87.6298,
        cityName: '$manualCityOverride (Manual)',
      );
    }

    // Returns standard default coordinates when geolocator is disabled/denied.
    return LocationCoordinates.defaultLocation;
  }
}
