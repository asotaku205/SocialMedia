import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/friend_services.dart';
import '../../profile/other_user_profile_screen.dart';
import '../../../utils/image_utils.dart';

class FriendCard extends StatelessWidget {
  final UserModel friend;
  final VoidCallback? onUnfriend;

  const FriendCard({
    Key? key,
    required this.friend,
    this.onUnfriend,
  }) : super(key: key);
  void _viewProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          userId: friend.uid,
          username: friend.userName,
        ),
      ),
    );
  }

  void _showUnfriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Friend.Unfriend'.tr()),
          content: Text(
            '${'Friend.Unfriend desc'.tr()} ${friend.displayName}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Friend.Cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _unfriend(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Friend.Unfriend'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unfriend(BuildContext context) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Friend.Unfriend status'.tr()),
            ],
          ),
        ),
      );

      // Gọi service để hủy kết bạn
      await FriendService().unfriend(friend.uid);

      // Hide loading và show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Friend.Unfriend Success'.tr()} ${friend.displayName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload danh sách bạn bè
      if (onUnfriend != null) {
        onUnfriend!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Authentication.Error'.tr()} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: ImageUtils.buildAvatar(
          imageUrl: friend.photoURL,
          radius: 25,
          child: friend.photoURL.isEmpty
              ? Text(
                  friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Thay đổi từ Colors.grey sang Colors.black
                  ),
                )
              : null,
        ),
        title: Text(
          friend.displayName.isNotEmpty ? friend.displayName : friend.userName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend.userName.isNotEmpty)
              Text(
                '@${friend.userName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (friend.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  friend.bio,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _viewProfile(context);
                break;
              case 'unfriend':
                _showUnfriendDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
             PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Friend.View Profile'.tr()),
                ],
              ),
            ),
             PopupMenuItem<String>(
              value: 'unfriend',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Friend.Unfriend'.tr(), style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewProfile(context),
      ),
    );
  }


}
