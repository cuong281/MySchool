import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschools/untils/app_color.dart';
import 'package:myfschools/services/user_session.dart';

import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _animEntry(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(
          ((_entryCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ttBg,
      body: Stack(
        children: [
          // Header gradient background
          Positioned(
            top: 0, left: 0, right: 0,
            height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.ttBlue900, AppColors.ttBlue500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Decorative circles on header
          Positioned(top: -30, right: -20,
              child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)))),
          Positioned(top: 60, right: 60,
              child: Container(width: 60, height: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Stats row ──────────────────────────────────────────
                      _animEntry(0.05, _buildStatsRow()),
                      const SizedBox(height: 20),

                      // ── Personal info ──────────────────────────────────────
                      _animEntry(0.12, _buildSectionLabel(
                          Icons.person_outline_rounded, 'Thông tin cá nhân')),
                      const SizedBox(height: 10),
                      _animEntry(0.15, _buildInfoCard([
                        _InfoRow(icon: Icons.badge_outlined,       label: 'MS Hsinh',    value: UserSession.instance.currentUser?.studentCode ?? 'N/A'),
                        _InfoRow(icon: Icons.cake_outlined,         label: 'Ngày sinh',   value: 'Chưa cập nhật'),
                        _InfoRow(icon: Icons.wc_rounded,            label: 'Giới tính',   value: 'N/A'),
                        _InfoRow(icon: Icons.email_outlined,        label: 'Email',       value: UserSession.instance.currentUser?.email ?? 'N/A'),
                        _InfoRow(icon: Icons.phone_outlined,        label: 'Số điện thoại', value: UserSession.instance.currentUser?.phoneNumber ?? 'N/A'),
                      ])),

                      const SizedBox(height: 20),

                      // ── Academic info ──────────────────────────────────────
                      _animEntry(0.22, _buildSectionLabel(
                          Icons.school_outlined, 'Thông tin học tập')),
                      const SizedBox(height: 10),
                      _animEntry(0.25, _buildInfoCard([
                        _InfoRow(icon: Icons.class_outlined,        label: 'Lớp',         value: UserSession.instance.currentUser?.className ?? 'Chưa xếp lớp'),
                        _InfoRow(icon: Icons.business_outlined,     label: 'Ngành',       value: 'Chưa cập nhật'),
                        _InfoRow(icon: Icons.account_balance_outlined, label: 'Campus',   value: 'FPT HN – Hòa Lạc'),
                        _InfoRow(icon: Icons.calendar_today_rounded, label: 'Khóa',       value: 'K17 (2021–2025)'),
                      ])),

                      const SizedBox(height: 20),

                      // ── Settings ───────────────────────────────────────────
                      _animEntry(0.32, _buildSectionLabel(
                          Icons.settings_outlined, 'Cài đặt')),
                      const SizedBox(height: 10),
                      _animEntry(0.35, _buildSettingsCard()),

                      const SizedBox(height: 20),

                      // ── Logout ─────────────────────────────────────────────
                      _animEntry(0.42, _buildLogoutButton(context)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Cá nhân',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.2)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Avatar + name
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: AppColors.ttBlue100,
                      child: const Icon(Icons.person_rounded, size: 52, color: AppColors.ttBlue700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(UserSession.instance.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${UserSession.instance.currentUser?.username ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _StatCell(value: 'N/A', label: 'GPA', color: AppColors.ttBlue700),
          _Divider(),
          _StatCell(value: 'N/A', label: 'Điểm danh', color: const Color(0xFF2E7D32)),
          _Divider(),
          _StatCell(value: '2025', label: 'Khóa học', color: AppColors.ttOrange),
          _Divider(),
          _StatCell(value: 'N/A', label: 'Môn học', color: const Color(0xFF6C3FB5)),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.ttBlue50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.ttBlue700),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: AppColors.ttText, letterSpacing: 0.2)),
      ],
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.ttBlue50,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(row.icon, size: 16, color: AppColors.ttBlue600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label,
                              style: const TextStyle(fontSize: 11, color: AppColors.hint,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(row.value,
                              style: const TextStyle(fontSize: 13.5,
                                  fontWeight: FontWeight.w600, color: AppColors.ttText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 58,
                    color: AppColors.ttBlue100.withOpacity(0.5)),
            ],
          );
        }),
      ),
    );
  }

  // ── Settings card ─────────────────────────────────────────────────────────
  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Notifications toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ttBlue50,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 16, color: AppColors.ttBlue600),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Thông báo',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ttText)),
                ),
                Switch.adaptive(
                  value: _notifEnabled,
                  activeColor: AppColors.ttBlue700,
                  onChanged: (v) { HapticFeedback.lightImpact(); setState(() => _notifEnabled = v); },
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 58, color: AppColors.ttBlue100.withOpacity(0.5)),

          // Language
          _SettingsTile(
            icon: Icons.language_outlined,
            label: 'Ngôn ngữ',
            trailing: const Text('Tiếng Việt',
                style: TextStyle(fontSize: 13, color: AppColors.hint, fontWeight: FontWeight.w500)),
          ),
          Divider(height: 1, indent: 58, color: AppColors.ttBlue100.withOpacity(0.5)),

          // Change password
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Đổi mật khẩu',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.hint, size: 20),
          ),
          Divider(height: 1, indent: 58, color: AppColors.ttBlue100.withOpacity(0.5)),

          // About
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Về ứng dụng',
            trailing: const Text('v1.0.0',
                style: TextStyle(fontSize: 13, color: AppColors.hint, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Logout button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 1. Tạo hiệu ứng rung
        HapticFeedback.mediumImpact();

        // 2. Xoá session user
        UserSession.instance.clear();

        // 3. Thực hiện điều hướng về trang Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFF3B30).withOpacity(0.4),
              width: 1.5
          ),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF3B30).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3)
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF3B30)),
            SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF3B30),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.hint,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32,
        color: AppColors.ttBlue100.withOpacity(0.6));
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsTile({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.ttBlue50,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: AppColors.ttBlue600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13.5,
                      fontWeight: FontWeight.w600, color: AppColors.ttText)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}