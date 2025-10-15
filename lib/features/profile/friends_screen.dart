import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/friend_services.dart';
import '../../models/user_model.dart';
import '../auth/widgets/friend_card.dart';
import '../auth/widgets/friend_request_card.dart';
import '../search_page/search_page.dart';
import 'package:easy_localization/easy_localization.dart';

class FriendsScreen extends StatefulWidget {
  final String? userId; // userId của người muốn xem danh sách bạn bè, null = current user
  
  const FriendsScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<UserModel> friends = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoadingFriends = false;
  bool isLoadingRequests = false;
  UserModel? userInfo; // Thông tin người dùng khi xem profile người khác

  @override
  void initState() {
    super.initState();
    // Chỉ hiện 1 tab nếu đang xem profile người khác
    int tabLength = widget.userId != null ? 1 : 2;
    _tabController = TabController(length: tabLength, vsync: this);
    _loadData(); // Load initial data
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load cả friends và pending requests (chỉ load requests nếu là current user)
  Future<void> _loadData() async {
    // Load thông tin user nếu xem profile người khác
    if (widget.userId != null) {
      await _loadUserInfo();
    }
    
    List<Future> futures = [_loadFriends()];
    
    // Chỉ load pending requests nếu đang xem profile của current user
    if (widget.userId == null) {
      futures.add(_loadPendingRequests());
    }
    
    await Future.wait(futures);
  }

  // Load danh sách bạn bè
  Future<void> _loadFriends() async {
    if (!mounted) return;

    setState(() {
      isLoadingFriends = true;
    });

    try {
      List<UserModel> friendsList;
      
      if (widget.userId != null) {
        // Lấy danh sách bạn bè của user khác
        friendsList = await FriendService.getUserFriends(widget.userId!);
      } else {
        // Lấy danh sách bạn bè của current user
        friendsList = await FriendService().getFriends();
      }
      
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
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"General.Error".tr()}: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  // Load thông tin user khi xem profile người khác
  Future<void> _loadUserInfo() async {
    if (widget.userId == null) return;
    
    try {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userData.exists && mounted) {
        setState(() {
          userInfo = UserModel.fromMap(userData.data()!, widget.userId!);
        });
      }
    } catch (e) {
      // Ignore error - sẽ hiển thị tên mặc định
      print('Error loading user info: $e');
    }
  }

  // Load danh sách lời mời kết bạn
  Future<void> _loadPendingRequests() async {
    if (!mounted) return;

    setState(() {
      isLoadingRequests = true;
    });

    try {
      final requestsList = await FriendService.getPendingRequests();
      if (mounted) {
        setState(() {
          pendingRequests = requestsList;
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingRequests = false;
        });
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"General.Error".tr()}: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend.Friends'.tr()),
        bottom: widget.userId != null 
            ? null // Không hiện tabs nếu xem profile người khác
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${"Friend.Friends".tr()} (${friends.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${"Friend.Friend Requests".tr()} (${pendingRequests.length})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: widget.userId != null 
          ? // Nếu xem profile người khác, chỉ hiện danh sách bạn bè
            _buildFriendsTab()
          : // Nếu xem profile của mình, hiện tabs
            TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsTab(),
                  _buildFriendRequestsTab(),
                ],
              ),
      floatingActionButton: widget.userId != null 
          ? null // Không hiện nút tìm kiếm khi xem profile người khác  
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WidgetSearch(),
                  ),
                ).then((_) {
                  // Refresh data khi quay lại từ search screen
                  _loadData();
                });
              },
              child: const Icon(Icons.person_search),
              tooltip: 'Friend.Search by email'.tr(),
            ),
    );
  }

  Widget _buildFriendsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return isLoadingFriends
        ? Center(child: CircularProgressIndicator())
        : friends.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Friend.You have no friends yet'.tr(),
                      style: textTheme.bodyLarge?.copyWith(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Friend.Lets find some'.tr(),
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadFriends,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return FriendCard(
                      friend: friends[index],
                      onUnfriend: _loadFriends, // Reload danh sách sau khi unfriend
                    );
                  },
                ),
              );
  }

  Widget _buildFriendRequestsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return isLoadingRequests
        ? Center(child: CircularProgressIndicator())
        : pendingRequests.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Friend.No new requests'.tr(),
                      style: textTheme.bodyLarge?.copyWith(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Friend.Friend request desc'.tr(),
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPendingRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> request = pendingRequests[index];
                    return FriendRequestCard(
                      sender: UserModel.fromMap(request['sender'], request['sender']['uid'] ?? ''),
                      friendship: request['friendship'],
                      onActionCompleted: _loadData, // Reload cả 2 tab
                    );
                  },
                ),
              );
  }
}
