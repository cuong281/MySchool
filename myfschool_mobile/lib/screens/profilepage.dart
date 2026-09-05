import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/services/api_client.dart';
import 'package:myfschools/services/attendance_api.dart';
import 'package:myfschools/services/report_api.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/untils/app_color.dart';

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
  bool _isLoading = true;

  // Real stats from APIs
  Map<String, dynamic>? _adminDashboard;
  List<Map<String, dynamic>> _teacherAssignments = [];
  AttendanceSummary? _studentAttendance;
  List<dynamic> _studentGrades = [];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _loadData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = UserSession.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      if (user.isAdmin) {
        final dashboard = await ReportApi.instance.getAdminDashboard();
        if (mounted) {
          setState(() {
            _adminDashboard = dashboard;
            _isLoading = false;
          });
        }
      } else if (user.isTeacher) {
        final res = await ApiClient.instance.get(
          Uri.parse('${ApiClient.baseUrl}/teachers/me/assignments'),
        );
        if (res.statusCode == 200) {
          final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          _teacherAssignments = list.cast<Map<String, dynamic>>();
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        final summary = await AttendanceApi.instance.getMyAttendanceSummary();
        final gradeRes = await ApiClient.instance.get(
          Uri.parse('${ApiClient.baseUrl}/grades/me'),
        );
        List<dynamic> grades = [];
        if (gradeRes.statusCode == 200) {
          grades = jsonDecode(utf8.decode(gradeRes.bodyBytes)) as List<dynamic>;
        }
        if (mounted) {
          setState(() {
            _studentAttendance = summary;
            _studentGrades = grades;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.ttBlue700,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Header (seamless gradient, full clearance for badges) ────────
            _buildHeader(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Real stats row based on role ─────────────────────────────
                  _animEntry(0.05, _buildStatsRow()),
                  const SizedBox(height: 20),

                  // ── Role specific information cards ───────────────────────────
                  ..._buildRoleInfoSections(),

                  // ── Settings ───────────────────────────────────────────────
                  _animEntry(0.32, _buildSectionLabel(
                      Icons.settings_outlined, 'Cài đặt')),
                  const SizedBox(height: 10),
                  _animEntry(0.35, _buildSettingsCard()),

                  const SizedBox(height: 20),

                  // ── Logout ─────────────────────────────────────────────────
                  _animEntry(0.42, _buildLogoutButton(context)),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = UserSession.instance.currentUser;
    final username = user?.username ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ttBlue900, AppColors.ttBlue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 50, left: -25,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
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
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 17, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _loadData();
                          },
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar
                  Container(
                    width: 86, height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: AppColors.ttBlue100,
                        child: Icon(
                          user?.isAdmin == true
                              ? Icons.admin_panel_settings_rounded
                              : user?.isTeacher == true
                                  ? Icons.school_rounded
                                  : Icons.person_rounded,
                          size: 52,
                          color: AppColors.ttBlue700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full name with fallback
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      UserSession.instance.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badges row: Role badge + Username chip (fully visible, ample spacing)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildRoleBadge(),
                      if (username.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25), width: 1),
                          ),
                          child: Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role badge ─────────────────────────────────────────────────────────────
  Widget _buildRoleBadge() {
    final user = UserSession.instance.currentUser;
    if (user?.isAdmin == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9500).withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFFFB340).withOpacity(0.6), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 13, color: Color(0xFFFFD60A)),
            SizedBox(width: 5),
            Text(
              'Quản trị viên',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (user?.isTeacher == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFF00C7BE).withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF63E6E2).withOpacity(0.6), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, size: 13, color: Color(0xFF63E6E2)),
            SizedBox(width: 5),
            Text(
              'Giáo viên',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF30D158).withOpacity(0.6), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.backpack_rounded, size: 13, color: Color(0xFF30D158)),
          SizedBox(width: 5),
          Text(
            'Học sinh',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row (100% Real API Data, No Mock Data) ──────────────────────────
  Widget _buildStatsRow() {
    final user = UserSession.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    List<Widget> cells = [];

    if (user.isAdmin) {
      final sCount = _isLoading ? '...' : '${_adminDashboard?['totalStudents'] ?? 0}';
      final tCount = _isLoading ? '...' : '${_adminDashboard?['totalTeachers'] ?? 0}';
      final cCount = _isLoading ? '...' : '${_adminDashboard?['totalClasses'] ?? 0}';
      final gCount = _isLoading ? '...' : '${_adminDashboard?['totalGrades'] ?? 0}';

      cells = [
        _StatCell(value: sCount, label: 'Học sinh', color: AppColors.ttBlue700),
        _Divider(),
        _StatCell(value: tCount, label: 'Giáo viên', color: const Color(0xFF2E7D32)),
        _Divider(),
        _StatCell(value: cCount, label: 'Lớp học', color: AppColors.ttOrange),
        _Divider(),
        _StatCell(value: gCount, label: 'Bản ghi điểm', color: const Color(0xFF6C3FB5)),
      ];
    } else if (user.isTeacher) {
      final classes = _teacherAssignments
          .map((e) => e['className']?.toString())
          .where((s) => s != null && s.isNotEmpty)
          .toSet();
      final subjects = _teacherAssignments
          .map((e) => e['subjectName']?.toString())
          .where((s) => s != null && s.isNotEmpty)
          .toSet();

      final classCount = _isLoading ? '...' : '${classes.length}';
      final subCount = _isLoading ? '...' : '${subjects.length}';
      final assignCount = _isLoading ? '...' : '${_teacherAssignments.length}';

      cells = [
        _StatCell(value: classCount, label: 'Lớp dạy', color: AppColors.ttBlue700),
        _Divider(),
        _StatCell(value: subCount, label: 'Bộ môn', color: const Color(0xFF2E7D32)),
        _Divider(),
        _StatCell(value: assignCount, label: 'Phân công', color: AppColors.ttOrange),
        _Divider(),
        const _StatCell(value: 'Hoạt động', label: 'Trạng thái', color: Color(0xFF2E7D32)),
      ];
    } else {
      // Student
      String gpaStr = '-';
      if (_studentGrades.isNotEmpty) {
        final validAverages = _studentGrades
            .map((g) => (g['averageScore'] as num?)?.toDouble())
            .whereType<double>()
            .toList();
        if (validAverages.isNotEmpty) {
          final avg = validAverages.reduce((a, b) => a + b) / validAverages.length;
          gpaStr = avg.toStringAsFixed(1);
        }
      }

      String attStr = '-';
      if (_studentAttendance != null) {
        attStr = '${_studentAttendance!.attendanceRate.toStringAsFixed(0)}%';
      }

      final uniqueSubs = _studentGrades
          .map((g) => g['subjectCode']?.toString())
          .whereType<String>()
          .toSet();
      final subCount = uniqueSubs.isNotEmpty ? '${uniqueSubs.length}' : '-';
      final className = user.className.isNotEmpty ? user.className : '-';

      cells = [
        _StatCell(value: _isLoading ? '...' : gpaStr, label: 'Điểm TB', color: AppColors.ttBlue700),
        _Divider(),
        _StatCell(value: _isLoading ? '...' : attStr, label: 'Điểm danh', color: const Color(0xFF2E7D32)),
        _Divider(),
        _StatCell(value: _isLoading ? '...' : subCount, label: 'Môn học', color: AppColors.ttOrange),
        _Divider(),
        _StatCell(value: className, label: 'Lớp', color: const Color(0xFF6C3FB5)),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: cells),
    );
  }

  // ── Role Information Sections (Only show existing fields, no mock data) ───
  List<Widget> _buildRoleInfoSections() {
    final user = UserSession.instance.currentUser;
    if (user == null) return [];

    final sections = <Widget>[];

    if (user.isAdmin) {
      final rows = <_InfoRow>[];
      if (user.lastName.isNotEmpty || user.firstName.isNotEmpty) {
        rows.add(_InfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Họ và tên',
          value: UserSession.instance.fullName,
        ));
      }
      rows.add(_InfoRow(
        icon: Icons.account_circle_outlined,
        label: 'Tên đăng nhập',
        value: user.username,
      ));
      rows.add(const _InfoRow(
        icon: Icons.shield_outlined,
        label: 'Vai trò hệ thống',
        value: 'Quản trị viên',
      ));
      if (user.email.isNotEmpty) {
        rows.add(_InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user.email,
        ));
      }
      if (user.phoneNumber.isNotEmpty) {
        rows.add(_InfoRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: user.phoneNumber,
        ));
      }
      rows.add(const _InfoRow(
        icon: Icons.check_circle_outline_rounded,
        label: 'Trạng thái tài khoản',
        value: 'Đang hoạt động',
      ));

      sections.add(_animEntry(0.12, _buildSectionLabel(
          Icons.admin_panel_settings_outlined, 'Thông tin tài khoản')));
      sections.add(const SizedBox(height: 10));
      sections.add(_animEntry(0.15, _buildInfoCard(rows)));
      sections.add(const SizedBox(height: 20));
    } else if (user.isTeacher) {
      final rows = <_InfoRow>[];
      rows.add(_InfoRow(
        icon: Icons.person_outline_rounded,
        label: 'Họ và tên',
        value: UserSession.instance.fullName,
      ));
      if (user.teacherId != null) {
        rows.add(_InfoRow(
          icon: Icons.badge_outlined,
          label: 'Mã giáo viên',
          value: 'GV${user.teacherId.toString().padLeft(3, '0')}',
        ));
      }
      rows.add(_InfoRow(
        icon: Icons.account_circle_outlined,
        label: 'Tên đăng nhập',
        value: user.username,
      ));
      rows.add(const _InfoRow(
        icon: Icons.school_outlined,
        label: 'Vai trò',
        value: 'Giáo viên',
      ));
      if (user.email.isNotEmpty) {
        rows.add(_InfoRow(
          icon: Icons.email_outlined,
          label: 'Email công vụ',
          value: user.email,
        ));
      }
      if (user.phoneNumber.isNotEmpty) {
        rows.add(_InfoRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: user.phoneNumber,
        ));
      }
      rows.add(const _InfoRow(
        icon: Icons.check_circle_outline_rounded,
        label: 'Trạng thái',
        value: 'Đang công tác',
      ));

      sections.add(_animEntry(0.12, _buildSectionLabel(
          Icons.work_outline_rounded, 'Thông tin công tác')));
      sections.add(const SizedBox(height: 10));
      sections.add(_animEntry(0.15, _buildInfoCard(rows)));
      sections.add(const SizedBox(height: 20));

      // Phân công giảng dạy nếu có dữ liệu
      if (_teacherAssignments.isNotEmpty) {
        final classes = _teacherAssignments
            .map((e) => e['className']?.toString())
            .where((s) => s != null && s.isNotEmpty)
            .toSet()
            .toList();
        final subjects = _teacherAssignments
            .map((e) => e['subjectName']?.toString())
            .where((s) => s != null && s.isNotEmpty)
            .toSet()
            .toList();
        final roles = _teacherAssignments
            .map((e) => e['roleType'] == 'HOMEROOM_TEACHER'
                ? 'GV Chủ nhiệm (${e['className']})'
                : 'GV Bộ môn (${e['subjectName']})')
            .toSet()
            .toList();

        final assignRows = <_InfoRow>[];
        if (classes.isNotEmpty) {
          assignRows.add(_InfoRow(
            icon: Icons.class_outlined,
            label: 'Lớp giảng dạy',
            value: classes.join(', '),
          ));
        }
        if (subjects.isNotEmpty) {
          assignRows.add(_InfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Bộ môn',
            value: subjects.join(', '),
          ));
        }
        if (roles.isNotEmpty) {
          assignRows.add(_InfoRow(
            icon: Icons.assignment_ind_outlined,
            label: 'Nhiệm vụ',
            value: roles.join('\n'),
          ));
        }

        if (assignRows.isNotEmpty) {
          sections.add(_animEntry(0.22, _buildSectionLabel(
              Icons.menu_book_outlined, 'Phân công giảng dạy')));
          sections.add(const SizedBox(height: 10));
          sections.add(_animEntry(0.25, _buildInfoCard(assignRows)));
          sections.add(const SizedBox(height: 20));
        }
      }
    } else {
      // Student
      final personalRows = <_InfoRow>[];
      personalRows.add(_InfoRow(
        icon: Icons.person_outline_rounded,
        label: 'Họ và tên',
        value: UserSession.instance.fullName,
      ));
      if (user.studentCode.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.badge_outlined,
          label: 'Mã học sinh',
          value: user.studentCode,
        ));
      }
      personalRows.add(_InfoRow(
        icon: Icons.account_circle_outlined,
        label: 'Tên đăng nhập',
        value: user.username,
      ));
      if (user.email.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user.email,
        ));
      }
      if (user.phoneNumber.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: user.phoneNumber,
        ));
      }
      if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.cake_outlined,
          label: 'Ngày sinh',
          value: user.dateOfBirth!,
        ));
      }
      if (user.gender != null && user.gender!.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.wc_rounded,
          label: 'Giới tính',
          value: user.gender!,
        ));
      }
      if (user.address != null && user.address!.isNotEmpty) {
        personalRows.add(_InfoRow(
          icon: Icons.home_outlined,
          label: 'Địa chỉ',
          value: user.address!,
        ));
      }

      sections.add(_animEntry(0.12, _buildSectionLabel(
          Icons.person_outline_rounded, 'Thông tin cá nhân')));
      sections.add(const SizedBox(height: 10));
      sections.add(_animEntry(0.15, _buildInfoCard(personalRows)));
      sections.add(const SizedBox(height: 20));

      if (user.className.isNotEmpty || user.classId != null) {
        final academicRows = <_InfoRow>[];
        if (user.className.isNotEmpty) {
          academicRows.add(_InfoRow(
            icon: Icons.class_outlined,
            label: 'Lớp',
            value: user.className,
          ));
        }
        if (user.classId != null) {
          academicRows.add(_InfoRow(
            icon: Icons.tag_rounded,
            label: 'Mã lớp',
            value: 'LOP${user.classId.toString().padLeft(3, '0')}',
          ));
        }
        academicRows.add(const _InfoRow(
          icon: Icons.verified_outlined,
          label: 'Tình trạng',
          value: 'Đang theo học',
        ));

        sections.add(_animEntry(0.22, _buildSectionLabel(
            Icons.school_outlined, 'Thông tin lớp học')));
        sections.add(const SizedBox(height: 10));
        sections.add(_animEntry(0.25, _buildInfoCard(academicRows)));
        sections.add(const SizedBox(height: 20));
      }
    }

    return sections;
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
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
          const _SettingsTile(
            icon: Icons.language_outlined,
            label: 'Ngôn ngữ',
            trailing: Text('Tiếng Việt',
                style: TextStyle(fontSize: 13, color: AppColors.hint, fontWeight: FontWeight.w500)),
          ),
          Divider(height: 1, indent: 58, color: AppColors.ttBlue100.withOpacity(0.5)),

          // Change password
          const _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Đổi mật khẩu',
            trailing: Icon(Icons.chevron_right_rounded, color: AppColors.hint, size: 20),
          ),
          Divider(height: 1, indent: 58, color: AppColors.ttBlue100.withOpacity(0.5)),

          // About
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'Về ứng dụng',
            trailing: Text('v1.0.0',
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
        HapticFeedback.mediumImpact();
        UserSession.instance.clear();
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
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.hint,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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