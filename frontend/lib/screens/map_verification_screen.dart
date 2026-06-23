// lib/screens/map_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../managers/campus_map_manager.dart';

class MapVerificationScreen extends StatefulWidget {
  final double lat;
  final double lng;

  const MapVerificationScreen({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  State<MapVerificationScreen> createState() => _MapVerificationScreenState();
}

class _MapVerificationScreenState extends State<MapVerificationScreen> {
  bool _isSatellite = true;

  // Hazara University boundary bounds
  static const LatLng _swBound = LatLng(34.4155, 73.2435);
  static const LatLng _neBound = LatLng(34.4244, 73.2565);

  // Wider bounds for camera constraint to avoid breaking zoom at minZoom
  static const LatLng _cameraSwBound = LatLng(34.4000, 73.2300);
  static const LatLng _cameraNeBound = LatLng(34.4300, 73.2700);

  late LatLng _selectedPoint;
  final List<Marker> _campusMarkers = [];

  bool _isInsideBounds(LatLng point) {
    return point.latitude >= _swBound.latitude &&
        point.latitude <= _neBound.latitude &&
        point.longitude >= _swBound.longitude &&
        point.longitude <= _neBound.longitude;
  }

  @override
  void initState() {
    super.initState();

    final initialPoint = LatLng(widget.lat, widget.lng);
    _selectedPoint = _isInsideBounds(initialPoint)
        ? initialPoint
        : CampusMapManager.universityCenter;

    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final locs = await CampusMapManager.fetchUniversityLocations();
    if (!mounted) return;

    final markers = locs.map((loc) {
      return Marker(
        markerId: MarkerId(loc.name),
        position: LatLng(loc.latitude, loc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: loc.name),
      );
    }).toList();

    setState(() {
      _campusMarkers.clear();
      _campusMarkers.addAll(markers);
    });
  }

  void _onMapTap(LatLng point) {
    if (_isInsideBounds(point)) {
      setState(() {
        _selectedPoint = point;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid location. You must stay inside Hazara University."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verify Location"),
            Text(
              "Hazara University Bounds Only",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPoint,
              zoom: 16.0,
            ),
            mapType: _isSatellite ? MapType.hybrid : MapType.normal,
            onTap: _onMapTap,
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: _cameraSwBound,
                northeast: _cameraNeBound,
              ),
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(14.0, 18.0),
            markers: {
              ..._campusMarkers,
              Marker(
                markerId: const MarkerId('selected_point'),
                position: _selectedPoint,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
          ),

          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "verify_satellite_btn",
              backgroundColor: Colors.white,
              child: Icon(
                _isSatellite ? Icons.map : Icons.satellite,
                color: Colors.green,
              ),
              onPressed: () {
                setState(() {
                  _isSatellite = !_isSatellite;
                });
              },
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, _selectedPoint);
              },
              icon: const Icon(Icons.check),
              label: const Text("Confirm Location"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
