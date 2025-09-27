import 'package:flutter/material.dart';
import '../widgets/fade_slide.dart';
import '../widgets/textformfield_email.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      String result = await AuthService.forgotPassword(
        email: _emailController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout!');
        },
      );
      if (result == 'success') {
        // Hiển thị thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link has been sent.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  child: Form(
                    key: _formKey,
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
                            onPressed: _isLoading ? null : _sendResetLink,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 60), // khoảng cách bottom
                      ],
                    ),
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
