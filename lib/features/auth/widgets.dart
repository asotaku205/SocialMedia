import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF355C7D);

Widget loginIcon() {
  return const Icon(Icons.login, size: 64, color: Colors.white);
}

Widget registerIcon() {
  return const Icon(Icons.person_add_alt_1, size: 64, color: Colors.white);
}

Widget forgotPasswordIcon() {
  return const Icon(Icons.lock_reset, size: 64, color: Colors.white);
}

Widget sectionTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    textAlign: TextAlign.center,
  );
}

Widget customTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  bool isPassword = false,
  bool isObscure = false,
  VoidCallback? toggleObscure,
}) {
  return TextField(
    controller: controller,
    obscureText: isPassword ? isObscure : false,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: isPassword && toggleObscure != null
          ? IconButton(
        icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggleObscure,
      )
          : null,
      filled: true,
      // ignore: deprecated_member_use
      fillColor: Colors.white.withOpacity(0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget gradientButton({
  required String text,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 18)),
  );
}
