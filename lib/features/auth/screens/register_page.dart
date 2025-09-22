import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/fade_slide.dart';
import '../widgets/textformfield_email.dart';
import '../widgets/textformfield_password.dart';
import '../widgets/textformfield_username.dart';
import '../../../services/auth_service.dart';
import 'login_page.dart';

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
  bool _isLoading = false; // Thêm loading state

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method xử lý đăng ký sử dụng AuthService
  Future<void> _register() async {
    // Kiểm tra validation form trước khi tiếp tục
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu và xác nhận mật khẩu không khớp!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Bật loading state
    setState(() => _isLoading = true);

    try {
      // Thêm timeout để tránh loading vô hạn
      String result = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userName: _usernameController.text.trim(),
        passwordConfirm: _confirmPasswordController.text.trim(),
      ).timeout(
        const Duration(seconds: 30), // Timeout sau 30 giây
        onTimeout: () {
          throw Exception('Timeout: Quá thời gian chờ. Vui lòng kiểm tra kết nối internet.');
        },
      );

      if (!mounted) {
        return;
      }

      if (result == 'success') {
        // Đăng ký thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear các text fields
        _emailController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Navigate về trang login sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
      } else {
        // Đăng ký thất bại - hiển thị error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result), // Hiển thị error message từ AuthService
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Xử lý các lỗi không mong muốn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Tắt loading state trong mọi trường hợp
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register, // Disable button khi đang loading
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Register'),
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