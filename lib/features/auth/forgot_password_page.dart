import 'package:flutter/material.dart';
import 'widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF355C7D), Color(0xFF6C5B7B)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                forgotPasswordIcon(),
                const SizedBox(height: 16),
                sectionTitle('Reset Your Password'),
                const SizedBox(height: 32),
                customTextField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email,
                ),
                const SizedBox(height: 24),
                gradientButton(
                  text: 'Send Request',
                  onPressed: () {
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '🔙 Back to Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
