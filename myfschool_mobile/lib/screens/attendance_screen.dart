import 'package:flutter/material.dart';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/services/attendance_api.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceSummary? _summary;
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chuyên cần & Điểm danh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null) _buildSummaryCard(_summary!),
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
                    _buildEmptyState()
                  else
                    ..._records.map(_buildRecordCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(AttendanceSummary s) {
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Chưa có dữ liệu điểm danh',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
