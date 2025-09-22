import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/fade_slide.dart';
import '../widgets/textformfield_email.dart';
import '../widgets/textformfield_password.dart';
import '../widgets/textformfield_username.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }
      // TODO: xử lí đăng kí ở đây
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing registration...')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  FadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: SizedBox(
                      height: 180,
                      child: Image.asset('assets/logo/logoApp.webp', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FadeSlide(
                    delay: Duration(milliseconds: 200),
                    child: Text('Create a new account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: EmailTextField(controller: _emailController),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: UserNameTextField(controller: _usernameController),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: PasswordTextField(controller: _passwordController),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: PasswordTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}