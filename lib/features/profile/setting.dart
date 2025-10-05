import 'package:flutter/material.dart';
import '../auth/screens/login_page.dart';
import 'edit_profile.dart';
import '../../../services/auth_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../auth/screens/forgot_password_page.dart';
import '../../../models/user_model.dart';

class Setting extends StatefulWidget {
  final String? uid;
  
  const Setting({super.key, this.uid});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
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
  logout() async {
    await AuthService.logout();
    if (mounted) return
      Navigator.pop(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 25,
            ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getUser,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  // Header User
                  Center(
                    child: Column(
                      children: [
                        // Avatar đơn giản với CircleAvatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty
                              ? NetworkImage(currentUser!.photoURL!)
                              : null,
                          child: currentUser!.photoURL!.isEmpty
                           ? const Icon(Icons.person)
                        : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentUser?.displayName?.isNotEmpty == true
                              ? currentUser!.displayName!
                              : currentUser?.userName?.isNotEmpty == true
                                  ? currentUser!.userName!
                                  : "Username",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUser?.email?.isNotEmpty == true
                              ? currentUser!.email!
                              : "Email",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        if (currentUser?.bio?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              currentUser!.bio!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey, thickness: 1),
                  const SizedBox(height: 20,),
                  // Edit Profile
                  ListTile(
                    leading: const Icon(BoxIcons.bx_user),
                    title: const Text('Edit Profile', style: TextStyle(fontSize: 16, color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfile())
                      );

                      // Refresh user data khi quay lại từ edit profile
                      if (result == true) {
                        await _getUser();
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: const Color(0xFF1F1F1F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 10),

                  // Change Password
                  ListTile(
                    leading: const Icon(BoxIcons.bx_lock),
                    title: const Text('Change Password', style: TextStyle(fontSize: 16, color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: const Color(0xFF1F1F1F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 30),

                  // Log Out Button
                  Center(
                    child: Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
