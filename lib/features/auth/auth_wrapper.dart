import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/widgets/bottom_bar.dart'; // Import BottomNavigation
import 'screens/login_page.dart';

/// AuthWrapper - Widget kiểm tra authentication state và navigate đúng màn hình
/// Sử dụng StreamBuilder để lắng nghe thay đổi authentication state real-time
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return BottomNavigation();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
