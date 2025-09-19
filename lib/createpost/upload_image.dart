import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UploadImageService {
  final ImagePicker _picker = ImagePicker();

  /// Upload ảnh từ gallery
  Future<File?> uploadFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
