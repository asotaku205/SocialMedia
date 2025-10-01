import 'package:blogapp/features/createpost/createpost.dart';
import 'package:blogapp/features/search_page/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../profile/setting.dart';
import '../../feed_Screen/main_feed.dart';
import '../../profile/main_profile.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../profile/friends_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() =>
      _BottomNavigationState();
}

int currentIndex = 0;

class _BottomNavigationState
    extends State<BottomNavigation> {
  late PageController pageController;
  final FirebaseAuth _auth =
      FirebaseAuth.instance;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          currentIndex: currentIndex,
          onTap: navigatePage,
          items: [
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_plus,),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_group),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_user),
              label: 'Profile',
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
          MainProfile(
            uid: _auth.currentUser!.uid,
          ),
        ],
      ),
    );
  }
}
