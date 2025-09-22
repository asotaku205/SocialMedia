// Import thư viện dart:io để làm việc với files trên hệ thống
import 'dart:io';
// Import package image_picker để chọn ảnh từ gallery hoặc camera
import 'package:image_picker/image_picker.dart';

// Class UploadImageService - quản lý việc upload và chọn ảnh
class UploadImageService {
  // Khởi tạo instance của ImagePicker để sử dụng trong class
  final ImagePicker _picker = ImagePicker();

  /// Method để upload ảnh từ gallery của thiết bị
  /// Trả về Future<File?> - File nếu chọn ảnh thành công, null nếu hủy
  Future<File?> uploadFromGallery() async {
    // Mở gallery để user chọn ảnh
    // ImageSource.gallery chỉ định nguồn là thư viện ảnh
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    // Kiểm tra xem user có chọn ảnh hay không
    if (pickedFile != null) {
      // Chuyển đổi XFile thành File object để sử dụng trong app
      return File(pickedFile.path);
    }

    // Trả về null nếu user hủy việc chọn ảnh
    return null;
  }
}
