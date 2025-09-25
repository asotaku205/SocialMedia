import 'package:flutter/material.dart';
import 'chat_detail.dart';
class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatDetail()),
          );
          },
        child: Container(
          padding: EdgeInsets.only(left: 16,right: 16,top: 10,bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                          "https://picsum.photos/200", // Ảnh random
                        ),
                      ),
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "John Doe",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6,),
                            Text('em chào đại ca ạ' ,style: TextStyle(fontSize: 13,color: Colors.grey.shade600, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text('vừa xong',style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),),
            ],
          ),
        ),

        );

  }
}
