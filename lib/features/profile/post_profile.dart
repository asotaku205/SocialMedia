import 'package:blogapp/features/feed_Screen/comment_ui.dart';
import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:blogapp/services/post_services.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:readmore/readmore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:blogapp/utils/timeago_setup.dart';

import '../../resource/navigation.dart';
import '../../widgets/full_screen_image.dart';

class PostProfile extends StatefulWidget {
  final String? userId;

  const PostProfile({super.key, this.userId});

  @override
  State<PostProfile> createState() => _PostProfileState();
}

class _PostProfileState extends State<PostProfile> with TickerProviderStateMixin {
  bool isBookmarked = false; // Cờ bookmark (global cho demo)
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  // Build toàn bộ list post từ stream
  Widget buildListPost() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final String? targetUserId = widget.userId ?? AuthService.currentUser?.uid;
    return StreamBuilder<List<PostModel>>(
      stream: PostService.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Icon(Icons.error, size: 40, color: colorScheme.error));
        }
        final allPosts = snapshot.data ?? [];
        final userPosts = targetUserId == null
            ? <PostModel>[]
            : allPosts.where((p) => p.authorId == targetUserId).toList();
        if (userPosts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Feed.No posts from friends".tr(),
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userPosts.length,
          itemBuilder: (context, index) {
            final post = userPosts[index];
            return buildUiPost(post);
          },
        );
      },
    );
  }

  // UI cho từng post
  Widget buildUiPost(PostModel post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final time = TimeagoSetup.formatTime(post.createdAt, context.locale.languageCode);
    final String? currentUserId = AuthService.currentUser?.uid;
    final int likeCount = post.likes;
    final int commentCount = post.comments;
    final bool isLiked = currentUserId != null && post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: colorScheme.background,
        border: Border(bottom: BorderSide(color: colorScheme.surface, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => NavigationUtils.navigateToProfile(context, post.authorId),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.authorAvatar.isNotEmpty ? NetworkImage(post.authorAvatar) : null,
                        child: post.authorAvatar.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
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
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onBackground,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            time,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showMoreOptions(post);
                  },
                  child: Icon(Icons.more_horiz, color: colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
              },
              child: ReadMoreText(
                post.content,
                trimLines: 6,
                trimMode: TrimMode.Line,
                trimCollapsedText: " ${'Feed.More'.tr()}",
                trimExpandedText: "  ${'Feed.Hide'.tr()}",
                moreStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 15),
                lessStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 15),
                style: textTheme.bodyLarge?.copyWith(fontSize: 20, color: colorScheme.onBackground),
              ),
            ),

            const SizedBox(height: 12),

            // Image (nếu có) với errorBuilder
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(
                        imageUrl: post.imageUrls.first,
                        heroTag: 'profile_post_image_${post.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'profile_post_image_${post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrls.first,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: MediaQuery.of(context).size.height * 0.3,
                        color: colorScheme.surface,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image, color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Like & Comment counts
            Row(
              children: [
                Text(
                  '$likeCount ${'Feed.Like'.tr()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
                  },
                  child: Text(
                    '$commentCount ${'Feed.Comment'.tr()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final uid = AuthService.currentUser?.uid;
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('General.Action required'.tr())),
                      );
                      return;
                    }
                    _likeAnimationController.forward().then((_) {
                      _likeAnimationController.reverse();
                    });
                    await PostService.toggleLike(post.id, uid);
                  },
                  child: AnimatedBuilder(
                    animation: _likeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _likeAnimation.value,
                        child: Icon(
                          isLiked ? BoxIcons.bxs_heart : BoxIcons.bx_heart,
                          color: isLiked ? colorScheme.error : colorScheme.onSurface.withOpacity(0.7),
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
                  },
                  child: Icon(BoxIcons.bx_message_rounded, color: colorScheme.onSurface.withOpacity(0.7), size: 22),
                ),

                const SizedBox(width: 16),

                Icon(BoxIcons.bx_send, color: colorScheme.onSurface.withOpacity(0.7), size: 22),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      isBookmarked = !isBookmarked;
                    });
                  },
                  child: Icon(
                    isBookmarked ? BoxIcons.bxs_bookmark : BoxIcons.bx_bookmark,
                    color: isBookmarked ? Colors.yellow : colorScheme.onSurface.withOpacity(0.7),
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(PostModel post) {
    final String? currentUserId = AuthService.currentUser?.uid;
    final bool isOwner = currentUserId != null && currentUserId == post.authorId;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(2)),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(BoxIcons.bx_bookmark, color: colorScheme.onBackground, size: 22),
                    const SizedBox(width: 16),
                    Text(
                      'Feed.Save Post'.tr(),
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(BoxIcons.bx_link, color: colorScheme.onBackground, size: 22),
                    const SizedBox(width: 16),
                    Text(
                      'Copy Link',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (isOwner)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final delPost = await PostService.deletePost(post.id);
                    if (delPost == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete success")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting post")));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Icon(BoxIcons.bx_trash, color: colorScheme.error, size: 22),
                      const SizedBox(width: 16),
                      Text(
                        'Delete',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildListPost();
  }
}
