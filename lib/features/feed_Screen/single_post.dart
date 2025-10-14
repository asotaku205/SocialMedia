import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:blogapp/features/profile/main_profile.dart';
import 'package:readmore/readmore.dart';
import 'package:blogapp/utils/timeago_setup.dart';
import 'package:blogapp/utils/image_utils.dart';
import '../../widgets/full_screen_image.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.background,
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
                color: colorScheme.secondary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Nút save/unsave
            _buildOptionItem(
              icon: BoxIcons.bx_bookmark,
              title: isBookmarked ? 'Feed.Unsave'.tr() : 'Feed.Save Post'.tr(),
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
              title: 'Feed.Copy Link'.tr(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : textColor,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : textColor,
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

    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: colorScheme.background,
        border: Border(
          bottom: BorderSide(color: colorScheme.surface, width: 0.5),
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
                      ImageUtils.buildAvatar(
                        imageUrl: post.authorAvatar,
                        radius: 20,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        context: context,
                        child: post.authorAvatar.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.secondary.withOpacity(0.5),
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
                  child: Icon(Icons.more_horiz, color: colorScheme.secondary),
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
              moreStyle: TextStyle(color: colorScheme.secondary, fontSize: 15),
              lessStyle: TextStyle(color: colorScheme.secondary, fontSize: 15),
              style: TextStyle(fontSize: 20, color: textColor),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 12),

            // ---------------- Ảnh trong post ----------------
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(
                        imageUrl: post.imageUrls.first,
                        heroTag: 'comment_post_image_${post.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'comment_post_image_${post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrls.first,
                      fit: BoxFit.contain,
                    ),
                  ),
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
