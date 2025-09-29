import 'package:blogapp/features/profile/post_profile.dart';
import 'package:flutter/material.dart';
import 'package:blogapp/features/feed_Screen/post_card.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import 'friends_screen.dart';
import 'setting.dart';

class MainProfile extends StatefulWidget {
  final String? uid;
  const MainProfile({super.key, this.uid});

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  UserModel? currentUser;
  bool isLoading = true;

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
      String? uid = AuthService.currentUser?.uid;
      if (uid != null) {
        UserModel? user = await AuthService.getUser();
        setState(() {
          currentUser = user;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching user data: $e');
    }
  }

  // giả sử bạn có hàm getUserAvatarUrl() trong services
  Future<String?> getUserAvatarUrl() async {
    return currentUser?.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // đang loading
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
                                    child: avatarUrl != null
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          )
                                        : const Icon(
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
                                  const SizedBox(height: 10),
                                  // Row thống kê Posts và Friends
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: const [
                                          Text(
                                            'Posts',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '0', // TODO: count posts
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FriendsScreen(),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Friends',
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
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Button Edit Profile
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Setting(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey, thickness: 1),
                  // PostCard
                  const PostProfile(),
                ],
              ),
            ),
    );
  }
}
