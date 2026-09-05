import 'package:flutter/material.dart';
import 'package:myfschools/models/reward_discipline_model.dart';
import 'package:myfschools/services/reward_discipline_service.dart';
import 'package:myfschools/services/user_session.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/school_class_api.dart';

class RewardDisciplineScreen extends StatefulWidget {
  const RewardDisciplineScreen({super.key});

  @override
  State<RewardDisciplineScreen> createState() => _RewardDisciplineScreenState();
}

class _RewardDisciplineScreenState extends State<RewardDisciplineScreen> {
  final RewardDisciplineService _service = RewardDisciplineService();
  List<RewardDisciplineModel> _data = [];
  List<SchoolClassModel> _classes = [];

  bool _isLoading = true;
  int? _selectedClassId;
  String _selectedType = 'Tất cả'; // Tất cả, Khen thưởng, Kỷ luật
  int? _selectedSemester; // null (Tất cả kỳ), 1 (Học kỳ 1), 2 (Học kỳ 2)

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = UserSession.instance.currentUser;
    if (user?.role == 'Admin') {
      try {
        final classes = await SchoolClassApi.instance.getAllClasses();
        if (mounted) setState(() => _classes = classes);
      } catch (e) {
        debugPrint('Error loading classes: $e');
      }
    }
    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final typeParam = _selectedType == 'Tất cả'
          ? null
          : (_selectedType == 'Khen thưởng' ? 'REWARD' : 'DISCIPLINE');

      final items = await _service.getRewards(
        classId: _selectedClassId,
        semester: _selectedSemester,
        type: typeParam,
      );

      if (mounted) {
        setState(() {
          _data = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reward discipline data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final isAdmin = user?.role == 'Admin';
    final isTeacher = user?.role == 'Teacher';
    final isStudent = user?.role == 'Student';

    final rewardCount = _data.where((i) => _isReward(i.type)).length;
    final disciplineCount = _data.where((i) => !_isReward(i.type)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Khen thưởng & Kỷ luật',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // 1. Role Context Banner
          _buildRoleBanner(isAdmin: isAdmin, isTeacher: isTeacher, isStudent: isStudent, rewardCount: rewardCount, disciplineCount: disciplineCount),

          // 2. Filter Bar
          _buildFilterBar(isAdmin: isAdmin),

          // 3. Main Data List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _data.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _data.length,
                          itemBuilder: (context, index) => _buildItemCard(_data[index], isStudent: isStudent),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool _isReward(String type) {
    final lower = type.toLowerCase();
    return lower.contains('khen') || lower.contains('reward');
  }

  Widget _buildRoleBanner({
    required bool isAdmin,
    required bool isTeacher,
    required bool isStudent,
    required int rewardCount,
    required int disciplineCount,
  }) {
    final user = UserSession.instance.currentUser;
    String title = 'Toàn trường';
    String subtitle = 'Quản trị viên có quyền xem và lọc toàn bộ dữ liệu';
    IconData iconData = Icons.admin_panel_settings_rounded;
    Color iconBg = const Color(0xFF1565C0);

    if (isTeacher) {
      final homeroomClass = _data.isNotEmpty ? (_data.first.className ?? '10A1') : 'Lớp chủ nhiệm';
      title = 'Lớp chủ nhiệm: $homeroomClass';
      subtitle = 'GVCN: ${user?.fullName ?? user?.username ?? "Giáo viên"} • Dữ liệu học sinh lớp chủ nhiệm';
      iconData = Icons.school_rounded;
      iconBg = const Color(0xFF0D47A1);
    } else if (isStudent) {
      final studentClass = _data.isNotEmpty ? (_data.first.className ?? user?.className ?? '10A1') : (user?.className ?? '');
      final studentCode = _data.isNotEmpty ? (_data.first.studentCode ?? user?.studentCode ?? '') : (user?.studentCode ?? '');
      title = user?.fullName ?? user?.username ?? 'Học sinh';
      subtitle = 'Lớp: $studentClass ${studentCode.isNotEmpty ? "• Mã HS: $studentCode" : ""}';
      iconData = Icons.person_rounded;
      iconBg = const Color(0xFF00695C);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconBg, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3C6E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Counters
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$rewardCount Khen',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-$disciplineCount Phạt',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({required bool isAdmin}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              // Class dropdown (Admin only)
              if (isAdmin) ...[
                Expanded(
                  flex: 11,
                  child: _buildDropdownFilter<int?>(
                    value: _selectedClassId,
                    items: [null, ..._classes.map((c) => c.id)],
                    itemLabels: {null: 'Tất cả lớp', for (var c in _classes) c.id: c.className},
                    onChanged: (v) {
                      _selectedClassId = v;
                      _fetchData();
                    },
                    icon: Icons.meeting_room_rounded,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Type dropdown
              Expanded(
                flex: 11,
                child: _buildDropdownFilter<String>(
                  value: _selectedType,
                  items: const ['Tất cả', 'Khen thưởng', 'Kỷ luật'],
                  onChanged: (v) {
                    if (v != null) {
                      _selectedType = v;
                      _fetchData();
                    }
                  },
                  icon: Icons.filter_alt_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Semester dropdown
              Expanded(
                flex: 11,
                child: _buildDropdownFilter<int?>(
                  value: _selectedSemester,
                  items: const [null, 1, 2],
                  itemLabels: const {
                    null: 'Tất cả kỳ',
                    1: 'Học kỳ 1',
                    2: 'Học kỳ 2',
                  },
                  onChanged: (v) {
                    _selectedSemester = v;
                    _fetchData();
                  },
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required T value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E), fontWeight: FontWeight.w700),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF1565C0)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabels != null ? itemLabels[item]! : item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildItemCard(RewardDisciplineModel item, {required bool isStudent}) {
    final isReward = _isReward(item.type);
    final mainColor = isReward ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgBadgeColor = isReward ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: mainColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Ribbon: Type + Semester + Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgBadgeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  isReward ? Icons.military_tech_rounded : Icons.gavel_rounded,
                  color: mainColor,
                  size: 19,
                ),
                const SizedBox(width: 6),
                Text(
                  isReward ? 'KHEN THƯỞNG' : 'KỶ LUẬT',
                  style: TextStyle(
                    color: mainColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                if (item.semester != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HK${item.semester}',
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.event_note_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.date),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Main Content Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student row (show if Admin or Teacher, or show student info if Student)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: mainColor.withOpacity(0.1),
                      child: Text(
                        (item.userName != null && item.userName!.isNotEmpty)
                            ? item.userName![0].toUpperCase()
                            : 'H',
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.userName ?? 'Học sinh',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A3C6E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.studentCode != null && item.studentCode!.isNotEmpty)
                                Text(
                                  'Mã: ${item.studentCode} • ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                'Lớp: ${item.className ?? "N/A"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (item.decisionNumber != null && item.decisionNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          item.decisionNumber!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF37474F),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.7),
                const SizedBox(height: 10),

                // Specific category/title if available
                if (item.typeName != null && item.typeName!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        isReward ? Icons.verified_rounded : Icons.info_outline_rounded,
                        size: 15,
                        color: mainColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.typeName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Content description
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF263238),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu phù hợp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc học kỳ, loại hoặc lớp để xem kết quả',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
