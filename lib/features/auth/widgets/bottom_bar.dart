import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../profile/setting.dart';
import '../../feed_Screen/main_feed.dart';
import '../../profile/main_profile.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: currentIndex,
          onTap: navigatePage,
          items:  [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setting',),
          ],
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onChanged,
        children: [
          FeedScreen(),
          Center(child: Text('Search Page')),
          MainProfile(uid: _auth.currentUser!.uid),
          Setting(), // Profile Page
        ],
      ),
    );
  }
}
