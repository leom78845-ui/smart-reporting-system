import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'map_verification_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedFilePath;
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // UPDATED: Dialog to choose between real-time Photo or Video
  Future<void> _captureMedia() async {
    final ImagePicker picker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Capture Media"),
        content: const Text("Capture real-time data for your report:"),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final XFile? photo = await picker.pickImage(source: ImageSource.camera);
              if (photo != null) setState(() => _selectedFilePath = photo.path);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Photo"),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final XFile? video = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
              if (video != null) setState(() => _selectedFilePath = video.path);
            },
            icon: const Icon(Icons.videocam),
            label: const Text("Video"),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    }
  }

  Future<void> _openMapVerification() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please capture media first!")));
      return;
    }
    
    await _getCurrentLocation();
    if (!mounted) return;

    final bool? confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => MapVerificationScreen(lat: _lat, lng: _lng)),
    );

    if (confirmed == true) await _submit();
  }

  Future<void> _submit() async {
    if (_selectedFilePath == null) return;
    setState(() => _isSubmitting = true);

    bool success = await ApiService.submitReport(
      title: _titleController.text,
      description: _descriptionController.text,
      latitude: _lat,
      longitude: _lng,
      filePath: _selectedFilePath!,
      mediaType: _selectedFilePath!.endsWith('.mp4') ? 'video' : 'image',
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Submitted!")));
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedFilePath = null);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submission Failed.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Report"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 20),
            
            if (_selectedFilePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_selectedFilePath!.endsWith('.mp4') ? "Video Captured" : "Image Captured", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),

            ElevatedButton.icon(
              onPressed: _captureMedia, 
              icon: const Icon(Icons.camera_enhance),
              label: Text(_selectedFilePath == null ? "Capture Media" : "Retake Media")
            ),
            const SizedBox(height: 20),
            
            _isSubmitting
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _openMapVerification,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Verify Location & Submit")
                ),
          ],
        ),
      ),
    );
  }
}