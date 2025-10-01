import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/friend_services.dart';
import '../profile/other_user_profile_screen.dart';

class BoxProfile extends StatefulWidget {
  final UserModel user;
  final String? friendshipStatus;
  final VoidCallback? onFriendshipChanged;

  const BoxProfile({super.key, required this.user, this.friendshipStatus, this.onFriendshipChanged});

  @override
  State<BoxProfile> createState() => _BoxProfileState();
}

class _BoxProfileState extends State<BoxProfile> {
  late String currentFriendshipStatus;

  @override
  void initState() {
    super.initState();
    currentFriendshipStatus = widget.friendshipStatus ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtherUserProfileScreen(userId: widget.user.uid, username: widget.user.userName),
          ),
        ).then((_) async {
          // Refresh friendship status khi quay lại
          try {
            final status = await FriendService.getFriendshipStatus(widget.user.uid);
            if (mounted) {
              setState(() {
                currentFriendshipStatus = status;
              });
              if (widget.onFriendshipChanged != null) {
                widget.onFriendshipChanged!();
              }
            }
          } catch (e) {
            print('Error refreshing friendship status: $e');
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar load từ user data
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: widget.user.photoURL.isNotEmpty ? NetworkImage(widget.user.photoURL) : null,
                    child: widget.user.photoURL.isEmpty
                        ? Text(
                            widget.user.displayName.isNotEmpty
                                ? widget.user.displayName[0].toUpperCase()
                                : widget.user.userName.isNotEmpty
                                ? widget.user.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Thông tin user
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.displayName.isNotEmpty ? widget.user.displayName : widget.user.userName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (widget.user.userName.isNotEmpty)
                          Text('@${widget.user.userName}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        if (widget.user.bio.isNotEmpty)
                          Text(
                            widget.user.bio,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                // Nút kết bạn dựa trên trạng thái
                currentFriendshipStatus == 'friends'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : currentFriendshipStatus == 'sent'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          'Đã gửi',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    : currentFriendshipStatus == 'pending'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Chấp nhận',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            final result = await FriendService.SendFriendRequest(widget.user.uid);

                            if (result.isEmpty || result == 'success') {
                              setState(() {
                                currentFriendshipStatus = 'sent';
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã gửi lời mời kết bạn tới ${widget.user.displayName}'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              if (widget.onFriendshipChanged != null) {
                                widget.onFriendshipChanged!();
                              }
                            } else {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi gửi lời mời: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text("Kết bạn"),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
