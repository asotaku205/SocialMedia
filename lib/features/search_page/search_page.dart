import 'package:blogapp/features/search_page/box_profile.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class WidgetSearch extends StatefulWidget {
  const WidgetSearch({super.key});

  @override
  State<WidgetSearch> createState() =>
      _WidgetSearchState();
}

class _WidgetSearchState
    extends State<WidgetSearch> {
  final TextEditingController _searchController = TextEditingController();
  //khai báo biến để quản lí textfield
  bool _showButtons =
      false; // Có hiển thị 2 nút phân loại không
  String _searchType = "user"; // user | post
  String _keyword = ""; // từ khóa tìm kiếm
  @override
  Widget build(BuildContext context) {
    @override
    void dispose() {
      _searchController
          .dispose(); // Giải phóng bộ nhớ
      super.dispose();
    }

    void _onSearch() {
      if (_searchController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              " Please enter a search keyword",
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              "Searching for: ${_searchController.text}",
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _showButtons = true;
          _searchType = "user";
          _keyword = _searchController.text;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Search",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            50,
          ), // chiều cao phần dưới
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    "Enter search keyword...",
                prefixIcon: Icon(
                  BoxIcons.bx_search,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (value) {
                _onSearch();
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        child: Column(
          children: [
            //nếu khi textflied đc gửi đi sẽ showButtons == true để hiện nút phân loại button 
            _showButtons == true
                ? Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút Profile
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchType = "user";
                          });
                        },
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              "Profile",
                              style: TextStyle(
                                color:
                                    _searchType ==
                                        "user"
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight:
                                    _searchType ==
                                        "user"
                                    ? FontWeight
                                          .bold
                                    : FontWeight
                                          .normal,
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.only(
                                    top: 4,
                                  ),
                              height: 2,
                              width: 50,
                              color:
                                  _searchType ==
                                      "user"
                                  ? Colors.white
                                  : Colors
                                        .transparent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Nút Post
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchType = "post";
                          });
                        },
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              "Post",
                              style: TextStyle(
                                color:
                                    _searchType ==
                                        "post"
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight:
                                    _searchType ==
                                        "post"
                                    ? FontWeight
                                          .bold
                                    : FontWeight
                                          .normal,
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.only(
                                    top: 4,
                                  ),
                              height: 2,
                              width: 50,
                              color:
                                  _searchType ==
                                      "post"
                                  ? Colors.white
                                  : Colors
                                        .transparent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : BoxProfile(),
                //mặc định khi chưa tìm kiếm sẽ hiện các box profile
          ],
        ),
      ),
    );
  }
}
