import 'package:flutter/material.dart';
import '../../services/friend_services.dart';
import '../../models/user_model.dart';
import '../auth/widgets/friend_card.dart';
import '../auth/widgets/friend_request_card.dart';
import '../search_page/search_page.dart';
import 'package:easy_localization/easy_localization.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(); // Load initial data
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load cả friends và pending requests
  Future<void> _loadData() async {
    await Future.wait([
      _loadFriends(),
      _loadPendingRequests(),
    ]);
  }

  // Load danh sách bạn bè
  Future<void> _loadFriends() async {
    if (!mounted) return;

    setState(() {
      isLoadingFriends = true;
    });

    try {
      final friendsList = await FriendService().getFriends();
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
            content: Text('${"General.Error".tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"General.Error".tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  Text('${('Friend.Friends'.tr())} (${friends.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add),
                  const SizedBox(width: 8),
                  Text('${('Friend.Friend Requests'.tr())} (${pendingRequests.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Danh sách bạn bè
          isLoadingFriends
              ? Center(child: CircularProgressIndicator())
              : friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Friend.You have no friends yet.'.tr(),
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Friend.Lets find some!'.tr(),
                            style: const TextStyle(color: Colors.grey),
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
                    ),

          // Tab 2: Lời mời kết bạn
          isLoadingRequests
              ? Center(child: CircularProgressIndicator())
              : pendingRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Friend.No new requests'.tr(),
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Friend.Friend request desc'.tr(),
                            style: const TextStyle(color: Colors.grey),
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
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
}
