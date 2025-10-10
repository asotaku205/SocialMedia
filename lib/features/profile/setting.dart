import 'package:flutter/material.dart';
import '../auth/screens/login_page.dart';
import 'edit_profile.dart';
import '../../../services/auth_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../auth/screens/forgot_password_page.dart';
import '../../../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

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
        title: Text(
          'Settings.Settings'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 25,
            ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
                          backgroundImage: currentUser?.photoURL != null && currentUser!.photoURL.isNotEmpty
                              ? NetworkImage(currentUser!.photoURL)
                              : null,
                          child: currentUser!.photoURL.isEmpty
                           ? Text(
                                  currentUser?.userName.isNotEmpty == true
                                      ? currentUser!.userName[0].toUpperCase()
                                      : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                            : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentUser?.displayName.isNotEmpty == true
                              ? currentUser!.displayName
                              : currentUser?.userName.isNotEmpty == true
                                  ? currentUser!.userName
                                  : "Username",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUser?.email.isNotEmpty == true
                              ? currentUser!.email
                              : "Email",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        if (currentUser?.bio.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              currentUser!.bio,
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
                    title: Text('Profile.Edit Profile'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white)),
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
                    title: Text('Authentication.Reset Password'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white)),
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
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text('Settings.Language'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
                    onTap: () {
                      _showLanguageDialog(context);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: const Color(0xFF1F1F1F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 10),
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
                        child: Text(
                          'Settings.Logout'.tr(),
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // THÊM FUNCTION MỚI CHO LANGUAGE DIALOG
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Settings.Change Language'.tr(), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white),
                title: Text('Settings.English'.tr(), style: const TextStyle(color: Colors.white)),
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settings.Change Language'.tr()),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white),
                title: Text('Settings.Vietnamese'.tr(), style: const TextStyle(color: Colors.white)),
                trailing: context.locale.languageCode == 'vi'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('vi'));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settings.Change Language'.tr()),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('General.Cancel'.tr(), style: const TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}
