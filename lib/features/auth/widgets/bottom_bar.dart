import 'package:blogapp/features/createpost/createpost.dart';
import 'package:blogapp/features/search_page/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../feed_Screen/main_feed.dart';
import '../../profile/main_profile.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../profile/friends_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/friend_services.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

int currentIndex = 0;

class _BottomNavigationState extends State<BottomNavigation> {
  late PageController pageController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  onChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  navigatePage(int page) {
    pageController.jumpToPage(page);
  }

  Widget _buildIconWithBadge(IconData icon, Stream<int> countStream) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: isDark ? Colors.white : Colors.black,
          unselectedItemColor: Colors.grey[600],
          currentIndex: currentIndex,
          onTap: navigatePage,
          items: [
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_home),
              label: 'Navigation.Home'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_search),
              label: 'Search.Search'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_plus),
              label: 'Navigation.Add'.tr(),
            ),
            BottomNavigationBarItem(
              icon: _buildIconWithBadge(
                BoxIcons.bx_group,
                FriendService.getPendingRequestsCount(),
              ),
              label: 'Friend.Friends'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_user),
              label: 'Profile.Profile'.tr(),
            ),
          ],
          //Ẩn label của mỗi item
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 25,
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onChanged,
        children: [
          FeedScreen(),
          WidgetSearch(),
          CreatePost(),
          FriendsScreen(),
          MainProfile(uid: _auth.currentUser!.uid),
        ],
      ),
    );
  }
}
