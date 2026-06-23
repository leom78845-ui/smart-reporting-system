// lib/screens/drafts_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_queue.dart';
import '../services/api_service.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    try {
      final data = await OfflineQueue.getQueuedReports();
      setState(() => _drafts = data);
    } catch (_) {
      setState(() => _drafts = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDraft(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Delete Draft", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to permanently delete this offline draft?",
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
      await OfflineQueue.deleteReport(id);
      _loadDrafts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Draft deleted successfully")),
        );
      }
    }
  }

  Future<void> _submitDraft(Map<String, dynamic> draft) async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No internet connection detected. Please try again later.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final filePath = draft['file_path'] as String?;
      if (filePath == null || filePath.isEmpty) {
        throw Exception("Media file path is missing in this draft.");
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("The media file for this draft could not be found on your device.");
      }

      // 1. Upload media
      final mediaUrl = await ApiService.uploadMedia(file);
      if (mediaUrl == null) {
        throw Exception("Failed to upload media. Server might be busy.");
      }

      // 2. Submit report
      final success = await ApiService.submitReport(
        title: draft['title'] ?? "Untitled",
        description: draft['description'] ?? "",
        latitude: (draft['latitude'] as num).toDouble(),
        longitude: (draft['longitude'] as num).toDouble(),
        mediaUrl: mediaUrl,
        mediaType: draft['media_type'] ?? "image",
      );

      if (success) {
        // 3. Delete from offline queue
        await OfflineQueue.deleteReport(draft['id'] as int);
        _loadDrafts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Draft submitted successfully!")),
          );
        }
      } else {
        throw Exception("Submission failed. Server rejected the report.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting draft: $e")),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Offline Drafts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrafts,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF121212),
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : _drafts.isEmpty
                    ? const Center(
                        child: Text(
                          "No offline drafts saved.",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drafts.length,
                        itemBuilder: (context, i) {
                          final draft = _drafts[i];
                          final file = File(draft['file_path'] ?? "");

                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail/Icon
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: file.existsSync()
                                              ? Image.file(
                                                  file,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white38,
                                                  ),
                                                )
                                              : Icon(
                                                  draft['media_type'] == 'video'
                                                      ? Icons.videocam
                                                      : Icons.image,
                                                  color: Colors.white54,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              draft['title'] ?? 'Untitled Draft',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              draft['description'] ?? 'No description provided.',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Coordinates display
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Lat: ${(draft['latitude'] as num?)?.toStringAsFixed(5) ?? 'N/A'}, Lng: ${(draft['longitude'] as num?)?.toStringAsFixed(5) ?? 'N/A'}",
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white10, height: 1),
                                  const SizedBox(height: 12),
                                  // Actions Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Delete button
                                      TextButton.icon(
                                        onPressed: () => _deleteDraft(draft['id'] as int),
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                      ),
                                      const SizedBox(width: 10),
                                      // Submit button
                                      ElevatedButton.icon(
                                        onPressed: () => _submitDraft(draft),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade900,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                                        label: const Text("Submit", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            if (_isSubmitting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    color: Colors.black87,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            "Submitting draft...",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
