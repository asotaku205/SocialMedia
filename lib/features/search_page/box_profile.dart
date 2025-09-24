import 'dart:ffi';

import 'package:flutter/material.dart';

class BoxProfile extends StatefulWidget {
  const BoxProfile({super.key});

  @override
  State<BoxProfile> createState() => _BoxProfileState();
}

class _BoxProfileState extends State<BoxProfile> {
  bool isFollowing = false; // Trạng thái theo dõi

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar load từ network
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                "https://picsum.photos/200", // Ảnh random
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Tên user
          const Expanded(
            child: Text(
              "John Doe",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Nút Follow
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.blue,
              foregroundColor: isFollowing ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                isFollowing = !isFollowing;
              });
            },
            child: Text(isFollowing ? "Following" : "Follow"),
          ),
          const Divider(color: Colors.grey, thickness: 1),
          SizedBox(height: 20,)
        ],
      ),
    );
  }
}
