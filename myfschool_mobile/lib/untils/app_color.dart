import 'package:flutter/material.dart';

class AppColors {
  // ===== Dark Theme (default) =====
  static const Color background = Color(0xFF0F0F10);
  static const Color stroke = Color(0xFF2A2A2E);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB9B9BE);
  static const Color hint = Color(0xFF8E8E93);

  static const Color primary = Color(0xFF3D66FF);
  static const Color inputFill = Color(0xFF0F0F10);

  static const Color authBackground = Colors.white;
  static const Color authTitle = Color(0xFF1C1C1E);
  static const Color authHint = Color(0xFF8E8E93);

  static const Color authButton = Color(0xFF5B61F6);
  static const Color authLink = Color(0xFFFF3B30);
  static const Color darkOrange = Color(0xFFFF8A00);

  static const Color authLine = Color(0xFFE5E5EA);

  // ===== Timetable =====
  static const Color ttBlue900  = Color(0xFF0D47A1);
  static const Color ttBlue700  = Color(0xFF1565C0);
  static const Color ttBlue500  = Color(0xFF1E88E5);
  static const Color ttBlue100  = Color(0xFFBBDEFB);
  static const Color ttBlue50   = Color(0xFFE3F2FD);
  static const Color ttOrange   = Color(0xFFF26B21);
  static const Color ttGreen    = Color(0xFF2E7D32);
  static const Color ttGreenBg  = Color(0xFFE8F5E9);
  static const Color ttRed      = Color(0xFFC62828);
  static const Color ttRedBg    = Color(0xFFFFEBEE);
  static const Color ttText     = Color(0xFF1C1C1E);
  static const Color ttBg       = Color(0xFFF0F4FF);
  static const Color ttMeetBlue = Color(0xFF1A73E8);
  static const Color ttBlue600 = Color(0xFF1976D2);

  static const LinearGradient ttBlueGradient = LinearGradient(
    colors: [ttBlue700, ttBlue500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient ttGreenGradient = LinearGradient(
    colors: [ttGreen, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient ttNavGradient = LinearGradient(
    colors: [ttBlue900, ttBlue700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}