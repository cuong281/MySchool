import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/models/attendance_history_model.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/attendance_api.dart';
import 'package:myfschools/services/school_class_api.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/screens/attendance_sheet_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _blue = Color(0xFF1A3C6E);
  static const _orange = Color(0xFFF26B21);
  static const _bg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  bool _isLoading = true;

  // Student view data
  AttendanceSummary? _summary;
  List<AttendanceRecord> _records = [];

  // Teacher/Admin view data
  List<SchoolClassModel> _classes = [];
  int? _selectedClassId;
  AttendanceClassHistoryModel? _classHistory;

  bool get _isStaff {
    final user = UserSession.instance.currentUser;
    return (user?.isTeacher == true) || (user?.isAdmin == true);
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);

    if (_isStaff) {
      final classes = await SchoolClassApi.instance.getAllClasses();
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
          // Overall Class Stats Card
          _buildClassSummaryCard(_classHistory!),
          const SizedBox(height: 20),

          // At-risk students section
          if (_classHistory!.atRiskStudents.isNotEmpty) ...[
            _buildAtRiskSection(_classHistory!.atRiskStudents),
            const SizedBox(height: 20),
          ],

          // Session history section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử các buổi học',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${_classHistory!.sessions.length} buổi',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_classHistory!.sessions.isEmpty)
            _buildEmptyState('Chưa có buổi học nào được điểm danh cho lớp này')
          else
            ..._classHistory!.sessions.map(_buildSessionCard),
        ] else
          _buildEmptyState('Không tìm thấy dữ liệu điểm danh của lớp'),
      ],
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
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
    );
  }

  Widget _buildClassSummaryCard(AttendanceClassHistoryModel hist) {
    Color rateColor = const Color(0xFF059669);
    if (hist.attendanceRate < 75) {
      rateColor = const Color(0xFFDC2626);
    } else if (hist.attendanceRate < 88) {
      rateColor = const Color(0xFFD97706);
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
              Text(
                'Tổng quan lớp ${hist.className}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rateColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tỷ lệ: ${hist.attendanceRate.toStringAsFixed(1)}%',
                  style: TextStyle(color: rateColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStaffStatBox('Tổng lượt', '${hist.totalSessions}', Colors.blueGrey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox('Có mặt', '${hist.presentCount}', Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox('Có phép', '${hist.excusedCount}', Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox('Không phép', '${hist.unexcusedCount}', Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStaffStatBox('Đi muộn', '${hist.lateCount}', Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStatBox(String label, String value, MaterialColor color) {
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color.shade900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskSection(List<AttendanceAtRiskStudentModel> list) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Học sinh cần lưu ý / Cảnh báo chuyên cần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
              const Spacer(),
              Text(
                '${list.length} học sinh',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade700),
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
                border: Border.all(color: isCritical ? Colors.red.shade300 : Colors.orange.shade200),
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
                            color: isCritical ? Colors.red.shade800 : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical ? Colors.red.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCritical ? 'Nguy cơ cấm thi' : 'Cảnh báo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.red.shade900 : Colors.orange.shade900,
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
              _buildMiniSessionBadge('Có mặt: ${session.presentCount}', Colors.green),
              const SizedBox(width: 6),
              _buildMiniSessionBadge('Phép: ${session.excusedCount}', Colors.blue),
              const SizedBox(width: 6),
              _buildMiniSessionBadge('K.Phép: ${session.unexcusedCount}', Colors.red),
              const SizedBox(width: 6),
              _buildMiniSessionBadge('Muộn: ${session.lateCount}', Colors.orange),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          fontSize: 11,
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
              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniSessionBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color.shade900, fontWeight: FontWeight.w500),
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
    Color rateColor = const Color(0xFF059669);
    Color rateBg = const Color(0xFFD1FAE5);
    if (s.attendanceRate < 70 || s.unexcusedAbsentCount >= 3) {
      rateColor = const Color(0xFFDC2626);
      rateBg = const Color(0xFFFEE2E2);
    } else if (s.attendanceRate < 85 || s.unexcusedAbsentCount >= 1) {
      rateColor = const Color(0xFFD97706);
      rateBg = const Color(0xFFFEF3C7);
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
                    _buildStatBox('Có mặt', s.presentCount.toString(), const Color(0xFF059669), const Color(0xFFD1FAE5)),
                    _buildStatBox('Phép', s.excusedAbsentCount.toString(), const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
                    _buildStatBox('K.Phép', s.unexcusedAbsentCount.toString(), const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                    _buildStatBox('Muộn', s.lateCount.toString(), const Color(0xFFD97706), const Color(0xFFFEF3C7)),
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
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFD1FAE5);
        break;
      case 'EXCUSED_ABSENCE':
        badgeColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFDBEAFE);
        break;
      case 'UNEXCUSED_ABSENCE':
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        break;
      case 'LATE':
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
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
