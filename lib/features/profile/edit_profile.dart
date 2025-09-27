// Import package Flutter UI cần thiết
import 'package:blogapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// EditProfile - Widget StatefulWidget để chỉnh sửa thông tin profile
class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

// State class chứa logic và UI cho EditProfile
class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  UserModel? currentUser;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController photoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserModel? user = await AuthService.getUser();
      if (user != null) {
        setState(() {
          currentUser = user;
          nameController.text = user.displayName ?? '';
          bioController.text = user.bio ?? '';

        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      String result = await AuthService.updateProfile(
        displayName: nameController.text.trim(),
        bio: bioController.text.trim(),
      );

      if (result == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Quay lại màn hình trước
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              child: ListView(
                children: [
                  // Header hiển thị avatar và tên user hiện tại
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        GestureDetector(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty)
                                    ? NetworkImage(currentUser!.photoURL!)
                                    : const NetworkImage("https://picsum.photos/100/100?random=1"),
                              ),
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                          onTap: () {
                            // TODO: Implement image picker
                          }
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentUser?.displayName ?? 'Loading...',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form field để chỉnh sửa tên
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Form field để chỉnh sửa bio
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button Save Changes
                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
