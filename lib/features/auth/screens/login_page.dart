import 'package:flutter/material.dart';
import '../widgets/fade_slide.dart';
import '../widgets/textformfield_email.dart';
import '../widgets/textformfield_password.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../../profile/main_profile.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method đăng nhập sử dụng AuthService
  Future<void> _login() async {
    // Kiểm tra validation form trước khi tiếp tục
    if (!_formKey.currentState!.validate()) return;

    // Bật loading state
    setState(() => _isLoading = true);
    try {
      // Sử dụng AuthService.signIn() - trả về UserModel nếu thành công, null nếu thất bại
      UserModel? user = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Kiểm tra kết quả đăng nhập
      if (user != null) {
        // Đăng nhập thành công - có UserModel
        if (mounted) {
          // Hiển thị thông báo chào mừng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chào mừng trở lại, ${user.displayName}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Điều hướng đến trang chủ
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MainProfile()));
        }
      } else {
        // Đăng nhập thất bại - user == null
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email hoặc mật khẩu không đúng'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
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
      if (mounted) setState(() => _isLoading = false);
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: SizedBox(
                      height: 200,
                      child: Image.asset('assets/logo/logoApp.webp', fit: BoxFit.contain),

                    ),
                  ),
                  const SizedBox(height: 20),
                  const FadeSlide(
                    delay: Duration(milliseconds: 200),
                    child: Text('Welcome back!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 8),
                  const FadeSlide(
                    delay: Duration(milliseconds: 300),
                    child: Text('Login to continue', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 40),
                  FadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: EmailTextField(controller: _emailController),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: PasswordTextField(controller: _passwordController),
                  ),
                  const SizedBox(height: 12),
                  FadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 700),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlide(
                    delay: const Duration(milliseconds: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                          child: const Text('Register now'),
                        ),
                      ],
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