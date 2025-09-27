import 'package:flutter/material.dart';
import 'package:blogapp/features/feed_Screen/post_card.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import 'setting.dart';

class MainProfile extends StatefulWidget {
  String? uid;
  MainProfile({super.key, this.uid});

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

  //ham widget tra ve avatar proflie
  // Trả về String? (URL) hoặc null nếu không có avatar
  Future<String?> getUserAvatarUrl() async {
    try {
      UserModel? user = await AuthService.getUser();
      if (user != null && user.photoURL.isNotEmpty) {
        return user.photoURL;
      } else {
        return null; // Không có avatar -> hiển thị icon
      }
    } catch (e) {
      print("Error getting user avatar: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '@${currentUser?.displayName ?? currentUser?.userName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        // shape: const RoundedRectangleBorder(
        //   borderRadius: BorderRadius.vertical(
        //     bottom: Radius.circular(15),
        //   ),
        // ),
        // iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
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
                            child:
                                avatarUrl !=
                                    null //check dk neu avatarUrl ko bang null
                                ? Image.network(
                                    //nhay vao day neu true
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
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
                            '@${currentUser?.displayName ?? currentUser?.userName}',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                    '${currentUser?.followers ?? 0}',
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
                                    '${currentUser?.following ?? 0}',
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
                const SizedBox(height: 15),
                // Container chứa bio/mô tả người dùng
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${currentUser?.bio ?? "This is the user bio."}',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 15),
                // Button Edit Profile
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Setting()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1),
                    minimumSize: const Size(
                      150,
                      35,
                    ), // giảm chiều rộng và chiều cao
                    padding: const EdgeInsets.symmetric(
                      horizontal: 140,
                      vertical: 15,
                    ), // padding nhỏ hơn
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
          // Danh sách bài viết của user
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return PostCard();
            },
          ),
        ],
      ),
    );
  }
}
