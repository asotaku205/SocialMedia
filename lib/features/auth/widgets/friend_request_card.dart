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
      // Show loading
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

      // Gọi service để chấp nhận lời mời
      await FriendService.AcceptFriendRequest(friendship['id']);

      // Hide loading và show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chấp nhận lời mời kết bạn từ ${sender.displayName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
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
      // Show loading
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

      // Gọi service để từ chối lời mời
      await FriendService.declineFriendRequest(friendship['id']);

      // Hide loading và show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối lời mời kết bạn từ ${sender.displayName}'),
          backgroundColor: Colors.orange,
        ),
      );

      // Reload data
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: sender.photoURL.isNotEmpty
                  ? NetworkImage(sender.photoURL)
                  : null,
              child: sender.photoURL.isEmpty
                  ? Text(
                      sender.displayName.isNotEmpty
                          ? sender.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sender.displayName.isNotEmpty
                        ? sender.displayName
                        : sender.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (sender.userName.isNotEmpty)
                    Text(
                      '@${sender.userName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  if (sender.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sender.bio,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptRequest(context),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Chấp nhận'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _declineRequest(context),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Từ chối'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
