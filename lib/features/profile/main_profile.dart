// Import các package cần thiết cho Flutter UI
import 'package:flutter/material.dart';
import 'setting.dart';

// MainProfile - Widget StatefulWidget để hiển thị trang profile người dùng
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
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
      ),

      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                // Row chứa avatar và thông tin user
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage('https://example.com/profile.jpg'),
                    ),
                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anh Son',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                          ),

                          // Row chứa thống kê Posts và Friends
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Cột Posts - hiển thị số bài viết
                              Column(
                                children: [
                                  Text('Posts', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  Text('120', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              // Cột Friends - hiển thị số bạn bè
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

                // Container chứa bio/mô tả người dùng
                Container(
                  child: Text(
                    'This is a brief bio about the user. It can span multiple lines and give more information about the user.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                SizedBox(height: 15),

                // Button Edit Profile - chuyển đến màn hình cài đặt
                TextButton(
                  onPressed: () {
                    // Navigation đến màn hình Setting khi nhấn button
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Setting())
                    );
                  },
                  child: Text('Edit Profile'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),

          // Danh sách bài viết của user - sử dụng ListView.builder để tạo danh sách động
          ListView.builder(
            shrinkWrap: true, // Chiếm đúng bao nhiêu không gian cần thiết
            physics: NeverScrollableScrollPhysics(), // Không cho scroll vì đã có ListView cha
            itemCount: 5, // Tạo 5 bài viết mẫu
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info - thông tin người đăng bài
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage('https://example.com/profile.jpg')
                          ),
                          SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Anh Son', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('2 hours ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Spacer(),

                          // Icon menu 3 chấm để hiện các option
                          IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
                        ],
                      ),
                      SizedBox(height: 10),

                      // Post content - nội dung bài viết (text)
                      Text(
                        'This is the content of the post. It can be a text description of what the user wants to share.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 10),

                      // Post image - hình ảnh của bài viết
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

                      // Like and comment buttons - các nút tương tác
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Nút like/thích
                          IconButton(
                            onPressed: () {}, // Chưa implement logic
                            icon: Icon(Icons.thumb_up_alt_outlined)
                          ),
                          // Nút comment/bình luận
                          IconButton(
                            onPressed: () {}, // Chưa implement logic
                            icon: Icon(Icons.comment_outlined)
                          ),
                          // Nút share/chia sẻ
                          IconButton(
                            onPressed: () {}, // Chưa implement logic
                            icon: Icon(Icons.share_outlined)
                          ),
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
