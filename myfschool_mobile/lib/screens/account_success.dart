import 'package:flutter/material.dart';
import 'package:myfschools/untils/app_color.dart';
import 'package:myfschools/untils/app_text_styles.dart';
import 'login.dart';

class AccountSuccessScreen extends StatelessWidget {
  const AccountSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.celebration_outlined,
                size: 120,
                color: AppColors.darkOrange,
              ),
              const SizedBox(height: 28),
              const Text(
                'Đổi mật khẩu\nthành công!',
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn có thể đăng nhập lại với mật khẩu mới.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Quay về Login và xoá stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: AppTextStyles.primaryButton,
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
