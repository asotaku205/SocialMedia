// Import các package cần thiết cho Flutter và Firebase
import 'package:flutter/material.dart'; // Package chính của Flutter để tạo UI
import 'package:firebase_core/firebase_core.dart'; // Package để khởi tạo Firebase
import 'features/auth/screens/login_page.dart'; // Import màn hình đăng nhập
import 'features/auth/screens/login_page.dart'; // Import duplicate - có thể xóa
import 'features/profile/main_profile.dart'; // Import màn hình profile chính
import 'firebase_options.dart'; // File config Firebase được tạo tự động
import 'features/createpost/createpost.dart'; // Import màn hình tạo bài viết
import 'features/profile/setting.dart'; // Import màn hình cài đặt

// Hàm main - điểm khởi đầu của ứng dụng Flutter
void main() async {
  // Đảm bảo rằng Flutter framework đã được khởi tạo hoàn toàn
  // Cần thiết khi sử dụng async operations trước runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với config phù hợp cho platform hiện tại
  // Await để đợi Firebase init hoàn tất trước khi chạy app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Config tự động theo platform (iOS/Android/Web)
  );

  // Chạy ứng dụng Flutter với widget gốc MyApp
  runApp(const MyApp());
}

// Widget gốc của ứng dụng - kế thừa StatelessWidget vì không cần state
class MyApp extends StatelessWidget {
  // Constructor với key optional để tối ưu performance
  const MyApp({super.key});

  // Method bắt buộc của StatelessWidget - xây dựng UI
  @override
  Widget build(BuildContext context) {
    // MaterialApp - widget gốc cung cấp Material Design theme và navigation
    return MaterialApp(
      title: 'Flutter Auth Demo', // Tiêu đề app hiển thị trên task manager
      debugShowCheckedModeBanner: false, // Ẩn banner "DEBUG" ở góc phải trên

      // Cấu hình theme chính cho toàn bộ app
      theme: ThemeData(
        brightness: Brightness.light, // Chế độ sáng (light mode)

        // Tạo color scheme từ màu gốc teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Màu chủ đạo của app
        ),

        useMaterial3: true, // Sử dụng Material Design 3 (phiên bản mới nhất)
        scaffoldBackgroundColor: Colors.white, // Màu nền cho tất cả Scaffold

        // Theme cho các input field trong toàn app
        inputDecorationTheme: InputDecorationTheme(
          filled: true, // Cho phép fill màu nền cho input
          fillColor: Colors.grey.shade100, // Màu nền nhạt cho input

          // Border mặc định cho input field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Bo góc 12px
            borderSide: BorderSide(color: Colors.grey.shade200), // Viền xám nhạt
          ),

          // Border khi input không được focus
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Bo góc 12px
            borderSide: BorderSide(color: Colors.grey.shade200), // Viền xám nhạt
          ),
        ),

        // Theme cho tất cả ElevatedButton trong app
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Màu nền button
            foregroundColor: Colors.white, // Màu text button
            padding: const EdgeInsets.symmetric(vertical: 16), // Padding trên dưới 16px

            // Hình dạng button với góc bo tròn
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bo góc 12px
            ),
          ),
        ),
      ),

      // Màn hình khởi đầu của app
      home: const LoginPage(), // Bắt đầu với màn hình đăng nhập
    );
  }
}
