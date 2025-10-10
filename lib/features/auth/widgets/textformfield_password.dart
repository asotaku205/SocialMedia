import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscured = true;

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Authentication.Please enter password'.tr();
        }
        if (value.length < 6) {
          return 'Authentication.Password must be at least 6 characters'.tr();
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Authentication.Password'.tr(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: _toggleVisibility,
        ),
      ),

    );
  }
}