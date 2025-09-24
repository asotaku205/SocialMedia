import 'package:flutter/material.dart';
import '../profile/main_profile.dart';

class CommentUi extends StatefulWidget {
  const CommentUi({super.key});

  @override
  State<CommentUi> createState() => _CommentUiState();
}

class _CommentUiState extends State<CommentUi> {
  final TextEditingController _controller = TextEditingController();

  final List<String> comments = List.generate(10, (i) => "cmt ${i + 1}");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Image.asset(
          'assets/logo/logoApp.webp',
          height: 36,
        ),
      ),

      body: Column(
        children: [
          // ================= DANH SÁCH CUỘN =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // ================== BÀI VIẾT ==================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 4, offset: Offset(0,2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainProfile()),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage:
                              NetworkImage('https://i.pravatar.cc/150?img=11'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Anh Son',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text('2 hours ago',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.more_horiz),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This is the content of the post. It can be a text description of what the user wants to share.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://picsum.photos/400/200',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Icon(Icons.thumb_up_alt_outlined),
                          Icon(Icons.comment_outlined),
                          Icon(Icons.share_outlined),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text("Bình luận",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),

                // ================== COMMENT ==================
                ...List.generate(comments.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                              "https://i.pravatar.cc/150?img=${index + 2}"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("User ${index + 1}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(comments[index],
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text("2m ago",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
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
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage:
                    NetworkImage('https://example.com/profile.jpg'),
                  ),
                  const SizedBox(width: 10),

                  // Ô nhập comment
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Viết bình luận...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() {
                        comments.add(_controller.text.trim());
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
