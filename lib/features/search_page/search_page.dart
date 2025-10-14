import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/user_model.dart';
import '../../services/friend_services.dart';
import '../profile/other_user_profile_screen.dart';
import 'box_profile.dart';

class WidgetSearch extends StatefulWidget {
  const WidgetSearch({super.key});

  @override
  State<WidgetSearch> createState() => _WidgetSearchState();
}

class _WidgetSearchState extends State<WidgetSearch> {
  final TextEditingController _searchController = TextEditingController();
  bool _showButtons = false;
  String _searchType = "user";
  String _keyword = "";

  // Biến quản lý search results
  List<UserModel> searchResults = [];
  bool isSearching = false;
  Map<String, String> friendshipStatuses = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Search.Please enter keyword".tr()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _showButtons = true;
        _searchType = "user";
        _keyword = _searchController.text;
      });

      if (_searchType == "user") {
        _searchUsers(_keyword);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query
        .trim()
        .length < 2) return;

    setState(() {
      isSearching = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      String? currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        setState(() {
          isSearching = false;
        });
        return;
      }

      String searchQuery = query.trim().toLowerCase();

      final allUsersQuery = await firestore
       .collection('users')
       .limit(100)
       .get();
      Set<String> addedUserIds = {};
      List<UserModel> results = [];
      for (var doc in allUsersQuery.docs) {
        if (doc.id != currentUserId && !addedUserIds.contains(doc.id)) {
          try {
            UserModel user = UserModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            // Kiểm tra nếu query có trong displayName hoặc userName
            String displayNameLower = user.displayName.toLowerCase();
            String userNameLower = user.userName.toLowerCase();
            if (displayNameLower.contains(searchQuery) ||
                userNameLower.contains(searchQuery)) {
              results.add(user);
              addedUserIds.add(doc.id);
            }
          } catch (e) {
            print('Error parsing user ${doc.id}: $e');
          }
        }
      }


      // Sắp xếp kết quả theo độ ưu tiên
      results.sort((a, b) {
        String aDisplayName = a.displayName.toLowerCase();
        String aUserName = a.userName.toLowerCase();
        String bDisplayName = b.displayName.toLowerCase();
        String bUserName = b.userName.toLowerCase();

        // Ưu tiên exact match
        if (aDisplayName == searchQuery || aUserName == searchQuery) return -1;
        if (bDisplayName == searchQuery || bUserName == searchQuery) return 1;

        // Ưu tiên starts with
        if (aDisplayName.startsWith(searchQuery) && !bDisplayName.startsWith(searchQuery)) return -1;
        if (bDisplayName.startsWith(searchQuery) && !aDisplayName.startsWith(searchQuery)) return 1;
        if (aUserName.startsWith(searchQuery) && !bUserName.startsWith(searchQuery)) return -1;
        if (bUserName.startsWith(searchQuery) && !aUserName.startsWith(searchQuery)) return 1;

        // Sắp xếp theo số lượng bạn bè
        return b.friendCount.compareTo(a.friendCount);
      });
      // Giới hạn kết quả hiển thị
      if (results.length > 20) {
        results = results.take(20).toList();
      }

      Map<String, String> statuses = {};
      for (UserModel user in results) {
        try {
          final status = await FriendService.getFriendshipStatus(user.uid);
          statuses[user.uid] = status;
        } catch (e) {
          statuses[user.uid] = 'none';
        }
      }

      if (mounted) {
        setState(() {
          searchResults = results;
          friendshipStatuses = statuses;
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSearching = false;
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
  void initState() {
    super.initState();

    // Thêm listener cho real-time search
    _searchController.addListener(() {
      if (_searchController.text.length >= 2) {
        // Delay 500ms để tránh search quá nhiều
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_searchController.text.length >= 2) {
            setState(() {
              _keyword = _searchController.text;
              _showButtons = true;
              _searchType = "user";
            });
            _searchUsers(_keyword);
          }
        });
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _showButtons = false;
          searchResults.clear();
          friendshipStatuses.clear();
        });
      }
    });
  }
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search.Search".tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: colorScheme.onBackground,
          ),
        ),
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search.Searching for users".tr(),
                prefixIcon: Icon(BoxIcons.bx_search, color: colorScheme.onSurface),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              onSubmitted: (value) {
                _onSearch();
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            // Buttons phân loại khi đã tìm kiếm
            _showButtons == true
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchType = "user";
                    });
                    if (_keyword.isNotEmpty) {
                      _searchUsers(_keyword);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Profile.Profile".tr(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _searchType == "user" ? colorScheme.onBackground : colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: _searchType == "user" ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 50,
                        color: _searchType == "user" ? colorScheme.onBackground : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchType = "post";
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Posts.Posts".tr(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _searchType == "post" ? colorScheme.onBackground : colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: _searchType == "post" ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 50,
                        color: _searchType == "post" ? colorScheme.onBackground : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            )
                : const SizedBox(),

            const SizedBox(height: 16),

            // Nội dung chính - tất cả trong build method duy nhất
            Expanded(
              child: !_showButtons
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Search.Searching for users'.tr(),
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Search.Enter name or username'.tr(), style: theme.textTheme.bodySmall?.copyWith(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
              )
                  : _searchType != "user"
                  ? Center(
                  child: Text('Search.Post search coming soon'.tr(), style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 16)))
                  : isSearching
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Search.Searching please wait'.tr(), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                  ],
                ),
              )
                  : searchResults.isEmpty && _keyword.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Search.No results found'.tr(),
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('${'Search.No users found with keyword'.tr()} "$_keyword"',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.4)), textAlign: TextAlign.center),
                  ],
                ),
              )
                  : searchResults.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('${searchResults.length} ${'Search.results found'.tr()}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        UserModel user = searchResults[index];
                        String friendshipStatus = friendshipStatuses[user.uid] ?? 'none';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: BoxProfile(
                            user: user,
                            friendshipStatus: friendshipStatus,
                            onFriendshipChanged: () {
                              // Refresh friendship status
                              FriendService.getFriendshipStatus(user.uid).then((status) {
                                if (mounted) {
                                  setState(() {
                                    friendshipStatuses[user.uid] = status;
                                  });
                                }
                              }).catchError((e) {
                                print('Error refreshing status: $e');
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
