import 'package:flutter/material.dart';
import '../features/profile/main_profile.dart';
import '../features/profile/other_user_profile_screen.dart';
import '../services/auth_service.dart';

class NavigationUtils {
  static void navigateToProfile(BuildContext context, String postAuthorId) {
    final String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == postAuthorId) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainProfile()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(userId: postAuthorId),
        ),
      );
    }
  }
}
