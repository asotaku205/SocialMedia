import 'package:easy_localization/easy_localization.dart';
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
           SnackBar(
            content: Text('Authentication.Reset Link'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Authentication.Error'.tr()} $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Authentication.Error'.tr()} $e'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final logoPath = isDark
        ? 'assets/logo/logoAppRemovebg.webp'
        : 'assets/logo/logoApp_pure_black.png';
    return Scaffold(
      backgroundColor: colorScheme.background, // nền đồng bộ theme
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
                              backgroundImage: AssetImage(logoPath),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeSlide(
                          delay: Duration(milliseconds: 200),
                          child: Text(
                            "Authentication.Reset Password".tr(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeSlide(
                          delay: Duration(milliseconds: 300),
                          child: Text(
                            'Authentication.Reset desc'.tr(),
                            style: TextStyle(fontSize: 16, color: colorScheme.secondary),
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
                              foregroundColor: textColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: textColor,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                :Text(
                                    'Authentication.Send Reset Link'.tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
