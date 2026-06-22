// lib/models/campus_location.dart

import 'package:latlong2/latlong.dart';

class CampusLocation {
  final String name;
  final double latitude;
  final double longitude;

  CampusLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // Convert to LatLng for Google Maps markers
  LatLng toLatLng() => LatLng(latitude, longitude);

  // ---------------------------------------------------------------------------
  // JSON HELPERS
  // ---------------------------------------------------------------------------
  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      name: json['name'] ?? 'Unknown',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
