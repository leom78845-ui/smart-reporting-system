// lib/managers/campus_map_manager.dart
import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';

class CampusMapManager {
  // Coordinates for Hazara University
  static final LatLng universityCenter = LatLng(34.4690, 73.2392);

  // Default zoom
  static const double defaultZoom = 16.0;

  static Future<List<CampusLocation>> fetchUniversityLocations() async {
    // Return mock data for now
    return [
      CampusLocation(name: "Library", lat: 34.4695, lng: 73.2395),
      CampusLocation(name: "Admin Block", lat: 34.4700, lng: 73.2400),
    ];
  }
}