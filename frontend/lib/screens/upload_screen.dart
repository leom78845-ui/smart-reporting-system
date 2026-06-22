// lib/screens/upload_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/offline_queue.dart';
import '../managers/auth_manager.dart';
import 'map_verification_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _selectedFile;
  String? _mediaType;
  bool _isLoading = false;

  int _pendingCount = 0;
  int _reviewingCount = 0;
  int _resolvedCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final stats = await ApiService.getMyReportStats();
      if (mounted) {
        setState(() {
          _pendingCount = stats['pending'] ?? 0;
          _reviewingCount = stats['reviewing'] ?? 0;
          _resolvedCount = stats['resolved'] ?? 0;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _pickMedia(String type) async {
    final picker = ImagePicker();
    XFile? picked;

    if (type == "image") {
      picked = await picker.pickImage(source: ImageSource.camera);
    } else {
      picked = await picker.pickVideo(source: ImageSource.camera);
    }

    if (picked != null) {
      setState(() {
        _selectedFile = File(picked!.path);
        _mediaType = type;
      });
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty || description.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and attach media")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current location from geolocator
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Open Map Verification Screen to let student double check the pin location
      setState(() => _isLoading = false);
      if (!mounted) return;
      final LatLng? verifiedLoc = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (_) => MapVerificationScreen(
            lat: pos.latitude,
            lng: pos.longitude,
          ),
        ),
      );

      if (verifiedLoc == null) {
        // User cancelled location verification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location verification is required.")),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Try uploading media locally
      final mediaUrl = await ApiService.uploadMedia(_selectedFile!);

      bool success = false;
      if (mediaUrl != null) {
        // Submit online
        success = await ApiService.submitReport(
          title: title,
          description: description,
          latitude: verifiedLoc.latitude,
          longitude: verifiedLoc.longitude,
          mediaUrl: mediaUrl,
          mediaType: _mediaType ?? "image",
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted successfully")),
        );
        _clearForm();
        _loadStats();
      } else {
        // Save offline draft using verified coordinates
        await OfflineQueue.queueReport({
          "title": title,
          "description": description,
          "latitude": verifiedLoc.latitude,
          "longitude": verifiedLoc.longitude,
          "file_path": _selectedFile!.path,
          "media_type": _mediaType ?? "image",
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No internet. Report saved offline.")),
        );
        _clearForm();
        _loadStats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedFile = null;
      _mediaType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hazara University Student",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
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
                  color: Colors.blue.shade900,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/hu_logo.png',
                      height: 60,
                      width: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            auth.user?['name'] ?? "Student Dashboard",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            auth.user?['roll_number'] ?? "Student",
                            style: const TextStyle(
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
                leading: const Icon(Icons.history, color: Colors.blueAccent),
                title: const Text(
                  "My Reports",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: const Text(
                  "Track your reports & drafts",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/myReports').then((_) => _loadStats());
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.amberAccent),
                title: const Text(
                  "Change Password",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/changePassword');
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
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/hu_gate.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // 3. Content
          RefreshIndicator(
            onRefresh: _loadStats,
            color: Colors.blue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Pending",
                          count: _pendingCount,
                          color: Colors.orangeAccent,
                          icon: Icons.hourglass_empty,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: "Reviewing",
                          count: _reviewingCount,
                          color: Colors.blueAccent,
                          icon: Icons.rate_review,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: "Resolved",
                          count: _resolvedCount,
                          color: Colors.greenAccent,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Submit A New Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Glassmorphic Upload Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Title",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Description",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _selectedFile == null
                                ? Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.white60),
                                          SizedBox(height: 8),
                                          Text(
                                            "No media captured yet",
                                            style: TextStyle(color: Colors.white60, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _mediaType == "image"
                                          ? Image.file(_selectedFile!, fit: BoxFit.cover)
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.video_library, size: 45, color: Colors.blueAccent),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "Video Captured",
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickMedia("image"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.12),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                      ),
                                    ),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text("Photo", style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickMedia("video"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.12),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                      ),
                                    ),
                                    icon: const Icon(Icons.videocam, size: 18),
                                    label: const Text("Video", style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.blue, Colors.blueAccent],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _submitReport,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Verify Location & Submit",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          _statsLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
