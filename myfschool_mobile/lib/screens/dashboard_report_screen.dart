import 'package:flutter/material.dart';
import 'package:myfschools/screens/admin_request_list_screen.dart';
import 'package:myfschools/services/report_api.dart';
import 'package:myfschools/services/user_session.dart';

class _GradeSegment {
  final String label;
  final int count;
  final Color color;

  const _GradeSegment(this.label, this.count, this.color);
}

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({super.key});

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  bool _isLoading = true;
  bool _isFilterLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _data;
  bool _isAdmin = false;

  String _selectedYear = '2025-2026';
  int _selectedSemester = 1;
  final List<String> _availableYears = ['2025-2026', '2024-2025'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool isSemesterChange = false}) async {
    if (isSemesterChange) {
      setState(() {
        _isFilterLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final user = UserSession.instance.currentUser;
    _isAdmin = user?.role == 'Admin';

    try {
      Map<String, dynamic>? res;
      if (_isAdmin) {
        res = await ReportApi.instance.getAdminDashboard(
          academicYear: _selectedYear,
          semester: _selectedSemester,
        );
      } else {
        res = await ReportApi.instance.getTeacherHomeroomDashboard(
          academicYear: _selectedYear,
          semester: _selectedSemester,
        );
      }

      if (mounted) {
        if (res != null) {
          setState(() {
            _data = res;
            _isLoading = false;
            _isFilterLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không thể tải dữ liệu báo cáo thống kê';
            _isLoading = false;
            _isFilterLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Đã xảy ra lỗi kết nối: $e';
          _isLoading = false;
          _isFilterLoading = false;
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
                onPressed: () => _loadDashboardData(),
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
      onRefresh: () => _loadDashboardData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar: Academic Year & Semester
            _buildFilterBar(),
            const SizedBox(height: 14),

            if (!_isAdmin && _data!['className'] != null) ...[
              _buildClassBanner(_data!['className'], _data!['homeroomTeacherName']),
              const SizedBox(height: 16),
            ],

            // Content wrapped with smooth loading transition
            AnimatedOpacity(
              opacity: _isFilterLoading ? 0.45 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AbsorbPointer(
                absorbing: _isFilterLoading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        children: [
          Row(
            children: [
              // Academic Year Dropdown
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      items: _availableYears.map((year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2C7BEF)),
                              const SizedBox(width: 6),
                              Text('Năm học $year'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedYear) {
                          setState(() {
                            _selectedYear = val;
                          });
                          _loadDashboardData(isSemesterChange: true);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Semester Segmented Buttons
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSemesterTab(
                          label: 'Học kỳ 1',
                          semester: 1,
                          isSelected: _selectedSemester == 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: _buildSemesterTab(
                          label: 'Học kỳ 2',
                          semester: 2,
                          isSelected: _selectedSemester == 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isFilterLoading) ...[
            const SizedBox(height: 8),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C7BEF)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSemesterTab({
    required String label,
    required int semester,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedSemester != semester) {
          setState(() {
            _selectedSemester = semester;
          });
          _loadDashboardData(isSemesterChange: true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C7BEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2C7BEF).withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
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
    if (_isAdmin) {
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
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              title: 'Giáo viên',
              value: '${_data!['totalTeachers'] ?? 0}',
              icon: Icons.school_outlined,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              title: 'Lớp học',
              value: '${_data!['totalClasses'] ?? 2}',
              icon: Icons.meeting_room_outlined,
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      );
    }

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final rate = (_data!['attendanceRate'] ?? 0.0).toDouble();
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
                'Thống kê chuyên cần (Hôm nay)',
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
            value: (rate / 100.0).clamp(0.0, 1.0),
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

    final xs = ((dist['Xuất sắc'] ?? dist['Xuat sac'] ?? 0) as num).toInt();
    final g = ((dist['Giỏi'] ?? dist['Gioi'] ?? 0) as num).toInt();
    final k = ((dist['Khá'] ?? dist['Kha'] ?? 0) as num).toInt();
    final tb = ((dist['Trung bình'] ?? dist['Trung binh'] ?? 0) as num).toInt();
    final y = ((dist['Yếu'] ?? dist['Yeu'] ?? 0) as num).toInt();

    final segments = [
      _GradeSegment('Xuất sắc', xs, const Color(0xFF2563EB)),
      _GradeSegment('Giỏi', g, const Color(0xFF10B981)),
      _GradeSegment('Khá', k, const Color(0xFFF59E0B)),
      _GradeSegment('Trung bình', tb, const Color(0xFFF97316)),
      _GradeSegment('Yếu', y, const Color(0xFFEF4444)),
    ];

    // CRITICAL: Only render segments with count > 0 to prevent Flutter Expanded(flex: 0) error!
    final activeSegments = segments.where((s) => s.count > 0).toList();
    final totalGraded = segments.fold<int>(0, (sum, item) => sum + item.count);

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 14),

          // Multi-color Segmented Progress Bar (Safe from flex: 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: activeSegments.isEmpty
                  ? Container(color: const Color(0xFFE2E8F0))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: activeSegments.map((s) {
                        return Expanded(
                          flex: s.count,
                          child: Container(
                            color: s.color,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend list with counts and percentages
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: segments.map((s) {
              final pct = totalGraded > 0 ? ((s.count / totalGraded) * 100).toStringAsFixed(0) : '0';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label}: ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '${s.count} ($pct%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: s.count > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_isAdmin) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminRequestListScreen()),
            );
            _loadDashboardData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (_isAdmin) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

