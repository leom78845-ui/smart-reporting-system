// lib/screens/map_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();
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
        point: LatLng(loc.latitude, loc.longitude),
        width: 100,
        height: 60,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.name)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Icon(CampusMapManager.getIconForLocation(loc.name), color: Colors.white, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
                child: Text(
                  loc.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    setState(() {
      _campusMarkers.clear();
      _campusMarkers.addAll(markers);
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 16,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(_cameraSwBound, _cameraNeBound),
              ),
              minZoom: 14.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite 
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartreporting.hu',
              ),
              MarkerLayer(
                markers: [
                  ..._campusMarkers,
                  Marker(
                    point: _selectedPoint,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
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
