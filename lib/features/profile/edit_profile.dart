// Import package Flutter UI cần thiết
import 'package:flutter/material.dart';

// EditProfile - Widget StatefulWidget để chỉnh sửa thông tin profile
class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

// State class chứa logic và UI cho EditProfile
class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
      ),

      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            // Header hiển thị avatar và tên user hiện tại
            Center(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://example.com/profile.jpg'),
                  ),
                  SizedBox(height: 10),
                  Text('Anh Son', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Form field để chỉnh sửa tên
            Container(
              padding: EdgeInsets.all(10),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
              ),
            ),
            SizedBox(height: 10),

            // Form field để chỉnh sửa email
            Container(
              padding: EdgeInsets.all(10),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ),
            SizedBox(height: 10),

            // Form field để chỉnh sửa bio (mô tả) - cho phép nhiều dòng
            Container(
              padding: EdgeInsets.all(10),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Bio',
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 20),

            // Button Save Changes - lưu các thay đổi
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save profile changes logic
                  // Chưa implement logic lưu thay đổi profile
                },
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
