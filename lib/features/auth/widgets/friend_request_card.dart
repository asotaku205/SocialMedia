import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/friend_services.dart';
import '../../../utils/image_utils.dart';

class FriendRequestCard extends StatelessWidget {
  final UserModel sender;
  final Map<String, dynamic> friendship;
  final VoidCallback? onActionCompleted;

  const FriendRequestCard({
    Key? key,
    required this.sender,
    required this.friendship,
    this.onActionCompleted,
  }) : super(key: key);

  Future<void> _acceptRequest(BuildContext context) async {
    try {
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
              Text('Friend.Accept status'.tr()),
            ],
          ),
        ),
      );
      // Sử dụng userId của sender
      await FriendService.acceptFriendRequestFromUser(sender.uid);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${"Friend.Accepted".tr()} ${sender.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
      if (onActionCompleted != null) {
        onActionCompleted!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${"Authentication.Error".tr()} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineRequest(BuildContext context) async {
    try {
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
              Text('Friend.Decline status'.tr()),
            ],
          ),
        ),
      );
      await FriendService.cancelFriendRequest(sender.uid);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${"Friend.Declined".tr()} ${sender.displayName}'),
          backgroundColor: Colors.orange,
        ),
      );
      if (onActionCompleted != null) {
        onActionCompleted!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${"Authentication.Error".tr()} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ImageUtils.buildAvatar(
                  imageUrl: sender.photoURL,
                  child: sender.photoURL.isEmpty 
                      ? const Icon(Icons.person, color: Colors.black) // Thay đổi từ Colors.grey sang Colors.black
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Friend.Friend Requests', style: TextStyle(color: Colors.grey[700], fontSize: 13)).tr(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _acceptRequest(context),
                  child: Text('Friend.Accept').tr(),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                TextButton(
                  onPressed: () => _declineRequest(context),
                  child: Text('Friend.Decline').tr(),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
