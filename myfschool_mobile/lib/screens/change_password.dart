import 'package:flutter/material.dart';
import 'package:myfschools/untils/app_color.dart';
import 'package:myfschools/untils/app_input.dart';
import 'account_success.dart';
import 'login.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool agree = false;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              const Text(
                'Đổi mật khẩu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.authTitle,
                ),
              ),

              const SizedBox(height: 28),

              const AppInput(
                hint: 'Nhập mã OTP',
                icon: Icons.person_outline,
                variant: AppInputVariant.underlineLight,
              ),

              const SizedBox(height: 16),

              AppInput(
                hint: 'New Password',
                icon: Icons.key_outlined,
                variant: AppInputVariant.underlineLight,
                obscure: hideNew,
                suffix: IconButton(
                  onPressed: () => setState(() => hideNew = !hideNew),
                  icon: Icon(
                    hideNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.authHint,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AppInput(
                hint: 'Confirm Password',
                icon: Icons.key_outlined,
                variant: AppInputVariant.underlineLight,
                obscure: hideConfirm,
                suffix: IconButton(
                  onPressed: () => setState(() => hideConfirm = !hideConfirm),
                  icon: Icon(
                    hideConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.authHint,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => agree = !agree),
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: agree ? AppColors.authLink : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.authLink, width: 1.2),
                      ),
                      child: agree
                          ? const Icon(Icons.check,
                          size: 13, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.authHint,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Services',
                            style: TextStyle(
                              color: AppColors.authLink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' and\n'),
                          TextSpan(
                            text: 'Privacy Policy.',
                            style: TextStyle(
                              color: AppColors.authLink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ Continue -> AccountSuccess
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSuccessScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Have an Account? ',
                      style: TextStyle(fontSize: 12, color: AppColors.authHint),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.authLink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
