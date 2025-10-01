import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/friend_services.dart';
import '../../../models/friend_model.dart';

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
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Đang chấp nhận lời mời...'),
            ],
          ),
        ),
      );
      // Sử dụng userId của sender
      await FriendService.acceptFriendRequestFromUser(sender.uid);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chấp nhận lời mời kết bạn từ ${sender.displayName}'),
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
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineRequest(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Đang từ chối lời mời...'),
            ],
          ),
        ),
      );
      await FriendService.cancelFriendRequest(sender.uid);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối lời mời kết bạn từ ${sender.displayName}'),
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
          content: Text('Lỗi: ${e.toString()}'),
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
                CircleAvatar(
                  backgroundImage:
                      sender.photoURL.isNotEmpty ? NetworkImage(sender.photoURL) : null,
                  child: sender.photoURL.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Lời mời kết bạn', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _acceptRequest(context),
                  child: const Text('Chấp nhận'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                TextButton(
                  onPressed: () => _declineRequest(context),
                  child: const Text('Từ chối'),
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
