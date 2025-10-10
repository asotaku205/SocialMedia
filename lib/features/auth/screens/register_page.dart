import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('Authentication.Confirm Password does not match'.tr()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String result = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userName: _usernameController.text.trim(),
        passwordConfirm: _confirmPasswordController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: Quá thời gian chờ. Vui lòng kiểm tra kết nối internet.');
        },
      );

      if (!mounted) return;

      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication.Register Success'.tr()),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _emailController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Authentication.Error'.tr()} ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // nền đen đồng bộ theme
      body: SafeArea(
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                FadeSlide(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    height: 250,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/logo/logoAppRemovebg.webp'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                 FadeSlide(
                  delay: Duration(milliseconds: 200),
                  child: Text(
                    'Authentication.Create an account'.tr(),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
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
                          labelText: 'Authentication.Confirm Password'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeSlide(
                  delay: const Duration(milliseconds: 600),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Authentication.Register'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
