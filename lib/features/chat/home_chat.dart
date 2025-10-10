import 'package:blogapp/services/auth_service.dart';
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
            content: Text('Error: ${e.toString()}'),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
         leading: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BottomNavigation()), (route) => false);
          },
          child: Image.asset(
            'assets/logo/logoAppRemovebg.webp',
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          "Chats",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Enter search keyword...",
                prefixIcon: Icon(BoxIcons.bx_search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onSubmitted: (value) {},
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Tin nhắn",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          isLoadingFriends
              ? const Center(child: CircularProgressIndicator())
              : friends.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có bạn bè nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Hãy tìm kiếm và kết bạn với mọi người!',
                  style: TextStyle(color: Colors.grey),
                ),
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