// lib/managers/campus_map_manager.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';

class CampusMapManager {
  // ---------------------------------------------------------------------------
  // DEFAULT MAP SETTINGS
  // ---------------------------------------------------------------------------
  static const LatLng universityCenter = LatLng(34.4200, 73.2505); // Hazara Uni
  static const double defaultZoom = 15.0;

  // ---------------------------------------------------------------------------
  // FETCH LOCATIONS (FROM BACKEND OR FALLBACK)
  // ---------------------------------------------------------------------------
  static Future<List<CampusLocation>> fetchUniversityLocations() async {
    try {
      // TODO: Replace with ApiService call if Django provides campus locations
      // final data = await ApiService.authorizedGet("/campus/locations/");
      // return data.map((e) => CampusLocation.fromJson(e)).toList();

      // For now, return fallback
      return _fallbackLocations();
    } catch (_) {
      return _fallbackLocations();
    }
  }

  static IconData getIconForLocation(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ground') || lower.contains('gym')) return Icons.sports_soccer;
    if (lower.contains('library')) return Icons.local_library;
    if (lower.contains('hostel') || lower.contains('guest house') || lower.contains('hall')) return Icons.hotel;
    if (lower.contains('cafeteria')) return Icons.restaurant;
    if (lower.contains('department') || lower.contains('science') || lower.contains('physics') || lower.contains('law') || lower.contains('economics') || lower.contains('media')) return Icons.school;
    if (lower.contains('garden')) return Icons.park;
    if (lower.contains('transport') || lower.contains('motor way')) return Icons.directions_bus;
    if (lower.contains('mosque')) return Icons.mosque;
    if (lower.contains('finance')) return Icons.attach_money;
    if (lower.contains('senate')) return Icons.account_balance;
    return Icons.business;
  }

  // ---------------------------------------------------------------------------
  // FALLBACK LOCATIONS
  // ---------------------------------------------------------------------------
  static List<CampusLocation> _fallbackLocations() {
    return [
      CampusLocation(
        name: "Department of English & Psychology 7 Block",
        latitude: 34.4192014,
        longitude: 73.2527837,
      ),
      CampusLocation(
        name: "Department of Pharmacy 6 Block",
        latitude: 34.4192014,
        longitude: 73.2527837,
      ),
      CampusLocation(
        name: "Department Of CS& IT 8 Block",
        latitude: 34.4192014,
        longitude: 73.2527837,
      ),
      CampusLocation(
        name: "Department of DPT & microbiology 9 Block",
        latitude: 34.419938,
        longitude: 73.252591,
      ),
      CampusLocation(
        name: "Department Of Botany 1 Block",
        latitude: 34.418057,
        longitude: 73.253104,
      ),
      CampusLocation(
        name: "Department of Management Sciences 4 Block",
        latitude: 34.418762,
        longitude: 73.2520293,
      ),
      CampusLocation(
        name: "Directorate Of IT 3 Block",
        latitude: 34.418742,
        longitude: 73.252147,
      ),
      CampusLocation(
        name: "Department of Public & Ad & dep Of Articeture 2 block",
        latitude: 34.418762,
        longitude: 73.2520293,
      ),
      CampusLocation(
        name: "Museum Of Hazara University",
        latitude: 34.419854,
        longitude: 73.2508801,
      ),
      CampusLocation(
        name: "Vice Chancellor Secretariat",
        latitude: 34.419878,
        longitude: 73.2511397,
      ),
      CampusLocation(
        name: "Administration Block",
        latitude: 34.419878,
        longitude: 73.2511397,
      ),
      CampusLocation(
        name: "Blue Area",
        latitude: 34.4189854,
        longitude: 73.2516976,
      ),
      CampusLocation(
        name: "Motor way Gate",
        latitude: 34.419369,
        longitude: 73.254856,
      ),
      CampusLocation(
        name: "Department of Physics & Biotechnology,genetic engineering",
        latitude: 34.4175338,
        longitude: 73.2514501,
      ),
      CampusLocation(
        name: "Law Department",
        latitude: 34.4171507,
        longitude: 73.250995,
      ),
      CampusLocation(
        name: "Transport",
        latitude: 34.4180643,
        longitude: 73.2497402,
      ),
      CampusLocation(
        name: "University GYM",
        latitude: 34.418154,
        longitude: 73.249215,
      ),
      CampusLocation(
        name: "Press and Publication Centre",
        latitude: 34.4187529,
        longitude: 73.2488299,
      ),
      CampusLocation(
        name: "Jinnah hall",
        latitude: 34.4188988,
        longitude: 73.2488483,
      ),
      CampusLocation(
        name: "Department of Media and Communication Studies",
        latitude: 34.4188684,
        longitude: 73.2483987,
      ),
      CampusLocation(
        name: "Department of Economics",
        latitude: 34.4188684,
        longitude: 73.2483987,
      ),
      CampusLocation(
        name: "Central Library Hazara University",
        latitude: 34.4188684,
        longitude: 73.2483987,
      ),
      CampusLocation(
        name: "2nd Gate Hazara University",
        latitude: 34.4193685,
        longitude: 73.2479399,
      ),
      CampusLocation(
        name: "Boys Hostel",
        latitude: 34.4200266,
        longitude: 73.24801,
      ),
      CampusLocation(
        name: "Walnut Garden",
        latitude: 34.4200266,
        longitude: 73.24801,
      ),
      CampusLocation(
        name: "Cafeteria",
        latitude: 34.4198032,
        longitude: 73.2482311,
      ),
      CampusLocation(
        name: "Football Ground",
        latitude: 34.4196679,
        longitude: 73.2490842,
      ),
      CampusLocation(
        name: "VC Secretariat Rd",
        latitude: 34.419936,
        longitude: 73.250632,
      ),
      CampusLocation(
        name: "Cricket Ground",
        latitude: 34.4206232,
        longitude: 73.2496645,
      ),
      CampusLocation(
        name: "Jasmine Garden",
        latitude: 34.4217073,
        longitude: 73.2494044,
      ),
      CampusLocation(
        name: "Siran Guest House",
        latitude: 34.4217073,
        longitude: 73.2494044,
      ),
      CampusLocation(
        name: "Welcome Garden",
        latitude: 34.4225481,
        longitude: 73.2482027,
      ),
      CampusLocation(
        name: "Senate Hall",
        latitude: 34.422800,
        longitude: 73.246000,
      ),
      CampusLocation(
        name: "HU Mosque",
        latitude: 34.422200,
        longitude: 73.246500,
      ),
      CampusLocation(
        name: "Finance",
        latitude: 34.421500,
        longitude: 73.251500,
      ),
      CampusLocation(
        name: "Zoology",
        latitude: 34.418000,
        longitude: 73.248300,
      ),
      CampusLocation(
        name: "Urdu",
        latitude: 34.417800,
        longitude: 73.248000,
      ),
      CampusLocation(
        name: "Faculty Hostel",
        latitude: 34.416500,
        longitude: 73.249200,
      ),
    ];
  }
}
