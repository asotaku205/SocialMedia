import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/fade_slide.dart';
import '../widgets/textformfield_email.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      // TODO: thêm logic sau khi gửi link reset ở đây
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to: ${_emailController.text}')),
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
                      height: 250,
                      child: Image.asset('assets/logo/logoApp.webp', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FadeSlide(
                    delay: Duration(milliseconds: 200),
                    child: Text('Enter your email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 8),
                  const FadeSlide(
                    delay: Duration(milliseconds: 300),
                    child: Text('We will send a link to reset your password.', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: EmailTextField(controller: _emailController),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: _sendResetLink,
                      child: const Text('Send Link'),
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