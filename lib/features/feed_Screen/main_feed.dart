
import 'package:blogapp/features/feed_Screen/post_card.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../chat/home_chat.dart';
import '../../models/user_model.dart';
import '../../services/friend_services.dart';
import '../../services/auth_service.dart';
import '../feed_Screen/post_card.dart';
import '../../models/post_model.dart';
import '../auth/widgets/bottom_bar.dart';

class FeedScreen extends StatefulWidget {

  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() =>
      _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = isDark
        ? 'assets/logo/logoAppRemovebg.webp'
        : 'assets/logo/logoApp_pure_black.png';
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BottomNavigation()), (route) => false);
          },
          child: Image.asset(
            logoPath,
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeChat()),
              );
            },
            icon: const Icon(BoxIcons.bxs_chat),
          ),
        ],
      ),
      body:PostCard(),
    );
  }
}
