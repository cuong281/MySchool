import 'package:flutter/material.dart';
import 'package:myfschools/untils/app_color.dart';
import 'package:myfschools/untils/app_text_styles.dart';

enum AppInputVariant { box, underlineLight }

class AppInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  final AppInputVariant variant;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const AppInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.variant = AppInputVariant.box,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnderline = variant == AppInputVariant.underlineLight;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: isUnderline ? AppTextStyles.authInput : AppTextStyles.input,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: isUnderline ? AppTextStyles.authHint : AppTextStyles.hint,
        prefixIcon: Icon(
          icon,
          color: isUnderline ? AppColors.authTitle : AppColors.hint,
          size: 20,
        ),
        suffixIcon: suffix,

        // Box only
        filled: !isUnderline,
        fillColor: isUnderline ? null : AppColors.inputFill,

        isDense: true,
        contentPadding: isUnderline
            ? const EdgeInsets.symmetric(vertical: 12)
            : const EdgeInsets.symmetric(vertical: 14, horizontal: 12),

        enabledBorder: isUnderline
            ? const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.authLine, width: 1),
        )
            : OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),

        focusedBorder: isUnderline
            ? const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.authLine, width: 1.4),
        )
            : OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
      ),
    );
  }
}
