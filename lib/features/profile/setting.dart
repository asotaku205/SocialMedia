import 'package:flutter/material.dart';
import '../auth/screens/login_page.dart';
import 'edit_profile.dart';
import '../../../services/auth_service.dart';
import 'package:icons_plus/icons_plus.dart';
import '../auth/screens/forgot_password_page.dart';
import '../../../models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme_switcher_tile.dart';
import '../../utils/image_utils.dart';

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
    if (mounted) {
      // Dùng pushAndRemoveUntil để xóa toàn bộ navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false, // Xóa tất cả routes trước đó
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings.Settings'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
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
                        // Avatar với ImageUtils
                        ImageUtils.buildAvatar(
                          imageUrl: currentUser?.photoURL,
                          radius: 50,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          context: context,
                          child: (currentUser?.photoURL == null || currentUser!.photoURL.isEmpty)
                              ? Text(
                                  currentUser?.userName.isNotEmpty == true
                                      ? currentUser!.userName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
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
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUser?.email.isNotEmpty == true
                              ? currentUser!.email
                              : "Email",
                          style: TextStyle(fontSize: 16, color: colorScheme.secondary),
                        ),
                        if (currentUser?.bio.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              currentUser!.bio,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: colorScheme.secondary, thickness: 1),
                  const SizedBox(height: 20,),
                  // Edit Profile
                  ListTile(
                    leading: Icon(BoxIcons.bx_user, color: colorScheme.primary),
                    title: Text('Profile.Edit Profile'.tr(), style: TextStyle(fontSize: 16, color: textColor)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.secondary),
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
                    tileColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 10),

                  // Change Password
                  ListTile(
                    leading: Icon(BoxIcons.bx_lock, color: colorScheme.primary),
                    title: Text('Authentication.Reset Password'.tr(), style: TextStyle(fontSize: 16, color: textColor)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.secondary),
                    onTap: () {
                      Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 10),
                  
                  ListTile(
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: Text('Settings.Language'.tr(), style: TextStyle(fontSize: 16, color: textColor)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.secondary),
                    onTap: () {
                      _showLanguageDialog(context);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 10),
                  // Theme Switcher
                  ThemeSwitcherTile(),
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
                            color: colorScheme.primary.withOpacity(0.2),
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
                          style: TextStyle(fontSize: 16, color: textColor),
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
        final colorScheme = Theme.of(context).colorScheme;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;
        return AlertDialog(
          backgroundColor: colorScheme.background,
          title: Text('Settings.Change Language'.tr(), style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.language, color: textColor),
                title: Text('Settings.English'.tr(), style: TextStyle(color: textColor)),
                trailing: context.locale.languageCode == 'en'
                    ? Icon(Icons.check, color: Colors.green)
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
                leading: Icon(Icons.language, color: textColor),
                title: Text('Settings.Vietnamese'.tr(), style: TextStyle(color: textColor)),
                trailing: context.locale.languageCode == 'vi'
                    ? Icon(Icons.check, color: Colors.green)
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
              child: Text('General.Cancel'.tr(), style: TextStyle(color: colorScheme.secondary)),
            ),
          ],
        );
      },
    );
  }
}
