// lib/screens/admin_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../managers/auth_manager.dart';
import '../managers/campus_map_manager.dart';
import 'package:url_launcher/url_launcher.dart';


class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  GoogleMapController? _mapController;

  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _showSheet = false;
  String _statusFilter = 'all';
  bool _isSatellite = true;




  final Set<Marker> _campusMarkers = {};
  final Set<Marker> _reportMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadCampusLocationMarkers() async {
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
          final reportId = r['id'].toString();
          return Marker(
            markerId: MarkerId('report_$reportId'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onTap: () => _showReportBottomSheet(r),
          );
        }).toList();

        setState(() {
          _reports = filtered;
          _reportMarkers.clear();
          _reportMarkers.addAll(markers);
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

  void _showReportBottomSheet(Map<String, dynamic> r) {
    String currentStatus = r['status'] ?? 'pending';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r['title'] ?? 'Report',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Submitted by: ${r['student_name'] ?? 'Unknown'} (${r['student_roll_number'] ?? 'Unknown'})",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Submitted At: ${_formatTimestamp(r['submitted_at'])}",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (r['media_captured_at'] != null && r['media_captured_at'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Media Recorded: ${_formatTimestamp(r['media_captured_at'])}",
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  "Description:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  r['description'] ?? 'No description',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                if (r['image_url'] != null && r['image_url'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Attached File:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildMediaPreview(r['image_url'].toString()),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text("Delete Report", style: TextStyle(color: Colors.white)),
                          content: const Text(
                            "Are you sure you want to delete this report permanently?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success = await ApiService.deleteReport(r['id'] as int);
                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Report deleted successfully")),
                            );
                            _loadReports();
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to delete report")),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      "Delete Report",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchVideo(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening video: $e")),
        );
      }
    }
  }

  Widget _buildMediaPreview(String url) {
    final lowerUrl = url.toLowerCase();
    final isVideo = lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.3gp');

    if (isVideo) {
      return GestureDetector(
        onTap: () => _launchVideo(url),
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text("Tap to Play Video", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }
 else {
      return GestureDetector(
        onTap: () => _showFullImage(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 100,
              color: Colors.grey.shade800,
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54),
                    SizedBox(width: 8),
                    Text("Error loading image", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 180,
                color: Colors.grey.shade900,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      );
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: CampusMapManager.universityCenter,
              zoom: CampusMapManager.defaultZoom,
            ),
            mapType: _isSatellite ? MapType.hybrid : MapType.normal,
            onMapCreated: (controller) => _mapController = controller,
            minMaxZoomPreference: const MinMaxZoomPreference(2.0, 18.0),
            mapToolbarEnabled: false,
            markers: _reportMarkers,
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
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17.0),
                              );
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

  String _formatTimestamp(dynamic timestampStr) {
    if (timestampStr == null) return "N/A";
    try {
      final dt = DateTime.parse(timestampStr.toString()).toLocal();
      final year = dt.year;
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$year-$month-$day $hour:$minute";
    } catch (_) {
      return timestampStr.toString();
    }
  }
}
