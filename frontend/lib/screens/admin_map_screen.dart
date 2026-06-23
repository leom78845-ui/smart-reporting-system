// lib/screens/admin_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../managers/auth_manager.dart';
import '../managers/campus_map_manager.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();

  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _showSheet = false;
  String _statusFilter = 'all';
  bool _isSatellite = false;

  // Hazara University boundary
  static const LatLng _swBound = LatLng(34.4155, 73.2435);
  static const LatLng _neBound = LatLng(34.4244, 73.2565);

  // Wider bounds for camera constraint to avoid breaking zoom at minZoom
  static const LatLng _cameraSwBound = LatLng(34.4000, 73.2300);
  static const LatLng _cameraNeBound = LatLng(34.4300, 73.2700);

  final List<Marker> _markers = [];
  final List<Marker> _campusMarkers = [];
  final List<Marker> _reportMarkers = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
    _loadCampusLocationMarkers();
  }

  Future<void> _loadCampusLocationMarkers() async {
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
      _updateAllMarkers();
    });
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getAllReports();
      if (mounted) {
        final filtered = data.where((r) {
          if (r['location'] == null) return false;
          final loc = r['location'];
          if (loc['latitude'] == null || loc['longitude'] == null) return false;
          final lat = double.tryParse(loc['latitude'].toString());
          final lng = double.tryParse(loc['longitude'].toString());
          return lat != null && lng != null;
        }).toList();

        // Build report markers
        final markers = filtered.map((r) {
          final loc = r['location']!;
          final lat = double.parse(loc['latitude'].toString());
          final lng = double.parse(loc['longitude'].toString());
          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showReportBottomSheet(r),
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          );
        }).toList();

        setState(() {
          _reports = filtered;
          _reportMarkers.clear();
          _reportMarkers.addAll(markers);
          _updateAllMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading reports: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateAllMarkers() {
    _markers.clear();
    _markers.addAll(_campusMarkers);
    _markers.addAll(_reportMarkers);
  }

  void _showReportBottomSheet(Map<String, dynamic> r) {
    String currentStatus = r['status'] ?? 'pending';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r['title'] ?? 'Report',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(r['description'] ?? 'No description'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: currentStatus,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'reviewing', child: Text('Reviewing')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (val) async {
                      if (val != null && val != currentStatus) {
                        final success = await ApiService.updateReportStatus(r['id'] as int, val);
                        if (success) {
                          setBottomSheetState(() {
                            currentStatus = val;
                            r['status'] = val;
                          });
                          _loadReports();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Status updated to $val")),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to update status.")),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hazara University Admin",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      endDrawer: Drawer(
        child: Container(
          color: Colors.grey.shade900,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/hu_logo.png',
                      height: 60,
                      width: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.admin_panel_settings,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Admin Panel",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Hazara University",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.orangeAccent),
                title: const Text(
                  "Requests",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  "Pending, approved & resolved list",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _showSheet = true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
                title: const Text(
                  "Create User",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  "Add a new student user",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/createStudents');
                },
              ),
              const Spacer(),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await auth.logout();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: CampusMapManager.universityCenter,
              initialZoom: CampusMapManager.defaultZoom,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              minZoom: 2.0,
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
                markers: _markers,
              ),
            ],
          ),

          _buildControls(),

          if (_showSheet) _buildSheet(),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: FloatingActionButton(
        heroTag: "satellite_btn",
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
    );
  }

  Widget _buildSheet() {
    final filteredReports = _reports.where((r) {
      if (_statusFilter == 'all') return true;
      return (r['status'] as String?)?.toLowerCase() == _statusFilter;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Submitted Reports",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() => _showSheet = false),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${_reports.length})'),
                  _buildFilterChip('pending', 'Pending (${_reports.where((r) => r['status'] == 'pending').length})'),
                  _buildFilterChip('reviewing', 'Reviewing (${_reports.where((r) => r['status'] == 'reviewing').length})'),
                  _buildFilterChip('resolved', 'Resolved (${_reports.where((r) => r['status'] == 'resolved').length})'),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        "No $_statusFilter reports found.",
                        style: const TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: filteredReports.length,
                      itemBuilder: (context, i) {
                        final report = filteredReports[i];
                        final statusColor = _getStatusColor(report['status']);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.2),
                            child: Icon(Icons.warning_amber_rounded, color: statusColor),
                          ),
                          title: Text(
                            report['title'] ?? 'Report',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Status: ${report['status']}",
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                             final loc = report['location'];
                             final lat = loc != null ? (double.tryParse(loc['latitude'].toString()) ?? 0.0) : 0.0;
                             final lng = loc != null ? (double.tryParse(loc['longitude'].toString()) ?? 0.0) : 0.0;
                             _mapController.move(LatLng(lat, lng), 17.0);
                             setState(() => _showSheet = false);
                             _showReportBottomSheet(report);
                           },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _statusFilter = value;
            });
          }
        },
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'reviewing':
        return Colors.blueAccent;
      case 'resolved':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}
