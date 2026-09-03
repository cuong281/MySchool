import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTextStyles {
  // ===== Dark =====
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const TextStyle subtitle = TextStyle(fontSize: 14, color: AppColors.hint);
  static const TextStyle input = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle hint = TextStyle(fontSize: 13, color: AppColors.hint);
  static const TextStyle body = TextStyle(fontSize: 14, color: AppColors.hint, height: 1.5);
  static const TextStyle small = TextStyle(fontSize: 12, color: AppColors.hint);
  static const TextStyle button = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle primaryButton = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
  static const TextStyle outlineButton = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary);
  static const TextStyle link = TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline);

  // ===== Auth / Light =====
  static const TextStyle authTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.authTitle,
  );
  static const TextStyle authBody = TextStyle(fontSize: 13, color: AppColors.authHint, height: 1.35);
  static const TextStyle authInput = TextStyle(fontSize: 14, color: AppColors.authTitle);
  static const TextStyle authHint = TextStyle(fontSize: 13, color: AppColors.authHint);
  static const TextStyle authButton = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static const TextStyle authLink = TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.authLink);

  // ===== Timetable =====
  static const TextStyle ttScreenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.ttText,
    letterSpacing: 0.2,
  );
  static const TextStyle ttYearBadge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const TextStyle ttWeekBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 1,
  );
  static const TextStyle ttWeekRange = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.ttText,
  );
  static const TextStyle ttTodayLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.ttBlue700,
  );
  static const TextStyle ttDayShort = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static const TextStyle ttDayDate = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.0,
  );
  static const TextStyle ttSlotLabel = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );
  static const TextStyle ttSlotTime = TextStyle(
    fontSize: 10,
    color: AppColors.hint,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle ttSubjectCode = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.3,
  );
  static const TextStyle ttStatusLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ttRoomText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ttText,
  );
  static const TextStyle ttTimeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.hint,
  );
  static const TextStyle ttChipLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle ttEmptyTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ttText,
  );
  static const TextStyle ttEmptySubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.hint,
  );
}