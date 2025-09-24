import 'package:flutter/material.dart';
import '../profile/main_profile.dart';
import 'comment_ui.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Danh sách trạng thái "xem thêm" cho mỗi post
  final List<bool> expanded = List.generate(5, (_) => false);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            String content =
                "This is the content of the post. It can be a text description of what the user wants to share. "
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus feugiat commodo felis, "
                "ac tincidunt nisi ultrices sed.";

            bool isLong = content.length > 100;
            bool isExpanded = expanded[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainProfile()),
                            );
                          },
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                    'https://example.com/profile.jpg'),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Anh Son',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text('2 hours ago',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                            onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Post content with "See more"
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CommentUi()),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpanded || !isLong
                                ? content
                                : content.substring(0, 100) + "...",
                            style: const TextStyle(fontSize: 14),
                            softWrap: true,
                          ),
                          if (isLong)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  expanded[index] = !isExpanded;
                                });
                              },
                              child: Text(
                                isExpanded ? "Ẩn bớt" : "Xem thêm",
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Post image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image:
                          NetworkImage('https://example.com/post_image.jpg'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Like - Comment - Share
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.thumb_up_alt_outlined)),
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CommentUi()),
                              );
                            },
                            icon: const Icon(Icons.comment_outlined)),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_outlined)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
