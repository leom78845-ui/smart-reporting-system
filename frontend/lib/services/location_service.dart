import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Ensures permissions + services are enabled before fetching location
  static Future<bool> ensurePermissions() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission state
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Fetches the current position safely
  static Future<Position> getCurrentPosition() async {
    final allowed = await ensurePermissions();
    if (!allowed) {
      throw Exception("Location permission denied or disabled.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Opens device settings if permission is permanently denied
  static Future<void> openSettings() async {
    await Geolocator.openAppSettings();
    await Geolocator.openLocationSettings();
  }
}
