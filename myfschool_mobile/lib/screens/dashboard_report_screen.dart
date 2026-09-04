import 'package:flutter/material.dart';
import 'package:myfschools/services/report_api.dart';
import 'package:myfschools/services/user_session.dart';

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({super.key});

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _data;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = UserSession.instance.currentUser;
    _isAdmin = user?.role == 'Admin';

    try {
      Map<String, dynamic>? res;
      if (_isAdmin) {
        res = await ReportApi.instance.getAdminDashboard();
      } else {
        res = await ReportApi.instance.getTeacherHomeroomDashboard();
      }

      if (mounted) {
        if (res != null) {
          setState(() {
            _data = res;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không thể tải dữ liệu báo cáo thống kê';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'Báo cáo toàn trường' : 'Báo cáo lớp chủ nhiệm',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('Không có dữ liệu báo cáo'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isAdmin && _data!['className'] != null) ...[
              _buildClassBanner(_data!['className'], _data!['homeroomTeacherName']),
              const SizedBox(height: 16),
            ],
            _buildOverviewCards(),
            const SizedBox(height: 16),
            _buildAttendanceCard(),
            const SizedBox(height: 16),
            _buildGradeStatsCard(),
            const SizedBox(height: 16),
            _buildLeaveRequestCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassBanner(String className, String? teacherName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C7BEF), Color(0xFF1B55B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lớp $className',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Giáo viên chủ nhiệm: ${teacherName ?? "N/A"}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Học sinh',
            value: '${_data!['totalStudents'] ?? 0}',
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF2C7BEF),
          ),
        ),
        const SizedBox(width: 12),
        if (_isAdmin)
          Expanded(
            child: _buildMetricCard(
              title: 'Giáo viên',
              value: '${_data!['totalTeachers'] ?? 0}',
              icon: Icons.school_outlined,
              color: const Color(0xFF10B981),
            ),
          ),
        if (!_isAdmin)
          Expanded(
            child: _buildMetricCard(
              title: 'Đơn chờ duyệt',
              value: '${_data!['pendingLeaveRequests'] ?? 0}',
              icon: Icons.pending_actions_outlined,
              color: const Color(0xFFF59E0B),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final rate = (_data!['attendanceRate'] ?? 100.0).toDouble();
    final present = _data!['presentCount'] ?? 0;
    final excused = _data!['excusedAbsenceCount'] ?? 0;
    final unexcused = _data!['unexcusedAbsenceCount'] ?? 0;
    final late = _data!['lateCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tỷ lệ chuyên cần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '$rate%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: rate >= 90 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: rate / 100.0,
            backgroundColor: const Color(0xFFE5E7EB),
            color: rate >= 90 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStat('Có mặt', '$present', const Color(0xFF10B981)),
              _buildSmallStat('Có phép', '$excused', const Color(0xFF3B82F6)),
              _buildSmallStat('Không phép', '$unexcused', const Color(0xFFEF4444)),
              _buildSmallStat('Đi muộn', '$late', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
        ),
      ],
    );
  }

  Widget _buildGradeStatsCard() {
    final gpa = (_isAdmin ? _data!['averageSchoolGpa'] : _data!['averageClassGpa']) ?? 0.0;
    final dist = _data!['gradeDistribution'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê học lực',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C7BEF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ĐTB: $gpa',
                  style: const TextStyle(
                    color: Color(0xFF2C7BEF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dist.isEmpty)
            const Text('Chưa có dữ liệu điểm số', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dist.entries.map((e) {
                return Chip(
                  label: Text('${e.key}: ${e.value}'),
                  backgroundColor: const Color(0xFFF3F4F6),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard() {
    final pending = _data!['pendingLeaveRequests'] ?? 0;
    final total = _data!['totalLeaveRequests'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_alt_outlined, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng số đơn xin nghỉ', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
                  Text('$total đơn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pending chờ duyệt',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
