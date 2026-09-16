import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/models/attendance_history_model.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/models/teacher_assignment_model.dart';
import 'package:myfschools/services/attendance_api.dart';
import 'package:myfschools/services/school_class_api.dart';
import 'package:myfschools/services/teacher_assignment_api.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/screens/attendance_sheet_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1A3C6E);
  static const _orange = Color(0xFFF26B21);
  static const _bg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  // Status colors as requested
  static const _colorPresent = Color(0xFF10B981);   // Xanh lá (Green)
  static const _colorExcused = Color(0xFF2563EB);   // Xanh dương (Blue)
  static const _colorLate = Color(0xFFF59E0B);      // Vàng/Cam (Amber/Orange)
  static const _colorUnexcused = Color(0xFFEF4444); // Đỏ (Red)

  bool _isLoading = true;

  // Student view data
  AttendanceSummary? _summary;
  List<AttendanceRecord> _records = [];

  // Teacher/Admin view data
  List<SchoolClassModel> _classes = [];
  int? _selectedClassId;
  AttendanceClassHistoryModel? _classHistory;
  List<TeacherAssignmentModel> _myAssignments = [];

  // Tab & Filters for Staff View
  int _selectedTab = 0; // 0: Theo buổi học, 1: Theo học sinh
  String _sessionFilterMonth = 'ALL'; // 'ALL', '9', '10', '11', '12', '1', '2', '3', '4', '5'
  String _sessionSemester = 'ALL'; // 'ALL', 'HK1', 'HK2'
  String _studentSearchQuery = '';
  String _studentFilter = 'ALL'; // 'ALL', 'AT_RISK', 'ABSENT', 'LATE'

  bool get _isStaff {
    final user = UserSession.instance.currentUser;
    return (user?.isTeacher == true) || (user?.isAdmin == true);
  }

  bool get _isCurrentClassHomeroom {
    final user = UserSession.instance.currentUser;
    if (user?.isAdmin == true) return true;
    return _myAssignments.any((a) => a.classId == _selectedClassId && a.isHomeroom);
  }

  String get _currentClassRoleLabel {
    final user = UserSession.instance.currentUser;
    if (user?.isAdmin == true) return 'Quản trị viên';
    if (_isCurrentClassHomeroom) return 'GV Chủ nhiệm';
    final subjects = _myAssignments
        .where((a) => a.classId == _selectedClassId && a.subjectName != null && a.subjectName!.isNotEmpty)
        .map((a) => a.subjectName!)
        .toSet()
        .toList();
    if (subjects.isNotEmpty) {
      return 'GV Bộ môn (${subjects.join(', ')})';
    }
    return 'GV Bộ môn';
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);

    if (_isStaff) {
      final user = UserSession.instance.currentUser;
      List<SchoolClassModel> classes = [];

      if (user?.isAdmin == true) {
        classes = await SchoolClassApi.instance.getAllClasses();
      } else {
        final assignments = await TeacherAssignmentApi.instance.getMyAssignments();
        _myAssignments = assignments;
        final seenClassIds = <int>{};
        for (final a in assignments) {
          if (seenClassIds.add(a.classId)) {
            classes.add(SchoolClassModel(
              id: a.classId,
              className: a.className,
              status: 'ACTIVE',
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _classes = classes;
          if (_classes.isNotEmpty) {
            _selectedClassId = _classes.first.id;
          }
        });
      }
      if (_selectedClassId != null) {
        await _loadClassHistory(_selectedClassId!);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await _loadStudentData();
    }
  }

  Future<void> _loadClassHistory(int classId) async {
    setState(() => _isLoading = true);
    final history = await AttendanceApi.instance.getClassAttendanceHistory(classId);
    if (mounted) {
      setState(() {
        _classHistory = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    final summaryFuture = AttendanceApi.instance.getMyAttendanceSummary();
    final recordsFuture = AttendanceApi.instance.getMyAttendance();

    final results = await Future.wait([summaryFuture, recordsFuture]);

    if (mounted) {
      setState(() {
        _summary = results[0] as AttendanceSummary?;
        _records = results[1] as List<AttendanceRecord>;
        _isLoading = false;
      });
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _isStaff ? 'Quản lý điểm danh' : 'Chuyên cần & Điểm danh',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : RefreshIndicator(
              onRefresh: () async {
                if (_isStaff && _selectedClassId != null) {
                  await _loadClassHistory(_selectedClassId!);
                } else {
                  await _loadStudentData();
                }
              },
              child: _isStaff ? _buildStaffView() : _buildStudentView(),
            ),
    );
  }

  // ==========================================
  // STAFF (TEACHER / ADMIN) VIEW
  // ==========================================

  Widget _buildStaffView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Class selector dropdown
        _buildClassSelector(),
        const SizedBox(height: 16),

        if (_classHistory != null) ...[
          // Overall Class Stats Card (Standardized Sĩ số 25, 1 buổi, 100%)
          _buildClassSummaryCard(_classHistory!),
          const SizedBox(height: 16),

          // At-risk students banner (if any)
          if (_classHistory!.atRiskStudents.isNotEmpty) ...[
            _buildAtRiskSection(_classHistory!.atRiskStudents),
            const SizedBox(height: 16),
          ],

          // 2 View Perspectives Tabs: [ Theo buổi học | Theo học sinh ]
          _buildSegmentedTabSelector(),
          const SizedBox(height: 14),

          // Render active tab view
          if (_selectedTab == 0)
            _buildSessionTimelineTab()
          else
            _buildStudentRosterTab(),
        ] else
          _buildEmptyState('Không tìm thấy dữ liệu điểm danh của lớp'),
      ],
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, size: 20, color: _blue),
              const SizedBox(width: 10),
              const Text('Chọn lớp:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedClassId,
                    isExpanded: true,
                    items: _classes.map((c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          'Lớp ${c.className}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _blue),
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null && newId != _selectedClassId) {
                        setState(() => _selectedClassId = newId);
                        _loadClassHistory(newId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_selectedClassId != null && _isStaff) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isCurrentClassHomeroom ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isCurrentClassHomeroom ? const Color(0xFFBFDBFE) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCurrentClassHomeroom ? Icons.verified_user : Icons.menu_book,
                    size: 13,
                    color: _isCurrentClassHomeroom ? const Color(0xFF2563EB) : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _currentClassRoleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isCurrentClassHomeroom ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Header Card: Standardized with fixed class size (Sĩ số 25), Sessions, Rate, Absences, Late
  Widget _buildClassSummaryCard(AttendanceClassHistoryModel hist) {
    Color rateColor = _colorPresent;
    if (hist.attendanceRate < 75) {
      rateColor = _colorUnexcused;
    } else if (hist.attendanceRate < 88) {
      rateColor = _colorLate;
    }

    final totalAbsences = hist.excusedCount + hist.unexcusedCount;
    final displayClassSize = hist.totalStudents > 0 ? hist.totalStudents : 25;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan lớp ${hist.className}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sĩ số: $displayClassSize học sinh',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Đã điểm danh: ${hist.totalSessions} buổi',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rateColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rateColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${hist.attendanceRate.toStringAsFixed(1)}%',
                      style: TextStyle(color: rateColor, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Chuyên cần',
                      style: TextStyle(color: rateColor, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Clean 4 stat boxes (Vắng, Có phép, K.Phép, Đi muộn)
          Row(
            children: [
              Expanded(
                child: _buildStaffStatBox(
                  'Tổng lượt vắng',
                  '$totalAbsences',
                  Colors.blueGrey,
                  'Có phép + K.phép',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox(
                  'Có phép',
                  '${hist.excusedCount}',
                  Colors.blue,
                  null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox(
                  'Không phép',
                  '${hist.unexcusedCount}',
                  Colors.red,
                  hist.unexcusedCount > 0 ? 'Cần xử lý' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox(
                  'Đi muộn',
                  '${hist.lateCount}',
                  Colors.orange,
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStatBox(String label, String value, MaterialColor color, String? sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(fontSize: 9, color: color.shade600, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Segmented Control Tab Selector: [ 📅 Theo buổi học | 🎓 Theo học sinh ]
  Widget _buildSegmentedTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 0
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: _selectedTab == 0 ? _blue : Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Theo buổi học (${_classHistory?.sessions.length ?? 0})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _selectedTab == 0 ? _blue : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 1
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 16, color: _selectedTab == 1 ? _blue : Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Theo học sinh (${_classHistory?.studentSummaries.length ?? _classHistory?.totalStudents ?? 25})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _selectedTab == 1 ? _blue : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: THEO BUỔI HỌC (TIMELINE + FILTERS)
  // ==========================================

  Widget _buildSessionTimelineTab() {
    final allSessions = _classHistory?.sessions ?? [];

    // Filter sessions by month and semester
    final filteredSessions = allSessions.where((s) {
      try {
        final dt = DateTime.parse(s.attendanceDate);
        if (_sessionFilterMonth != 'ALL') {
          if (dt.month != int.tryParse(_sessionFilterMonth)) return false;
        }
        if (_sessionSemester == 'HK1') {
          // HK1: Tháng 9 -> Tháng 1
          if (dt.month > 1 && dt.month < 9) return false;
        } else if (_sessionSemester == 'HK2') {
          // HK2: Tháng 2 -> Tháng 6
          if (dt.month < 2 || dt.month > 6) return false;
        }
      } catch (_) {}
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar for Timeline (Month / Semester chips)
        _buildSessionFilterBar(),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isCurrentClassHomeroom
                  ? 'Danh sách buổi học (${filteredSessions.length})'
                  : 'Danh sách buổi học bộ môn (${filteredSessions.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            if (filteredSessions.length < allSessions.length)
              InkWell(
                onTap: () {
                  setState(() {
                    _sessionFilterMonth = 'ALL';
                    _sessionSemester = 'ALL';
                  });
                },
                child: const Text('Đặt lại bộ lọc', style: TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredSessions.isEmpty)
          _buildEmptyState(allSessions.isEmpty
              ? (_isCurrentClassHomeroom
                  ? 'Lớp chưa có buổi học nào được điểm danh'
                  : 'Chưa có buổi điểm danh nào cho bộ môn của bạn trong lớp này')
              : 'Không có buổi học nào phù hợp với bộ lọc')
        else
          ...filteredSessions.map(_buildSessionCard),
      ],
    );
  }

  Widget _buildSessionFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Semester Chips
          _buildFilterChip('Tất cả', _sessionSemester == 'ALL' && _sessionFilterMonth == 'ALL', () {
            setState(() {
              _sessionSemester = 'ALL';
              _sessionFilterMonth = 'ALL';
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('Học kỳ 1', _sessionSemester == 'HK1', () {
            setState(() {
              _sessionSemester = _sessionSemester == 'HK1' ? 'ALL' : 'HK1';
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('Học kỳ 2', _sessionSemester == 'HK2', () {
            setState(() {
              _sessionSemester = _sessionSemester == 'HK2' ? 'ALL' : 'HK2';
            });
          }),
          const SizedBox(width: 10),
          Container(width: 1, height: 22, color: _border),
          const SizedBox(width: 10),

          // Month Filter Chips
          _buildFilterChip('Tháng 9', _sessionFilterMonth == '9', () {
            setState(() {
              _sessionFilterMonth = _sessionFilterMonth == '9' ? 'ALL' : '9';
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('Tháng 10', _sessionFilterMonth == '10', () {
            setState(() {
              _sessionFilterMonth = _sessionFilterMonth == '10' ? 'ALL' : '10';
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('Tháng 11', _sessionFilterMonth == '11', () {
            setState(() {
              _sessionFilterMonth = _sessionFilterMonth == '11' ? 'ALL' : '11';
            });
          }),
          const SizedBox(width: 6),
          _buildFilterChip('Tháng 12', _sessionFilterMonth == '12', () {
            setState(() {
              _sessionFilterMonth = _sessionFilterMonth == '12' ? 'ALL' : '12';
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _blue : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(AttendanceSessionSummaryModel session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tiết ${session.slotNumber}',
                  style: const TextStyle(color: _blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                session.subjectName ?? 'Môn học',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDisplayDate(session.attendanceDate),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniColorBadge('Có mặt: ${session.presentCount}', _colorPresent),
              const SizedBox(width: 6),
              _buildMiniColorBadge('Phép: ${session.excusedCount}', _colorExcused),
              const SizedBox(width: 6),
              _buildMiniColorBadge('K.Phép: ${session.unexcusedCount}', _colorUnexcused),
              const SizedBox(width: 6),
              _buildMiniColorBadge('Muộn: ${session.lateCount}', _colorLate),
              const Spacer(),
              InkWell(
                onTap: () async {
                  if (_selectedClassId == null) return;
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AttendanceSheetScreen(
                        classId: _selectedClassId!,
                        className: _classHistory?.className,
                        subjectId: session.subjectId,
                        subjectName: session.subjectName,
                        slotNumber: session.slotNumber,
                        attendanceDate: session.attendanceDate,
                      ),
                    ),
                  );
                  if (updated == true) {
                    _loadClassHistory(_selectedClassId!);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: session.canEdit ? _orange.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: session.canEdit ? _orange : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        session.canEdit ? Icons.edit : Icons.visibility,
                        size: 13,
                        color: session.canEdit ? _orange : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.canEdit ? 'Sửa' : 'Xem lại',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: session.canEdit ? _orange : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (session.absentStudents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Vắng/Muộn: ${session.absentStudents.join(", ")}',
              style: const TextStyle(fontSize: 11, color: _colorUnexcused, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniColorBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==========================================
  // TAB 2: THEO HỌC SINH (ROSTER + DETAIL SHEET)
  // ==========================================

  Widget _buildStudentRosterTab() {
    final summaries = _classHistory?.studentSummaries ?? [];

    // Filter by search text and quick filter
    final filtered = summaries.where((s) {
      if (_studentSearchQuery.isNotEmpty) {
        final q = _studentSearchQuery.toLowerCase();
        final matchName = s.studentName.toLowerCase().contains(q);
        final matchCode = s.studentCode.toLowerCase().contains(q);
        if (!matchName && !matchCode) return false;
      }

      if (_studentFilter == 'AT_RISK') {
        return s.isAtRisk || s.unexcusedCount >= 1 || s.attendanceRate < 85;
      } else if (_studentFilter == 'ABSENT') {
        return (s.excusedCount + s.unexcusedCount) > 0;
      } else if (_studentFilter == 'LATE') {
        return s.lateCount > 0;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter header for Student Roster
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _studentSearchQuery = val.trim()),
            decoration: const InputDecoration(
              icon: Icon(Icons.search, size: 20, color: Colors.grey),
              hintText: 'Tìm kiếm theo tên hoặc mã học sinh...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Quick status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tất cả (${summaries.length})', _studentFilter == 'ALL', () {
                setState(() => _studentFilter = 'ALL');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Cần lưu ý', _studentFilter == 'AT_RISK', () {
                setState(() => _studentFilter = 'AT_RISK');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Có vắng học', _studentFilter == 'ABSENT', () {
                setState(() => _studentFilter = 'ABSENT');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Có đi muộn', _studentFilter == 'LATE', () {
                setState(() => _studentFilter = 'LATE');
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          _buildEmptyState('Không tìm thấy học sinh nào phù hợp')
        else
          ...filtered.map((s) => _buildStudentRosterCard(s)),
      ],
    );
  }

  Widget _buildStudentRosterCard(AttendanceStudentSummaryModel s) {
    Color rateColor = _colorPresent;
    if (s.attendanceRate < 70 || s.unexcusedCount >= 3) {
      rateColor = _colorUnexcused;
    } else if (s.attendanceRate < 85 || s.unexcusedCount >= 1) {
      rateColor = _colorLate;
    }

    final isCriticalUnexcused = s.unexcusedCount >= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCriticalUnexcused ? _colorUnexcused.withOpacity(0.6) : _border,
          width: isCriticalUnexcused ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showStudentDetailModal(context, s),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _blue.withOpacity(0.1),
                    child: Text(
                      s.studentName.isNotEmpty ? s.studentName.substring(0, 1).toUpperCase() : 'H',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _blue, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.studentName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Mã: ${s.studentCode}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Individual rate badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rateColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${s.attendanceRate.toStringAsFixed(1)}%',
                          style: TextStyle(color: rateColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chuyên cần',
                          style: TextStyle(color: rateColor, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              // Tags breakdown
              Row(
                children: [
                  _buildMiniColorBadge('Có mặt: ${s.presentCount}', _colorPresent),
                  const SizedBox(width: 6),
                  _buildMiniColorBadge('Phép: ${s.excusedCount}', _colorExcused),
                  const SizedBox(width: 6),
                  _buildMiniColorBadge('K.Phép: ${s.unexcusedCount}', _colorUnexcused),
                  const SizedBox(width: 6),
                  _buildMiniColorBadge('Muộn: ${s.lateCount}', _colorLate),
                ],
              ),
              if (isCriticalUnexcused) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorUnexcused.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: _colorUnexcused),
                      const SizedBox(width: 4),
                      Text(
                        'Cảnh báo: Vắng không phép ${s.unexcusedCount} buổi (Nguy cơ cấm thi)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _colorUnexcused),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Personal Student Detail Modal Sheet
  void _showStudentDetailModal(BuildContext context, AttendanceStudentSummaryModel student) {
    Color rateColor = _colorPresent;
    if (student.attendanceRate < 70 || student.unexcusedCount >= 3) {
      rateColor = _colorUnexcused;
    } else if (student.attendanceRate < 85 || student.unexcusedCount >= 1) {
      rateColor = _colorLate;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Student Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _blue.withOpacity(0.15),
                      child: Text(
                        student.studentName.isNotEmpty ? student.studentName.substring(0, 1).toUpperCase() : 'H',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _blue, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.studentName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Mã HS: ${student.studentCode} | Lớp: ${_classHistory?.className ?? ""}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Rate & Stats Overview Box
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tỷ lệ chuyên cần cá nhân', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                '${student.attendanceRate.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: rateColor),
                              ),
                              Text(
                                'Được điểm danh ${student.totalTrackedSessions} buổi',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: rateColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.warningNote,
                              style: TextStyle(color: rateColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMiniColorStat('Có mặt', '${student.presentCount}', _colorPresent)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildMiniColorStat('Có phép', '${student.excusedCount}', _colorExcused)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildMiniColorStat('K.Phép', '${student.unexcusedCount}', _colorUnexcused)),
                          const SizedBox(width: 6),
                          Expanded(child: _buildMiniColorStat('Đi muộn', '${student.lateCount}', _colorLate)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Timeline Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: _blue),
                    const SizedBox(width: 6),
                    const Text(
                      'Lịch sử điểm danh cá nhân',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    Text(
                      '${student.records.length} buổi',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Student's Records List
              Expanded(
                child: student.records.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có bản ghi điểm danh nào',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: student.records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (_, idx) {
                          final rec = student.records[idx];
                          Color badgeColor = _colorPresent;
                          if (rec.status == 'EXCUSED_ABSENCE') {
                            badgeColor = _colorExcused;
                          } else if (rec.status == 'UNEXCUSED_ABSENCE') {
                            badgeColor = _colorUnexcused;
                          } else if (rec.status == 'LATE') {
                            badgeColor = _colorLate;
                          }

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatDisplayDate(rec.attendanceDate),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.subjectName.isNotEmpty
                                            ? '${rec.subjectName} (Tiết ${rec.slotNumber ?? 1})'
                                            : 'Tiết ${rec.slotNumber ?? 1}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      if (rec.note.isNotEmpty)
                                        Text(
                                          'Ghi chú: ${rec.note}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rec.statusLabel,
                                    style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniColorStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildAtRiskSection(List<AttendanceAtRiskStudentModel> list) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _colorUnexcused.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _colorUnexcused.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _colorUnexcused, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Học sinh cần lưu ý / Cảnh báo chuyên cần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _colorUnexcused),
              ),
              const Spacer(),
              Text(
                '${list.length} học sinh',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _colorUnexcused),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...list.map((s) {
            final isCritical = s.unexcusedCount >= 3 || s.rate < 70;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCritical ? _colorUnexcused.withOpacity(0.5) : _colorLate.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.studentName} (${s.studentCode})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          s.warningNote,
                          style: TextStyle(
                            fontSize: 11,
                            color: isCritical ? _colorUnexcused : _colorLate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical ? _colorUnexcused.withOpacity(0.12) : _colorLate.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCritical ? 'Nguy cơ cấm thi' : 'Cảnh báo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCritical ? _colorUnexcused : _colorLate,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // STUDENT VIEW (PERSONAL ATTENDANCE)
  // ==========================================

  Widget _buildStudentView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_summary != null) _buildStudentSummaryCard(_summary!),
        const SizedBox(height: 20),
        const Text(
          'Lịch sử điểm danh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_records.isEmpty)
          _buildEmptyState('Chưa có dữ liệu điểm danh')
        else
          ..._records.map(_buildRecordCard),
      ],
    );
  }

  Widget _buildStudentSummaryCard(AttendanceSummary s) {
    Color rateColor = _colorPresent;
    Color rateBg = _colorPresent.withOpacity(0.12);
    if (s.attendanceRate < 70 || s.unexcusedAbsentCount >= 3) {
      rateColor = _colorUnexcused;
      rateBg = _colorUnexcused.withOpacity(0.12);
    } else if (s.attendanceRate < 85 || s.unexcusedAbsentCount >= 1) {
      rateColor = _colorLate;
      rateBg = _colorLate.withOpacity(0.12);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.studentName.isNotEmpty ? s.studentName : 'Học sinh',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lớp: ${s.className} | MS: ${s.studentCode}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: rateBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.statusNote,
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tỷ lệ chuyên cần', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(
                      '${s.attendanceRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: rateColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng số buổi: ${s.totalSessions}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatBox('Có mặt', s.presentCount.toString(), _colorPresent, _colorPresent.withOpacity(0.1)),
                    _buildStatBox('Phép', s.excusedAbsentCount.toString(), _colorExcused, _colorExcused.withOpacity(0.1)),
                    _buildStatBox('K.Phép', s.unexcusedAbsentCount.toString(), _colorUnexcused, _colorUnexcused.withOpacity(0.1)),
                    _buildStatBox('Muộn', s.lateCount.toString(), _colorLate, _colorLate.withOpacity(0.1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(AttendanceRecord record) {
    Color badgeColor;
    Color badgeBg;

    switch (record.status.toUpperCase()) {
      case 'PRESENT':
        badgeColor = _colorPresent;
        badgeBg = _colorPresent.withOpacity(0.12);
        break;
      case 'EXCUSED_ABSENCE':
        badgeColor = _colorExcused;
        badgeBg = _colorExcused.withOpacity(0.12);
        break;
      case 'UNEXCUSED_ABSENCE':
        badgeColor = _colorUnexcused;
        badgeBg = _colorUnexcused.withOpacity(0.12);
        break;
      case 'LATE':
        badgeColor = _colorLate;
        badgeBg = _colorLate.withOpacity(0.12);
        break;
      default:
        badgeColor = const Color(0xFF475569);
        badgeBg = const Color(0xFFF1F5F9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  '${record.attendanceDate.day}/${record.attendanceDate.month}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                Text(
                  record.attendanceDate.year.toString(),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.subjectName.isNotEmpty
                          ? record.subjectName
                          : (record.slotNumber != null ? 'Tiết ${record.slotNumber}' : 'Buổi học'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.statusLabel,
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (record.slotNumber != null && record.subjectName.isNotEmpty)
                  Text(
                    'Tiết ${record.slotNumber} - Lớp ${record.className}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ghi chú: ${record.note}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState([String? message]) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message ?? 'Chưa có dữ liệu điểm danh',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
