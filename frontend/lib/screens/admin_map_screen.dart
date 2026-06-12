import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../managers/campus_map_manager.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isSatellite = false;
  bool _showSheet = false;

  final MapController _mapController = MapController();

  final LatLngBounds _hazaraBounds = LatLngBounds(
    const LatLng(34.4155, 73.2435), // South-West
    const LatLng(34.4244, 73.2565), // North-East
  );

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ApiService.getAllReports();
      if (mounted) setState(() => _reports = reports);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hazara University Map")),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(34.4200, 73.2500),
                initialZoom: 16.5,
                cameraConstraint: CameraConstraint.contain(bounds: _hazaraBounds),
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite 
                      ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}' 
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smart.reporting.app',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
            _buildControls(),
            if (_showSheet) _buildSheet(constraints),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "sat_btn",
            mini: true,
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
            child: Icon(_isSatellite ? Icons.map : Icons.satellite),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "list_btn",
            onPressed: () => setState(() => _showSheet = !_showSheet),
            icon: const Icon(Icons.list),
            label: Text("${_reports.length} Reports"),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(BoxConstraints constraints) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, controller) => Container(
        color: Colors.white,
        child: ListView.builder(
          controller: controller,
          itemCount: _reports.length,
          itemBuilder: (context, i) {
            final report = _reports[i];
            return ListTile(
              title: Text(report['title'] ?? 'Report'),
              onTap: () {
                final lat = double.tryParse(report['latitude'].toString()) ?? 0.0;
                final lng = double.tryParse(report['longitude'].toString()) ?? 0.0;
                _mapController.move(LatLng(lat, lng), 17.0);
              },
            );
          },
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _reports
        .where((r) => r['latitude'] != null)
        .map((r) => Marker(
            point: LatLng(double.parse(r['latitude'].toString()), double.parse(r['longitude'].toString())),
            child: const Icon(Icons.location_on, color: Colors.red)))
        .toList();
  }
}