import 'package:blogapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:blogapp/services/chat_service.dart';
import 'chat_list.dart';
import 'package:blogapp/models/user_model.dart';
import 'package:blogapp/services/friend_services.dart';
import '../../features/auth/widgets/bottom_bar.dart';

class HomeChat extends StatefulWidget {
  const HomeChat({super.key});

  @override
  State<HomeChat> createState() => _HomeChatState();
}

class _HomeChatState extends State<HomeChat> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  bool isLoadingFriends = false;
  List<UserModel> friends = [];
  DateTime _lastUpdate = DateTime.now(); // Thêm để track thời gian cập nhật

  @override
  void initState() {
    super.initState();
    _loadFriends(); // Tải danh sách bạn bè khi màn hình được khởi tạo
  }

  Future<void> _loadFriends() async {
    if (!mounted) return;

    setState(() {
      isLoadingFriends = true;
    });

    try {
      final friendsList = await FriendService().getFriends();
      
      // Sắp xếp danh sách bạn bè theo tin nhắn mới nhất
      await _sortFriendsByLatestMessage(friendsList);
      
      if (mounted) {
        setState(() {
          friends = friendsList;
          isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingFriends = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication.Error: ${e.toString()}').tr(),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sortFriendsByLatestMessage(List<UserModel> friendsList) async {
    // Tạo một map để lưu thời gian tin nhắn mới nhất của mỗi friend
    Map<String, DateTime?> latestMessageTimes = {};
    
    // Lấy tin nhắn mới nhất cho mỗi friend
    for (UserModel friend in friendsList) {
      try {
        final latestMessage = await ChatService.getLatestMessage(friend.uid);
        latestMessageTimes[friend.uid] = latestMessage?.timestamp;
      } catch (e) {
        print('Error getting latest message for ${friend.uid}: $e');
        latestMessageTimes[friend.uid] = null;
      }
    }
    
    // Sắp xếp danh sách friends theo thời gian tin nhắn mới nhất
    friendsList.sort((a, b) {
      final timeA = latestMessageTimes[a.uid];
      final timeB = latestMessageTimes[b.uid];
      
      // Nếu cả hai đều có tin nhắn, sắp xếp theo thời gian mới nhất
      if (timeA != null && timeB != null) {
        return timeB.compareTo(timeA); // Mới nhất lên đầu
      }
      
      // Nếu chỉ A có tin nhắn, A lên đầu
      if (timeA != null && timeB == null) {
        return -1;
      }
      
      // Nếu chỉ B có tin nhắn, B lên đầu
      if (timeA == null && timeB != null) {
        return 1;
      }
      
      // Nếu cả hai đều không có tin nhắn, sắp xếp theo tên
      return a.displayName.compareTo(b.displayName);
    });
  }

  // Thêm method để cập nhật danh sách chat
  void _updateChatList() {
    print('Updating chat list...');
    _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        centerTitle: false,
        title: Text(
          "Chat.Chats",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ).tr(),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search.Please enter keyword".tr(),
                prefixIcon: Icon(BoxIcons.bx_search, color: colorScheme.onSurface),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colorScheme.surface,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              onSubmitted: (value) {},
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Chat.Messages",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).tr(),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, color: colorScheme.onBackground),
              ),
            ],
          ),
          isLoadingFriends
              ? const Center(child: CircularProgressIndicator())
              : friends.isEmpty
              ?  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: colorScheme.onSurface.withOpacity(0.5)),
                SizedBox(height: 16),
                Text(
                  'Chat.You have no friends yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                ).tr(),
                SizedBox(height: 8),
                Text(
                  'Friend.Lets find some!',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                ).tr(),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadFriends,
            child: ListView.builder(
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                return ChatList(
                  friend: friends[index],
                  onChatUpdate: _updateChatList, // Truyền callback
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}