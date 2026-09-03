import 'package:flutter/material.dart';
import 'package:myfschools/untils/app_input.dart';

import '../assets/images.dart';
import '../services/auth_service.dart';
import '../services/user_session.dart';
import 'forget_password.dart';
import 'package:myfschools/screens/homepage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final result = await authService.value.login(phone, password);

    if (result != null) {
      UserSession.instance.setUser(result);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai số điện thoại hoặc mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Image.asset(
                    TImages.darkAppLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chào mừng quay lại',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 22),
              AppInput(
                controller: phoneController,
                hint: 'Số điện thoại',
                icon: Icons.phone_outlined,
                variant: AppInputVariant.underlineLight,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: passwordController,
                hint: 'Mật khẩu',
                icon: Icons.key_outlined,
                variant: AppInputVariant.underlineLight,
                obscure: hidePassword,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => hidePassword = !hidePassword),
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8E8E93),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF8E8E93),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgetPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
              const Center(
                child: Text(
                  'Phiên bản 1.0.0.0',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ),
              const Center(
                child: Text(
                  'Copyright FPT Schools',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
