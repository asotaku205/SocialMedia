import 'package:blogapp/features/profile/post_profile.dart';
import 'package:blogapp/widgets/full_screen_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import 'friends_screen.dart';
import 'setting.dart';
import '../../utils/image_utils.dart';

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
    setState(() => isLoading = true);
    try {
      String? uid = AuthService.currentUser?.uid;
      if (uid != null) {
        UserModel? user = await AuthService.getUser();
        setState(() {
          currentUser = user;
          isLoading = false;
        });
        await AuthService.syncPostCount(currentUser!.uid);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print('Error fetching user data: $e');
    }
  }

  Future<String?> getUserAvatarUrl() async {
    return currentUser?.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        title: Text(
          "Profile.Profile".tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.end,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                                  onTap: () {
                                    final url = currentUser?.photoURL;
                                    if (url != null && url.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImage(
                                            imageUrl: url,
                                            heroTag: 'profile_avatar',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Hero(
                                    tag: 'profile_avatar',
                                    child: ImageUtils.buildAvatar(
                                      imageUrl: currentUser?.photoURL,
                                      radius: 40,
                                      child: currentUser?.photoURL == null || 
                                             currentUser!.photoURL.isEmpty
                                          ? Text(
                                              currentUser?.displayName != null &&
                                                      currentUser!.displayName.isNotEmpty
                                                  ? currentUser!.displayName[0].toUpperCase()
                                                  : '?',
                                              style: textTheme.displayLarge?.copyWith(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentUser?.displayName ?? currentUser?.userName ?? "Username"}',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            "Posts.Posts".tr(),
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurface.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${currentUser?.postCount ?? 0}",
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onBackground,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const FriendsScreen(),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Text(
                                              "Friend.Friends".tr(),
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${currentUser?.friendCount ?? 0}',
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onBackground,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
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
                        // Container chứa bio/mô tả người dùng
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${currentUser?.bio ?? "This is the user bio."}',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                            foregroundColor: colorScheme.onBackground,
                            side: BorderSide(
                              color: colorScheme.onBackground,
                              width: 1,
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text("Profile.Edit Profile".tr()),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: colorScheme.onSurface.withOpacity(0.2)),
                      ],
                    ),
                  ),
                  PostProfile(),
                ],
              ),
            ),
    );
  }
}
