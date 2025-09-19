import "package:blogapp/createpost/upload_image.dart";
import "package:flutter/material.dart";
import "dart:io";

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  //khởi tạo đối tượng uploadimg
  final UploadImageService _uploadService = UploadImageService();
  File? _imageFile; // Lưu ảnh đã chọn

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Tiêu đề với nút thoát
      appBar: AppBar(
        title: const Text(
          "Create Post",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.close, size: 25)),
        ],
      ),
      resizeToAvoidBottomInset: true,

      body: SingleChildScrollView(
        //để cuộn nội dung xuống được
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 80,
          //set padding bên dưới cho giao diện dài ra khi bàn phím hiện lên ko bị che các
          //widget khác
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ô tải ảnh
                Container(
                  margin: const EdgeInsets.all(20),
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: _imageFile == null
                      //nếu image vẫn null thì chạy vào đoạn code ở dưới
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _uploadImage,
                              icon: const Icon(Icons.add, size: 72),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Add image here",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        )
                      //nếu image ko null ảnh sẽ hiên ra ở container
                      : ClipRRect(//dùng widget này để cắt nội dung bo góc đúng với container bo góc
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(//hiển thị ảnh từ 1 file cục bộ trên máy
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
                // Ô nhập text
                Container(
                  margin: const EdgeInsets.all(20),
                  child: TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: "What's on your mind?",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "This field is required";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.multiline, //tự động xuống dòng
                    minLines: 7, //5 dòng mà tối thiểu
                    maxLines: null, //ko giới hạn số dòng
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // button create post
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                //đk trong if chạy tất cả các validate nếu true hết thì chạy
                //câu lệnh bên trong if
                debugPrint("Post created: ${_commentController.text}");
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFF6f61ef),
            ),
            child: const Text(
              "Create Post",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
