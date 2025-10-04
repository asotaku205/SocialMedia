
import 'package:blogapp/features/feed_Screen/post_card.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../chat/home_chat.dart';
import '../../models/user_model.dart';
import '../../services/friend_services.dart';
import '../../services/auth_service.dart';
import '../feed_Screen/post_card.dart';
import '../../models/post_model.dart';


class FeedScreen extends StatefulWidget {

  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() =>
      _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(
            8,
          ), // bo nhẹ cho logo
          child: Image.asset(
            'assets/logo/logoAppRemovebg.webp',
            height:
                45,
            fit: BoxFit
                .contain, // giữ nguyên tỉ lệ không méo
            filterQuality: FilterQuality.high,
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
