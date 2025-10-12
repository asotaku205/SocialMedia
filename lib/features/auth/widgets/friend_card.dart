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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Friend.Unfriend'.tr(), style: textTheme.titleMedium?.copyWith(color: colorScheme.onBackground)),
          content: Text(
            '${'Friend.Unfriend desc'.tr()} ${friend.displayName}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Friend.Cancel'.tr(), style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _unfriend(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              child: Text('Friend.Unfriend'.tr(), style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unfriend(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
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
          backgroundColor: colorScheme.secondary,
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
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: ImageUtils.buildAvatar(
          imageUrl: friend.photoURL,
          radius: 25,
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          child: friend.photoURL.isEmpty
              ? Text(
                  friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : '?',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                )
              : null,
          context: context,
        ),
        title: Text(
          friend.displayName.isNotEmpty ? friend.displayName : friend.userName,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onBackground,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend.userName.isNotEmpty)
              Text(
                '@${friend.userName}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            if (friend.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  friend.bio,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
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
                  Icon(Icons.person, color: colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Friend.View Profile'.tr(), style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ],
              ),
            ),
             PopupMenuItem<String>(
              value: 'unfriend',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: colorScheme.error),
                  SizedBox(width: 8),
                  Text('Friend.Unfriend'.tr(), style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
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
