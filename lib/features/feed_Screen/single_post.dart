import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/post_services.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:blogapp/features/profile/main_profile.dart';
import 'package:readmore/readmore.dart';
import 'package:blogapp/utils/timeago_setup.dart';

class SinglePostCard extends StatefulWidget {
  final PostModel post;
  const SinglePostCard({Key? key, required this.post}) : super(key: key);
  @override
  State<SinglePostCard> createState() => _SinglePostCardState();
}

class _SinglePostCardState extends State<SinglePostCard>
    with TickerProviderStateMixin {
  bool isBookmarked = false; // Cờ lưu trạng thái bookmark post

  /// Hiện bottom sheet khi bấm vào dấu "3 chấm"
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
            // Thanh kéo nhỏ ở trên
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Nút save/unsave
            _buildOptionItem(
              icon: BoxIcons.bx_bookmark,
              title: isBookmarked ? 'Unsave' : 'Save Post',
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
                Navigator.pop(context);
              },
            ),
            // Nút copy link
            _buildOptionItem(
              icon: BoxIcons.bx_link,
              title: 'Copy Link',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget cho từng item trong bottom sheet
  Widget _buildOptionItem({
    required IconData icon,
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
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 16),
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

  /// UI cho từng post
  Widget buidUiPost(PostModel post) {
    final time = TimeagoSetup.formatTime(post.createdAt, context.locale.languageCode); // thời gian đăng dạng "2h ago"

    // Lấy uid của user hiện tại
    final String? currentUserId = AuthService.currentUser?.uid;

    // Lấy thông tin like/comment từ post
    int likeCount = post.likes;
    int commentCount = post.comments;
    bool isLiked =
        currentUserId != null && post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Color(0xFF262626), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Header ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + Tên + Thời gian
                GestureDetector(
                  onTap: () {
                    // Điều hướng sang trang profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainProfile(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.authorAvatar.isNotEmpty
                            ? NetworkImage(post.authorAvatar)
                            : null,
                        child: post.authorAvatar.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            time,
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
                // Nút 3 chấm
                GestureDetector(
                  onTap: _showMoreOptions,
                  child: const Icon(Icons.more_horiz, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- Nội dung bài viết ----------------
            ReadMoreText(
              post.content,
              trimLines: 6,
              trimMode: TrimMode.Line,
              trimCollapsedText: " ${'Feed.More'.tr()}",
              trimExpandedText: "  ${'Feed.Hide'.tr()}",
              moreStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              lessStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 12),

            // ---------------- Ảnh trong post ----------------
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build list post từ stream
    return buidUiPost(widget.post);
  }
}
