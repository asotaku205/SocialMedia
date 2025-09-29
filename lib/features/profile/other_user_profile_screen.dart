import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/friend_services.dart';
import '../../services/auth_service.dart';
import '../feed_Screen/post_card.dart';
import '../../models/post_model.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const OtherUserProfileScreen({
    Key? key,
    required this.userId,
    this.username,
  }) : super(key: key);

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  UserModel? currentUser;
  List<PostModel> userPosts = [];
  bool isLoading = true;
  String friendshipStatus = 'none'; // none, pending, friends, sent
  bool isProcessingRequest = false;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    setState(() {
      isLoading = true;
    });
    try {
      UserModel? user = await FriendService.getUserById(widget.userId);
      if (user != null) {
        setState(() {
          currentUser = user;
        });
        await _checkFriendshipStatus();
        await _loadUserPosts();
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching user data: $e');
    }
  }

  Future<void> _checkFriendshipStatus() async {
    try {
      final status = await FriendService.getFriendshipStatus(widget.userId);
      if (mounted) {
        setState(() {
          friendshipStatus = status;
        });
      }
    } catch (e) {
      print('Error checking friendship status: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final posts = await FriendService.getUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          userPosts = posts;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
    }
  }

  // Trả về String? (URL) hoặc null nếu không có avatar
  Future<String?> getUserAvatarUrl() async {
    try {
      if (currentUser != null && currentUser!.photoURL.isNotEmpty) {
        return currentUser!.photoURL;
      } else {
        return null; // Không có avatar -> hiển thị icon
      }
    } catch (e) {
      print("Error getting user avatar: $e");
      return null;
    }
  }

  Future<void> _handleFriendAction() async {
    if (isProcessingRequest) return;

    setState(() {
      isProcessingRequest = true;
    });

    try {
      String result = '';

      switch (friendshipStatus) {
        case 'none':
          result = await FriendService.SendFriendRequest(widget.userId);
          if (result.isEmpty || result == 'success') {
            setState(() {
              friendshipStatus = 'sent';
            });
            _showSnackBar('Đã gửi lời mời kết bạn', Colors.green);
          } else {
            _showSnackBar(result, Colors.red);
          }
          break;

        case 'sent':
          result = await FriendService.cancelFriendRequest(widget.userId);
          if (result == 'success') {
            setState(() {
              friendshipStatus = 'none';
            });
            _showSnackBar('Đã hủy lời mời kết bạn', Colors.orange);
          } else {
            _showSnackBar(result, Colors.red);
          }
          break;

        case 'pending':
          await FriendService.acceptFriendRequestFromUser(widget.userId);
          setState(() {
            friendshipStatus = 'friends';
            if (currentUser != null) {
              currentUser = currentUser!.copyWith(friendCount: currentUser!.friendCount + 1);
            }
          });
          _showSnackBar('Đã chấp nhận lời mời kết bạn', Colors.green);
          break;

        case 'friends':
          await FriendService().unfriend(widget.userId);
          setState(() {
            friendshipStatus = 'none';
            if (currentUser != null) {
              currentUser = currentUser!.copyWith(friendCount: currentUser!.friendCount - 1);
            }
          });
          _showSnackBar('Đã hủy kết bạn', Colors.red);
          break;
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isProcessingRequest = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildFriendActionButton() {
    if (isProcessingRequest) {
      return Container(
        width: double.infinity,
        height: 40,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    switch (friendshipStatus) {
      case 'none':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleFriendAction,
            icon: const Icon(Icons.person_add),
            label: const Text('Kết bạn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'sent':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleFriendAction,
            icon: const Icon(Icons.pending),
            label: const Text('Hủy lời mời'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'pending':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleFriendAction,
            icon: const Icon(Icons.check),
            label: const Text('Chấp nhận kết bạn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'friends':
        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Bạn bè',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _handleFriendAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Hủy kết bạn'),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${currentUser?.userName ?? currentUser?.displayName ?? widget.username ?? "Profile"}',
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showSnackBar('Tính năng báo cáo sẽ được thêm sau', Colors.blue);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // User Info Section
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        // Row chứa avatar và thông tin user
                        Row(
                          children: [
                            FutureBuilder<String?>(
                              future: getUserAvatarUrl(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  // Neu dang trang thai cho se hien ra loading
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.white, Colors.white],
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 50,
                                    ),
                                  );
                                }

                                String? avatarUrl = snapshot.data;
                                //gan URL tu snapshot cho bien avatarURL

                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Colors.white],
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: avatarUrl != null //check dk neu avatarUrl ko bang null
                                        ? Image.network(
                                            //nhay vao day neu true
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                color: Colors.black,
                                                size: 50,
                                              );
                                            },
                                          )
                                        : const Icon(
                                            //nhay vao day neu false
                                            Icons.person,
                                            color: Colors.black,
                                            size: 50,
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentUser?.displayName ?? currentUser?.userName ?? "Username"}',
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (currentUser?.userName?.isNotEmpty == true)
                                    Text(
                                      '@${currentUser!.userName}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  if (currentUser?.bio?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        currentUser!.bio,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[300],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  // Row chứa thống kê Posts và Friends
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'posts',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '${userPosts.length}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'friends',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '${currentUser?.friendCount ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Friend Action Button
                        _buildFriendActionButton(),
                      ],
                    ),
                  ),

                  // Divider
                  const Divider(
                    height: 1,
                    color: Colors.grey,
                  ),

                  // Posts Section
                  if (userPosts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bài viết',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userPosts.length,
                            itemBuilder: (context, index) {
                              return PostCard();
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.post_add_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có bài viết nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
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
}
