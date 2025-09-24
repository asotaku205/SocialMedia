import 'package:flutter/material.dart';
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
      // TODO: thêm logic gửi link reset
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset link sent to: ${_emailController.text}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // nền đen
      body: Stack(
        children: [
          // Content chính
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60), // tạo khoảng cách top nếu muốn
                      FadeSlide(
                        delay: const Duration(milliseconds: 100),
                        child: SizedBox(
                          height: 250,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                AssetImage('assets/logo/logoAppRemovebg.webp'),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const FadeSlide(
                        delay: Duration(milliseconds: 200),
                        child: Text(
                          'Enter your email',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const FadeSlide(
                        delay: Duration(milliseconds: 300),
                        child: Text(
                          'We will send a link to reset your password',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Send Link'),
                        ),
                      ),
                      const SizedBox(height: 60), // khoảng cách bottom
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Icon back top-left
          Positioned(
            top: 16,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
