import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class UserNameTextField extends StatelessWidget {
  final TextEditingController controller;

  const UserNameTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Authentication.Please enter username'.tr();
        }
        if (value.length < 3) {
          return 'Authentication.Username must be at least 3 characters'.tr();
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Authentication.Username'.tr(),
        prefixIcon: const Icon(Icons.person),
      ),
    );
  }
}