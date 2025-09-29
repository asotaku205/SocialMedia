// Import thư viện để làm việc với files
import 'dart:io';
import 'dart:typed_data';
// Import package image_picker để chọn ảnh từ gallery hoặc camera
import 'package:image_picker/image_picker.dart';
// Import Firebase Storage để upload ảnh
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Class UploadImageService - quản lý việc upload và chọn ảnh
class UploadImageService {
  // Khởi tạo instance của ImagePicker để sử dụng trong class
  final ImagePicker _picker = ImagePicker();
  // Khởi tạo Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Method để upload ảnh từ gallery của thiết bị
  /// Trả về Future<File?> - File nếu chọn ảnh thành công, null nếu hủy
  Future<File?> uploadFromGallery() async {
    try {
      print('Starting image picker from gallery...');

      // Mở gallery để user chọn ảnh
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      // Kiểm tra xem user có chọn ảnh hay không
      if (pickedFile != null) {
        print('Image picked successfully: ${pickedFile.path}');

        // Kiểm tra file có tồn tại không trước khi tạo File object
        if (await File(pickedFile.path).exists()) {
          return File(pickedFile.path);
        } else {
          throw Exception('File không tồn tại tại đường dẫn: ${pickedFile.path}');
        }
      }

      print('No image selected by user');
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Lỗi khi chọn ảnh từ thư viện: $e');
    }
  }

  /// Method để upload ảnh lên Firebase Storage
  /// Trả về Future<String> - URL của ảnh nếu upload thành công
  Future<String> uploadImage(File imageFile) async {
    try {
      // Kiểm tra file có tồn tại không
      if (!await imageFile.exists()) {
        throw Exception('File ảnh không tồn tại');
      }

      // Lấy user hiện tại
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User chưa đăng nhập');
      }

      print('Starting image upload for user: ${user.uid}');
      print('File size: ${await imageFile.length()} bytes');

      // Tạo tên file unique bằng timestamp
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Tạo reference đến vị trí lưu file trong Storage
      final storageRef = _storage.ref().child('profile_images/$fileName');

      print('Uploading to Firebase Storage path: profile_images/$fileName');

      // Đọc file thành bytes để tránh Platform dependency issues
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Upload bytes thay vì File để tránh Platform conflicts
      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': fileName,
          },
        ),
      );

      print('Upload completed successfully');

      // Lấy URL download của file đã upload
      final downloadURL = await uploadTask.ref.getDownloadURL();

      print('Download URL obtained: $downloadURL');
      return downloadURL;

    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Lỗi khi upload ảnh: ${e.toString()}');
    }
  }

  /// Method để upload ảnh từ camera
  Future<File?> uploadFromCamera() async {
    try {
      print('Starting image picker from camera...');

      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('Image captured successfully: ${pickedFile.path}');

        if (await File(pickedFile.path).exists()) {
          return File(pickedFile.path);
        } else {
          throw Exception('File không tồn tại sau khi chụp');
        }
      }

      print('No image captured');
      return null;
    } catch (e) {
      print('Error capturing image from camera: $e');
      throw Exception('Lỗi khi chụp ảnh: $e');
    }
  }

  /// Method để xóa ảnh cũ từ Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
        print('Old image deleted successfully');
      }
    } catch (e) {
      print('Error deleting old image: $e');
      // Không throw exception vì việc xóa ảnh cũ thất bại không nên chặn việc upload ảnh mới
    }
  }

  /// Method để kiểm tra permissions (nếu cần)
  Future<bool> checkPermissions() async {
    try {
      // Thử pick một ảnh test để kiểm tra permissions
      final testPick = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1,
        maxHeight: 1,
      );
      return testPick != null;
    } catch (e) {
      print('Permission check failed: $e');
      return false;
    }
  }
}
