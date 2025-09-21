import 'package:flutter/material.dart';
import 'setting.dart';
class MainProfile extends StatefulWidget {
  const MainProfile({super.key});

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Profile'),backgroundColor: Colors.white,),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    //Avatar
                    CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://example.com/profile.jpg')),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Name
                          Text('Anh Son', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              //posts
                              Column(
                                children: [
                                  Text('Posts', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  Text('120', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              //friends
                              Column(
                                children: [
                                  Text('Friends', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  Text('300', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                //Bio
                Container(
                  child: Text(
                    'This is a brief bio about the user. It can span multiple lines and give more information about the user.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                SizedBox(height: 15),
                //Button Edit Profile
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Setting()));
                  },
                  child: Text('Edit Profile'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          //vach ngan cach giua cac phan
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          //danh sach bai viet
          ListView.builder(
            shrinkWrap: true,// chiem dung bao nhieu cho no
            physics: NeverScrollableScrollPhysics(),// ko cho cuon vi co listview cha
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //User info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://example.com/profile.jpg')),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Anh Son', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('2 hours ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Spacer(),
                          IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
                        ],
                      ),
                      SizedBox(height: 10),
                      //Post content
                      Text(
                        'This is the content of the post. It can be a text description of what the user wants to share.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 10),
                      //Post image
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage('https://example.com/post_image.jpg'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 10),
                      //Like and comment buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(onPressed: () {}, icon: Icon(Icons.thumb_up_alt_outlined)),
                          IconButton(onPressed: () {}, icon: Icon(Icons.comment_outlined)),
                          IconButton(onPressed: () {}, icon: Icon(Icons.share_outlined)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
