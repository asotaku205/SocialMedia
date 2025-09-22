import 'package:blogapp/resource/color.dart';
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage("https://example.com/"),
                ),
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                        ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'username',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '@noone',
                          ),
                        ],
                      ),
                    ),
                ),
                IconButton(
                    onPressed: (){
                      showDialog(context: context, builder: (context) => Dialog(
                        child: ListView(
                          padding: EdgeInsets.symmetric(vertical: 16,),
                          shrinkWrap:  true,
                          children: [
                            'Delete',
                          ].map((e) => InkWell(
                            onTap: (){},
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Text(e),
                            ),
                          ),
                          ).toList(),
                        ),
                      ));
                    },
                    icon: Icon(Icons.more_vert),
                ),
              ],
            ),
            //image section
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height*0.35,
            width: double.infinity,
            child: Image.network(
                'data:image/jpeg;base64,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',
                  fit: BoxFit.cover,
                 ),
          ),
          //like, comment setion
          Row(
            children: [
              IconButton(
                  onPressed: (){},
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
              ),
              IconButton(
                onPressed: (){},
                icon: Icon(
                  Icons.comment_outlined,
                ),
              ),
              IconButton(
                onPressed: (){},
                icon: Icon(
                  Icons.send,
                ),
              ),
              Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      onPressed: (){},
                      icon: Icon(Icons.bookmark_border),
                    ),
                  )
              ),
            ],
          ),
          //description and number of comment
          Container(
            padding:  EdgeInsets.symmetric(horizontal: 16,),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: (Theme.of(context).textTheme.titleSmall ??
                      const TextStyle()).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  child: Text(
                    '1Tr+ like',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                   width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 8,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: secondaryColor),
                      children: [
                        TextSpan(
                          text: 'username',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '  commment by user will be show here',
                        ),
                      ]
                    ),
                  ),
                ),
                InkWell(
                  onTap: (){},
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all n comment',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'yy/mm/dd',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
