import 'post_card.dart';
import 'package:blogapp/resource/color.dart';
import 'package:flutter/material.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset(
          'assets/logo/logoApp.webp',
          fit: BoxFit.contain,
          height: kToolbarHeight,
        ),
        actions: [
          IconButton(
            onPressed: (){},
            icon: const Icon(
                Icons.message_outlined),),
        ],
      ),
       body: PostCard(),
    );
  }
}
