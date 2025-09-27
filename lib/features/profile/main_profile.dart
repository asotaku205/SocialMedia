import 'package:flutter/material.dart';
import '../feed_Screen/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${currentUser?.userName ?? currentUser?.displayName ?? "Profile"}',
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
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
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: const NetworkImage(
                              "https://picsum.photos/100/100?random=1",
                            ),
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
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Button Edit Profile
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Setting()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1),
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
                const PostCard(),
              ],
            ),
          ),
    );
  }
}