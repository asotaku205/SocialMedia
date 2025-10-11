// Import thư viện để làm việc với files
import 'dart:typed_data';
import 'dart:convert';
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
  /// Trả về Future<XFile?> - XFile nếu chọn ảnh thành công, null nếu hủy
  Future<XFile?> uploadFromGallery() async {
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
        return pickedFile;
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
  Future<String> uploadImage(XFile imageFile) async {
    try {
      // Lấy user hiện tại
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User chưa đăng nhập');
      }

      print('Starting image upload for user: ${user.uid}');

      // Trên web, sử dụng base64 fallback ngay lập tức để tránh CORS
      if (kIsWeb) {
        print('Using base64 fallback for web platform');
        return await _uploadAsBase64Fallback(imageFile);
      }

      // Mobile approach - sử dụng Firebase Storage bình thường
      final Uint8List imageBytes = await imageFile.readAsBytes();
      print('File size: ${imageBytes.length} bytes');

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('profile_images/$fileName');

      print('Uploading to Firebase Storage path: profile_images/$fileName');

      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': fileName,
            'platform': 'mobile',
          },
        ),
      );

      print('Mobile upload completed successfully');
      final downloadURL = await uploadTask.ref.getDownloadURL();
      print('Download URL obtained: $downloadURL');
      return downloadURL;

    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Lỗi khi upload ảnh: ${e.toString()}');
    }
  }

  /// Fallback method: Convert ảnh thành base64 và lưu metadata trong Firestore
  Future<String> _uploadAsBase64Fallback(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User chưa đăng nhập');

      // Đọc ảnh thành bytes và convert sang base64
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Giới hạn kích thước để tránh base64 quá lớn
      if (imageBytes.length > 1024 * 1024) { // 1MB
        throw Exception('Ảnh quá lớn cho web upload. Vui lòng chọn ảnh nhỏ hơn 1MB');
      }
      
      final String base64String = base64Encode(imageBytes);
      
      // Tạo data URL
      final String dataUrl = 'data:image/jpeg;base64,$base64String';
      
      print('Using base64 fallback for web upload');
      print('Base64 data length: ${dataUrl.length} characters');
      
      return dataUrl;
      
    } catch (e) {
      print('Fallback upload failed: $e');
      throw Exception('Không thể upload ảnh trên web: ${e.toString()}');
    }
  }

  /// Method để upload ảnh từ camera
  Future<XFile?> uploadFromCamera() async {
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
        return pickedFile;
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
