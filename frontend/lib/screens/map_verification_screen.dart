import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapVerificationScreen extends StatelessWidget {
  final double lat;
  final double lng;

  const MapVerificationScreen({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Location")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng), 
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Required in newer versions
                  userAgentPackageName: 'com.smart.reporting.system', 
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  )
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm Location & Submit"),
            ),
          )
        ],
      ),
    );
  }
}