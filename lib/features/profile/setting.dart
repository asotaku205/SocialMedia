// Import các package cần thiết cho Flutter UI
import 'package:flutter/material.dart';
import 'edit_profile.dart';
import '../../../services/auth_service.dart';


// Setting - Widget StatefulWidget để hiển thị màn hình cài đặt
class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  //logout
  logout() async{
    await AuthService.logout();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: Colors.white,
      ),

      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // Phần header hiển thị thông tin user
            Center(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Text('Anh Son', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('email', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 10),
                ],
              ),
            ),

            const Divider(),

            // ListTile cho Edit Profile
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Edit Profile'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigation đến màn hình EditProfile khi tap
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile())
                );
              },
            ),

            const Divider(),

            // ListTile cho Change Password
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Change Password'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to change password screen
              },
            ),

            const Divider(),
            SizedBox(height: 18),

            // Phần chọn theme mode (Light/Dark)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implement light mode logic
                    },
                    child: Text(
                      'Light Mode',
                      style: TextStyle(fontSize: 16, color: Colors.grey)
                    )
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement dark mode logic
                    },
                    child: Text(
                      'Dark Mode',
                      style: TextStyle(fontSize: 16, color: Colors.grey)
                    )
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),

            // Button Log Out - nút đăng xuất
            Center(
              child: ElevatedButton(
                onPressed: () {
                  logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, color: Colors.white)
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}
