// Import các package cần thiết
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import các màn hình trong app
// import 'features/auth/screens/login_page.dart';
// import 'features/profile/main_profile.dart';
// import 'features/createpost/createpost.dart';
// import 'features/profile/setting.dart';
// import 'features/feed_Screen/main_feed.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/chat/home_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  // Chạy app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily:
            'SFProDisplay', // set font cho toàn app
        brightness:
            Brightness.dark, // Chế độ dark
        scaffoldBackgroundColor:
            Colors.black, // Nền app đen
        primaryColor: Colors.white,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          background: Colors.black,
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Colors.black, // nền đen
          foregroundColor: Colors
              .white, // chữ/trở lại/ icon trắng
          elevation: 0, // loại bỏ shadow nếu muốn
        ),

        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(
              backgroundColor:
                  Colors.black,
              type: BottomNavigationBarType
                  .fixed, // hiển thị tất cả item
            ),
        // Text mặc định màu trắng
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
          ),
          titleSmall: TextStyle(
            color: Colors.white,
          ),
        ),

        // Input field theme
        inputDecorationTheme:
            InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[900],
              hintStyle: const TextStyle(
                color: Colors.grey,
              ),
              labelStyle: const TextStyle(
                color: Colors.white,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.white,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),

        // Button theme - Outline trắng
        elevatedButtonTheme:
            ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .transparent, // Nền trong suốt
                foregroundColor:
                    Colors.white, // Chữ trắng
                side: const BorderSide(
                  color: Colors.white,
                  width: 1.5,
                ), // Viền trắng
                padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
      ),

      // Màn hình khởi đầu
      home: const AuthWrapper(),
    );
  }
}
