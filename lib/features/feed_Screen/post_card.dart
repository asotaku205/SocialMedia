import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
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
  //hàm để xử lí khi nhấn vào nút more options
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
            icon: BoxIcons.bx_bookmark,
            title: isBookmarked ? 'Unsave' : 'Save Post',
            onTap: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });
              Navigator.pop(context);
            },
          ),
          _buildOptionItem(
            icon: BoxIcons.bx_link,
            title: 'Copy Link',
            onTap: () => Navigator.pop(context),
          ),
          _buildOptionItem(
            icon: BoxIcons.bx_flag,
            title: 'Report',
            onTap: () => Navigator.pop(context),
            isDestructive: true,
          ),
          _buildOptionItem(
            icon: BoxIcons.bx_trash,
            title: 'Delete',
            onTap: () => Navigator.pop(context),
            isDestructive: true,
          ),
        ],
      ),
    ),
  );
}


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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF262626),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Avatar + User Info + More Options
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF262626),
                          width: 1,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          "https://picsum.photos/100/100?random=1",
                        ),
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(width: 12),
                // Thông tin người dùng
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'username',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút more options
                GestureDetector(
                  onTap: _showMoreOptions,//gọi hàm khi nhấn vào
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
            
            // Nội dung bài viết
            const Text(
              'Enjoying the beautiful sunset today! 🌅 Nature never fails to amaze me with its incredible colors and peaceful moments.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            
            const SizedBox(height: 12),
            
            //Ảnh bài viết
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
                  "https://picsum.photos/400/300?random=2",
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
            
            // Biểu thị lượt tim và bình luận
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
            
            //các bút bấm trạng thái
            Row(
              children: [
                // Like 
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
                            isLiked ? BoxIcons.bxs_heart : BoxIcons.bx_heart,
                            color: isLiked ? Colors.red : Colors.grey[400],
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Comment
                GestureDetector(
                  onTap: () {
                    // xử lí hành động đẻ e chuyển sang trang commnet ở đây
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      BoxIcons.bx_message_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Share button
                GestureDetector(
                  onTap: () {
                    // Xử lí hành động share ở đây
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      BoxIcons.bx_send,
                      color: Colors.grey[400],
                      size: 22,
                    ),
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
                      isBookmarked ? BoxIcons.bxs_bookmark : BoxIcons.bx_bookmark,
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