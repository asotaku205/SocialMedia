import 'package:blogapp/features/feed_Screen/single_post.dart';
import 'package:flutter/material.dart';
import '../profile/main_profile.dart';
import 'package:blogapp/models/post_model.dart';
import '../../features/auth/widgets/bottom_bar.dart';
import 'package:easy_localization/easy_localization.dart';
class CommentUi extends StatefulWidget {
  //truyen doi tuong bai viet v day
  final PostModel post; 
  const CommentUi({super.key, required this.post});

  @override
  State<CommentUi> createState() => _CommentUiState();
}

class _CommentUiState extends State<CommentUi> {
  final TextEditingController _controller = TextEditingController();
  final List<String> comments = List.generate(10, (i) => "Bình luận ${i + 1} - Đây là một bình luận mẫu từ người dùng");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
      title: Text(
          "Feed.Comment".tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      
      ),
      body: Column(
        children: [
          // ================= DANH SÁCH CUỘN =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // ================== HIỂN THỊ 1 BÀI VIẾT DUY NHẤT ==================
                SinglePostCard(post: widget.post),

                const SizedBox(height: 20),

                // ================== TIÊU ĐỀ BÌNH LUẬN ==================
                 Text(
                  "${"Feed.Comment".tr()} (${comments.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.grey),

                // ================== DANH SÁCH COMMENT ==================
                ...List.generate(comments.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MainProfile()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              "https://picsum.photos/100/100?random=1",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF262626), width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "User ${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comments[index],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "2m ago",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // ================= INPUT COMMENT =================
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Color(0xFF262626), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage("https://picsum.photos/100/100?random=1"),
                  ),
                  const SizedBox(width: 10),

                  // Ô nhập comment
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Feed.Comment hint".tr(),
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,

                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() {
                        comments.insert(0, _controller.text.trim());
                      });
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
