import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Ensures camera permission is granted before capturing media
  static Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Capture photo or video using the device camera ONLY
  static Future<XFile?> captureMedia({required bool isVideo}) async {
    final allowed = await ensureCameraPermission();
    if (!allowed) {
      throw Exception("Camera permission denied.");
    }

    return isVideo
        ? await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 30),
          )
        : await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
  }
}
