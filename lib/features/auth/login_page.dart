import 'package:flutter/material.dart';
import 'widgets.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  void navigateWithFade(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF355C7D), Color(0xFF6C5B7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                loginIcon(),
                const SizedBox(height: 16),
                sectionTitle('Welcome Back, Log In!'),
                const SizedBox(height: 32),
                customTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email,
                ),
                const SizedBox(height: 16),
                customTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                  isObscure: _isObscure,
                  toggleObscure: () => setState(() => _isObscure = !_isObscure),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => navigateWithFade(context, const ForgotPasswordPage()),
                    child: const Text('Forgot password?', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                gradientButton(
                  text: 'Log In',
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => navigateWithFade(context, const RegisterPage()),
                  child: const Text('Don’t have an account? Sign Up', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 40),
                footerSignature(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
