import 'package:flutter/material.dart';
import 'edit_profile.dart';
class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: Colors.white,

      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            Center(
              child: Column(

                children: [
                    SizedBox(height: 10),
                    Text('Anh Son',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)),
                   SizedBox(height: 10),
                  Text('email',style: TextStyle(fontSize: 16,color: Colors.grey)),
                  SizedBox(height: 10),

                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Edit Profile'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile()));
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Change Password'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to notifications settings
              },
            ),
            const Divider(),
            SizedBox(height: 18),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Light Mode
                  TextButton(onPressed: (){}, child: Text('Light Mode',style: TextStyle(fontSize: 16,color: Colors.grey),)),
                  //Dark Mode
                  TextButton(onPressed: (){}, child: Text('Dark Mode',style: TextStyle(fontSize: 16,color: Colors.grey),)),
                ],
              ),
            ),
            SizedBox(height: 18),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle logout logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Log Out', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      )
    );
  }
}
