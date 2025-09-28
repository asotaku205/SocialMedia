import 'package:flutter/material.dart';
import '../profile/main_profile.dart';
import '../feed_Screen/post_card.dart';

class CommentUi extends StatefulWidget {
  const CommentUi({super.key});

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
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logo/logoAppRemovebg.webp',
            height: 45,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
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
                SinglePostCard(),

                const SizedBox(height: 20),

                // ================== TIÊU ĐỀ BÌNH LUẬN ==================
                const Text(
                  "Bình luận",
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
                        decoration: const InputDecoration(
                          hintText: "Viết bình luận...",
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

// Widget riêng để hiển thị 1 bài viết duy nhất
class SinglePostCard extends StatefulWidget {
  @override
  State<SinglePostCard> createState() => _SinglePostCardState();
}

class _SinglePostCardState extends State<SinglePostCard> with TickerProviderStateMixin {
  bool isLiked = false;
  bool isBookmarked = false;
  int likeCount = 128;
  int commentCount = 24;

  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
        });
      } else {
        likeCount--;
      }
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionItem(
              title: isBookmarked ? 'Bỏ lưu' : 'Lưu bài viết',
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              title: 'Sao chép liên kết',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionItem(
              title: 'Báo cáo',
              onTap: () => Navigator.pop(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String content =
        "This is the content of the post. It can be a text description of what the user wants to share. "
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus feugiat commodo felis, "
        "ac tincidunt nisi ultrices sed.";

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262626), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info và more options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainProfile()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF262626), width: 1),
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage("https://picsum.photos/100/100?random=1"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anh Son',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '2 hours ago',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showMoreOptions,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nội dung bài viết - hiển thị đầy đủ
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              softWrap: true,
            ),

            const SizedBox(height: 12),

            // Ảnh bài viết
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  "https://picsum.photos/400/300?random=1",
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF1A1A1A),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey[600],
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Thống kê like và comment
            Row(
              children: [
                Text(
                  '$likeCount Like',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$commentCount Comment',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Các nút tương tác
            Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _toggleLike,
                  child: AnimatedBuilder(
                    animation: _likeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _likeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[400],
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // Comment button
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.comment_outlined,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),

                const SizedBox(width: 4),

                // Share button
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.share_outlined,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),

                const Spacer(),

                // Bookmark button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isBookmarked = !isBookmarked;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? const Color(0xFF1DA1F2) : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
