import 'package:flutter/material.dart';

class UserNameTextField extends StatelessWidget {
  final TextEditingController controller;

  const UserNameTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: const InputDecoration(
        labelText: 'UserName',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your username';
        }
        if (value.length < 6) {
          return 'Username must be at least 6 characters';
        }
        return null;
      },
    );
  }
}