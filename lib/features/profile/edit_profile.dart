// Import package Flutter UI cần thiết
import 'package:blogapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import "package:blogapp/features/createpost/upload_image.dart";
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';

// EditProfile - Widget StatefulWidget để chỉnh sửa thông tin profile
class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

// State class chứa logic và UI cho EditProfile
class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  UserModel? currentUser;
  XFile? image;
  final UploadImageService _uploadService = UploadImageService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController photoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    try {
      XFile? pickedImage = await _uploadService.uploadFromGallery();
      if (pickedImage != null) {
        setState(() {
          image = pickedImage; // Lưu ảnh đã chọn vào biến image
        });

        // Hiển thị thông báo đã chọn ảnh thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile.Avatar updated successfully'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile.Error uploading avatar'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserModel? user = await AuthService.getUser();
      if (user != null) {
        setState(() {
          currentUser = user;
          nameController.text = user.displayName ?? '';
          bioController.text = user.bio ?? '';

        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? uploadedImageUrl;

      // Nếu có ảnh mới được chọn, upload lên Firebase Storage
      if (image != null) {
        print('Uploading new image...');

        // Hiển thị progress cho user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text('Profile.Upload Avatar'.tr()),
              ],
            ),
            duration: const Duration(seconds: 10),
          ),
        );

        uploadedImageUrl = await _uploadService.uploadImage(image!);
        print('Image uploaded successfully: $uploadedImageUrl');

        // Xóa thông báo upload
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

      } else {
        // Nếu không có ảnh mới, giữ nguyên ảnh cũ
        uploadedImageUrl = currentUser?.photoURL;
        print('No new image selected, keeping current photo');
      }

      print('Updating profile with data:');
      print('DisplayName: ${nameController.text.trim()}');
      print('Bio: ${bioController.text.trim()}');
      print('PhotoURL: $uploadedImageUrl');

      String result = await AuthService.updateProfile(
        displayName: nameController.text.trim(),
        bio: bioController.text.trim(),
        photoURL: uploadedImageUrl,
      );

      if (result == 'success') {
        // Reload user data để cập nhật UI
        await _loadUserData();

        // Reset image state
        setState(() {
          image = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile.Profile updated successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Trả về true để báo hiệu đã update thành công
        }
      } else {
        print('Update profile failed: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'General.Error'.tr()}: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Exception in updateProfile: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile.Error uploading avatar'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile.Edit Profile'.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          )
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              child: ListView(
                children: [
                  // Header hiển thị avatar và tên user hiện tại
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        GestureDetector(
                          child: Stack(
                            children: [
                              image != null
                                  ? FutureBuilder<Uint8List>(
                                      future: image!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return CircleAvatar(
                                            radius: 50,
                                            backgroundImage: MemoryImage(snapshot.data!),
                                          );
                                        }
                                        return const CircleAvatar(
                                          radius: 50,
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    )
                                  : CircleAvatar(
                                      radius: 50,
                                      backgroundImage: (currentUser?.photoURL != null && currentUser!.photoURL.isNotEmpty)
                                          ? NetworkImage(currentUser!.photoURL)
                                          : const NetworkImage("https://picsum.photos/100/100?random=1"),
                                    ),
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                          onTap: () {
                            _pickImage();
                          }
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentUser?.displayName ?? 'General.Loading'.tr(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form field để chỉnh sửa tên
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Profile.First Name'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Form field để chỉnh sửa bio
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: 'Profile.Bio'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.info),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button Save Changes
                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Profile.Save'.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
