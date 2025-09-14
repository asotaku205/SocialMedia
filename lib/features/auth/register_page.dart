import 'package:flutter/material.dart';
import 'widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isChecked = false;

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
                registerIcon(),
                const SizedBox(height: 16),
                sectionTitle('Welcome, Sign Up!'),
                const SizedBox(height: 32),
                customTextField(
                  controller: _nameController,
                  hint: 'User Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                customTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (val) => setState(() => _isChecked = val!),
                      checkColor: Colors.white,
                      activeColor: Color(0xFF355C7D),
                    ),
                    const Expanded(
                      child: Text('I accept the policy and terms', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                gradientButton(
                  text: 'Sign Up',
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('🔙 Back to Login', style: TextStyle(color: Colors.white)),
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
