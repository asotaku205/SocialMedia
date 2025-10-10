import "package:blogapp/features/createpost/upload_image.dart";
import "package:blogapp/services/auth_service.dart";
import "package:blogapp/services/post_services.dart";
import "package:flutter/material.dart";
import "dart:io";
import 'package:icons_plus/icons_plus.dart';
import 'package:blogapp/models/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

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

  // State để quản lý loading và thông tin user
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Lấy thông tin người dùng và lưu vào state để tái sử dụng
  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getUser();
    if (mounted) { // Kiểm tra để chắc chắn widget vẫn còn tồn tại
      setState(() {
        _currentUser = user;
      });
    }
  }

  /// Hàm chọn ảnh từ thư viện
  Future<void> _uploadImage() async {
    final image = await _uploadService.uploadFromGallery();
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  /// Hàm xóa ảnh đã chọn
  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }
  
  /// Hàm xử lý logic đăng bài hoàn chỉnh
  Future<void> _sharePost() async {
    // Kiểm tra form có hợp lệ không
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true; // Bật trạng thái loading
    });

    // Gọi PostService để tạo bài viết, truyền cả nội dung và file ảnh
    final result = await PostService.createPost(
      content: _commentController.text.trim(),
      imageFile: _imageFile,
    );
    
    // Tắt loading sau khi hoàn tất
    if (mounted) {
       setState(() {
        _isLoading = false;
      });
    }

    if (result == 'success' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Posts.Post created successfully".tr()), backgroundColor: Colors.green),
      );
      setState(() {
        _commentController.clear();
        _imageFile=null;
      });
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('General.Error'.tr()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          "Posts.Create Post".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 25,
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
                    // Hiển thị thông tin user từ state, không dùng FutureBuilder
                    Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 25,
                           backgroundImage: (_currentUser?.photoURL ?? '').isNotEmpty
                              ? NetworkImage(_currentUser!.photoURL)
                              : null,
                          child: _currentUser == null
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : (_currentUser!.photoURL.isEmpty
                                  ? Text(
                                      _currentUser!.displayName.isNotEmpty
                                          ? _currentUser!.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null),
                        ),
                        const SizedBox(width: 12),
                        // Tên người dùng
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.displayName ?? "General.Loading".tr(),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text("Posts.Share your thoughts".tr(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // Ô nhập text
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Posts.What's on your mind?".tr(),
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        validator: (value) {
                          // Chỉ báo lỗi nếu cả text và ảnh đều rỗng
                          if ((value == null || value.trim().isEmpty) && _imageFile == null) {
                            return "Posts.The post must have content or an image".tr();
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        minLines: 5,
                        maxLines: null,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phần chọn ảnh
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _imageFile != null ? 280 : 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      ),
                      child: _imageFile == null
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
                                    child: const Icon(BoxIcons.bx_image_add, size: 32, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Posts.Add Photo".tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text("Posts.Tap to choose from gallery".tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                                    child: IconButton(
                                      onPressed: _removeImage,
                                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 100), // Khoảng trống cho nút ở dưới
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Nút gửi đi
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 20, top: 20),
        color: Colors.black,
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sharePost, // Vô hiệu hóa nút khi đang loading
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              disabledBackgroundColor: Colors.grey[800], // Màu khi nút bị vô hiệu hóa
            ),
            child: _isLoading
                // Hiển thị vòng xoay khi đang loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text("Posts.Share Post".tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}