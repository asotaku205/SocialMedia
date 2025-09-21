// Import package http để thực hiện các API calls
import 'package:http/http.dart' as http;

// Class AuthService - quản lý tất cả logic xác thực người dùng
class AuthService {
  // Method static để đăng nhập - có thể gọi mà không cần tạo instance
  // Tham số: email và password của user
  // Trả về: Future<bool> - true nếu đăng nhập thành công, false nếu thất bại
  static Future<bool> login(String email, String password) async {
    // Gửi POST request đến API endpoint đăng nhập
    final response = await http.post(
      Uri.parse("https://yourapi.com/login"), // URL API đăng nhập (placeholder)
      body: {
        "email": email,       // Gửi email trong body request
        "password": password  // Gửi password trong body request
      },
    );

    // Kiểm tra status code response
    // 200 = OK (thành công), trả về true
    // Khác 200 = lỗi, trả về false
    return response.statusCode == 200;
  }
}
