import 'package:image_picker/image_picker.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> captureMedia({required bool isVideo}) async {
    return isVideo
        ? await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30))
        : await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
  }
}