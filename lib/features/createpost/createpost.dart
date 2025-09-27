import "package:blogapp/features/createpost/upload_image.dart";
import "package:blogapp/services/auth_service.dart";
import "package:blogapp/services/post_services.dart";
import "package:flutter/material.dart";
import "dart:io";
import 'package:icons_plus/icons_plus.dart';
import 'package:blogapp/models/user_model.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final UploadImageService _uploadService = UploadImageService();
  File? _imageFile;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    final image = await _uploadService.uploadFromGallery();
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  //ham lay ten user
  Future<String> getNameUser() async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        return user.displayName; // lay ten nguoi dung
      } else {
        return "Unknown User";
      }
    } catch (e) {
      print('Error getting user name: $e');
      return "Unknown User";
    }
  }

  //ham widget tra ve avatar proflie
  // Trả về String? (URL) hoặc null nếu không có avatar
  Future<String?> getUserAvatarUrl() async {
    try {
      UserModel? user = await AuthService.getUser();
      if (user != null && user.photoURL.isNotEmpty) {
        return user.photoURL;
      } else {
        return null; // Không có avatar -> hiển thị icon
      }
    } catch (e) {
      print("Error getting user avatar: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        //Tiêu đề
        title: const Text(
          "Create Post",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Phần hiện profile
                    Row(
                      children: [
                        //ô avatar
                        FutureBuilder<String?>(
                          future: getUserAvatarUrl(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // Neu dang trang thai cho se hien ra loading
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              );
                            }

                            String? avatarUrl = snapshot.data;
                            //gan URL tu snapshot cho bien avatarURL

                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child:
                                    avatarUrl !=
                                        null //check dk neu avatarUrl ko bang null
                                    ? Image.network(
                                        //nhay vao day neu true
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      )
                                    : const Icon(
                                        //nhay vao day neu false
                                        Icons.person,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //Tên
                            FutureBuilder<String>(
                              future: getNameUser(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  //neu dang o trang thai cho se tra ve text Loading
                                  return Text(
                                    "Loading...",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  //neu xay ra loi se tra ve text Error
                                  return Text(
                                    "Error",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  );
                                } else {
                                  return Text(
                                    snapshot.data ??
                                        "Your Name", //neu napshot.data null se tra ve text Your Name
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Share your thoughts...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Ô nhập text bài viết
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      child: TextFormField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        //check giá trị nếu null hoặc rỗng hiện ra thông báo đỏ
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please share your thoughts";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 5,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phần app load ảnh
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _imageFile != null ? 280 : 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child:
                          _imageFile ==
                              null // nếu biến _imageFile ko null thì nhảy vào
                          //phần chỉ hiện logo và text nếu khi đã chọn ảnh _imageFile có giá trị
                          //hình ảnh sẽ đc hiển
                          ? InkWell(
                              onTap: _uploadImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      BoxIcons.bx_image_add,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Add Photo",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Tap to choose from gallery",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      onPressed: _removeImage,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.photo,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Photo added",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 100), // space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // button gửi đi
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        color: Colors.black,
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                // Lấy nội dung text
                String content = _commentController.text.trim();

                // Gọi hàm createPost để lưu lên Firebase
                String result = await PostService.createPost(
                  content: content,
                  imageFile: _imageFile,
                );

                if (result == 'success') {
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Post created successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Reset trạng thái sau khi gửi
                  setState(() {
                    _imageFile = null;
                    _commentController.clear();
                  });
                } else {
                  // Hiển thị lỗi nếu không thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Share Post",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
