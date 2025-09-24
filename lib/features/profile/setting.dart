import 'package:flutter/material.dart';
import 'edit_profile.dart';
import '../../../services/auth_service.dart';
import 'package:icons_plus/icons_plus.dart';
class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  logout() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Header User
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                      "https://picsum.photos/100/100?random=1",
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Anh Son',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'email@example.com',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => EditProfile()));
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
              // TODO: navigate to change password
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
    );
  }
}
