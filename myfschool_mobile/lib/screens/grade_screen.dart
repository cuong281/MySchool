import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschools/controllers/GradeController.dart';
import 'package:myfschools/models/grade.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/models/teacher_assignment_model.dart';
import 'package:myfschools/services/school_class_api.dart';
import 'package:myfschools/services/teacher_assignment_api.dart';
import 'package:myfschools/services/user_session.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen>
    with SingleTickerProviderStateMixin {
  Future<List<Grade>>? _gradesFuture;
  late AnimationController _animCtrl;

  // Filters
  String _selectedSemester = 'HK1'; // 'HK1', 'HK2', 'Cả năm'
  String _searchQuery = '';
  String _sortBy = 'Tên học sinh'; // 'Tên học sinh', 'GPA: Cao - Thấp', 'GPA: Thấp - Cao'
  String _selectedSubject = 'Tất cả môn';

  // Expansion state for accordion cards (User specifically requested resetting when switching class/semester)
  final Set<int> _expandedStudentIds = {};

  // Admin class list
  List<SchoolClassModel> _adminClasses = [];
  int? _selectedAdminClassId;
  String _selectedAdminClassName = 'Tất cả lớp';

  // Teacher assignments & selected class
  List<TeacherAssignmentModel> _teacherAssignments = [];
  int? _selectedClassId;
  String _selectedClassName = '';
  bool _isCurrentClassHomeroom = false;
  String? _currentSubjectName;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    final user = UserSession.instance.currentUser;
    if (user != null && !user.isTeacher && user.role != 'Teacher' && user.role != 'Admin') {
      _gradesFuture = GradeController.getMyGrades();
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = UserSession.instance.currentUser;
    if (user == null) return;

    try {
      if (user.role == 'Admin') {
        final classes = await SchoolClassApi.instance.getAllClasses();
        if (mounted) {
          setState(() {
            _adminClasses = classes;
          });
        }
      } else if (user.isTeacher || user.role == 'Teacher') {
        final assignments = await TeacherAssignmentApi.instance.getMyAssignments();
        if (mounted) {
          setState(() {
            _teacherAssignments = assignments;
            // Prefer Homeroom class if assigned, otherwise first assignment
            final homeroomList = assignments.where((a) => a.isHomeroom).toList();
            if (homeroomList.isNotEmpty) {
              _selectedClassId = homeroomList.first.classId;
              _selectedClassName = homeroomList.first.className;
              _isCurrentClassHomeroom = true;
              _currentSubjectName = homeroomList.first.subjectName;
            } else if (assignments.isNotEmpty) {
              _selectedClassId = assignments.first.classId;
              _selectedClassName = assignments.first.className;
              _isCurrentClassHomeroom = assignments.first.isHomeroom;
              _currentSubjectName = assignments.first.subjectName;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu ban đầu bảng điểm: $e');
    }

    if (mounted) {
      _loadGrades();
    }
  }

  void _loadGrades() {
    final user = UserSession.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (user.role == 'Admin') {
        if (_selectedAdminClassId == null) {
          _gradesFuture = GradeController.getAllGrades();
        } else {
          _gradesFuture = GradeController.getGradesByClass(_selectedAdminClassId!);
        }
      } else if (user.isTeacher || user.role == 'Teacher') {
        if (_selectedClassId != null) {
          _gradesFuture = GradeController.getGradesByClass(_selectedClassId!);
        } else {
          _gradesFuture = Future.value([]);
        }
      } else {
        // Student: view own grades
        _gradesFuture = GradeController.getMyGrades();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    _expandedStudentIds.clear();
    _loadGrades();
  }

  // ── User-requested reset on Class/Semester change ───────────────────
  void _onSelectClass(int classId, String className, bool isHomeroom, String? subjectName) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedClassId = classId;
      _selectedClassName = className;
      _isCurrentClassHomeroom = isHomeroom;
      _currentSubjectName = subjectName;
      _selectedSubject = 'Tất cả môn';
      _expandedStudentIds.clear(); // RESET AS INSTRUCTED!
      _loadGrades();
    });
  }

  void _onSelectSemester(String sem) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSemester = sem;
      _expandedStudentIds.clear(); // RESET AS INSTRUCTED!
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final isTeacher = user?.isTeacher == true || user?.role == 'Teacher';
    final isAdmin = user?.role == 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (_isCurrentClassHomeroom
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF00897B))
                        .withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isTeacher, isAdmin),
                if (isTeacher) _buildTeacherScopeSelector(),
                if (isAdmin) _buildAdminClassSelector(),
                _buildSemesterFilter(),
                Expanded(
                  child: _gradesFuture == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        )
                      : FutureBuilder<List<Grade>>(
                          future: _gradesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1565C0),
                                ),
                              );
                            }
                      if (snapshot.hasError) {
                        return _buildError(snapshot.error.toString());
                      }

                      final rawGrades = snapshot.data ?? [];
                      final filtered = _processGrades(rawGrades);

                      return Column(
                        children: [
                          _buildContextBanner(rawGrades, isTeacher, isAdmin),
                          _buildToolbar(rawGrades, filtered, isTeacher, isAdmin),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildEmpty()
                                : _buildGradeList(filtered, isTeacher, isAdmin),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isTeacher, bool isAdmin) {
    String subTitle = 'Kết quả học tập cá nhân';
    if (isAdmin) {
      subTitle = 'Quản trị viên • Toàn trường';
    } else if (isTeacher) {
      subTitle = _isCurrentClassHomeroom
          ? 'Lớp chủ nhiệm: $_selectedClassName'
          : 'Lớp bộ môn: $_selectedClassName';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCurrentClassHomeroom || isAdmin
              ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)]
              : [const Color(0xFF00695C), const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isCurrentClassHomeroom || isAdmin
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF00695C))
                .withOpacity(0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bảng điểm',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _refresh();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Teacher Class Scope Selector (Homeroom vs Subject Classes) ───────
  Widget _buildTeacherScopeSelector() {
    if (_teacherAssignments.isEmpty) return const SizedBox.shrink();

    // Deduplicate classes while prioritizing Homeroom roles
    final Map<int, TeacherAssignmentModel> uniqueClasses = {};
    for (var a in _teacherAssignments) {
      if (!uniqueClasses.containsKey(a.classId) || a.isHomeroom) {
        uniqueClasses[a.classId] = a;
      }
    }

    final classList = uniqueClasses.values.toList()
      ..sort((a, b) {
        if (a.isHomeroom && !b.isHomeroom) return -1;
        if (!a.isHomeroom && b.isHomeroom) return 1;
        return a.className.compareTo(b.className);
      });

    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: classList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = classList[index];
          final isSelected = _selectedClassId == item.classId;
          final isHrm = item.isHomeroom;

          return GestureDetector(
            onTap: () => _onSelectClass(
              item.classId,
              item.className,
              item.isHomeroom,
              item.subjectName,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isHrm ? const Color(0xFF1565C0) : const Color(0xFF00796B))
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? (isHrm ? const Color(0xFF1565C0) : const Color(0xFF00796B))
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isHrm
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF00796B))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHrm ? Icons.workspace_premium_rounded : Icons.menu_book_rounded,
                    size: 16,
                    color: isSelected
                        ? (isHrm ? const Color(0xFFFFD54F) : Colors.white)
                        : (isHrm ? const Color(0xFFE65100) : const Color(0xFF00796B)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isHrm
                        ? 'Lớp ${item.className} (Chủ nhiệm)'
                        : 'Lớp ${item.className} (Môn ${item.subjectName ?? "bộ môn"})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isHrm ? const Color(0xFF1565C0) : const Color(0xFF2D3748)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Admin Class Selector ────────────────────────────────────────────
  Widget _buildAdminClassSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.class_rounded, size: 18, color: Color(0xFF1565C0)),
          const SizedBox(width: 10),
          const Text(
            'Lớp học:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedAdminClassId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1565C0)),
                hint: Text(
                  _selectedAdminClassName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _selectedAdminClassId = v;
                    _selectedAdminClassName = v == null
                        ? 'Tất cả lớp'
                        : _adminClasses.firstWhere((c) => c.id == v).className;
                    _expandedStudentIds.clear();
                    _loadGrades();
                  });
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả lớp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  ..._adminClasses.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text('Lớp ${c.className}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Semester Filter ─────────────────────────────────────────────────
  Widget _buildSemesterFilter() {
    final semesters = ['HK1', 'HK2', 'Cả năm'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children: semesters.map((sem) {
          final isActive = _selectedSemester == sem;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onSelectSemester(sem),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1565C0) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    sem,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Contextual Statistics Banner ────────────────────────────────────
  Widget _buildContextBanner(List<Grade> allGrades, bool isTeacher, bool isAdmin) {
    if (allGrades.isEmpty) return const SizedBox.shrink();

    // Unique students count in current view
    final studentCount = allGrades.map((g) => g.studentId).toSet().length;

    // Filtered by current semester for stats
    final sem = _selectedSemester == 'HK1' ? 1 : (_selectedSemester == 'HK2' ? 2 : 0);
    final targetGrades = sem == 0
        ? _calculateAnnualGrades(allGrades)
        : allGrades.where((g) => g.semester == sem).toList();

    double avgGpa = 0.0;
    if (targetGrades.isNotEmpty) {
      avgGpa = targetGrades.fold<double>(0.0, (sum, g) => sum + g.averageScore) / targetGrades.length;
    }

    final isHrm = _isCurrentClassHomeroom || isAdmin;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHrm ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              color: isHrm ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isHrm ? Icons.stars_rounded : Icons.auto_stories_rounded,
              size: 20,
              color: isHrm ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTeacher
                      ? (_isCurrentClassHomeroom
                          ? 'Bảng điểm tổng hợp Lớp $_selectedClassName'
                          : 'Bảng điểm môn ${_currentSubjectName ?? "Bộ môn"} • Lớp $_selectedClassName')
                      : (isAdmin ? 'Thống kê toàn diện điểm số' : 'Kết quả học tập cá nhân'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sĩ số: $studentCount học sinh  •  ĐTB: ${avgGpa.toStringAsFixed(2)}  •  Kỳ: $_selectedSemester',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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

  // ── Toolbar: Context-Aware Subject Filter + Search + Sort + Bulk Toggle
  Widget _buildToolbar(
    List<Grade> rawGrades,
    List<Grade> filteredGrades,
    bool isTeacher,
    bool isAdmin,
  ) {
    final availableSubjects = rawGrades.map((g) => g.subjectName).toSet().toList()..sort();
    final isSubjectClass = isTeacher && !_isCurrentClassHomeroom;

    // Distinct students for expand/collapse all
    final currentStudentIds = filteredGrades.map((g) => g.studentId).toSet().toList();
    final allExpanded = currentStudentIds.isNotEmpty &&
        currentStudentIds.every((id) => _expandedStudentIds.contains(id));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Tìm học sinh...',
                      hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      icon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF1565C0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort dropdown
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF1565C0)),
                    onChanged: (v) => setState(() => _sortBy = v!),
                    items: ['Tên học sinh', 'GPA: Cao - Thấp', 'GPA: Thấp - Cao']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Context-aware Subject Filter & Expand All Toggle
          Row(
            children: [
              // 1. Subject filter
              if (isSubjectClass)
                // USER REQUIREMENT: In subject class, hide/lock dropdown and pin subject chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF81E6D9), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_added_rounded, size: 14, color: Color(0xFF00796B)),
                      const SizedBox(width: 5),
                      Text(
                        'Môn: ${_currentSubjectName ?? "Bộ môn"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Homeroom or Admin view: dropdown to filter subject freely
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF1565C0)),
                      onChanged: (v) => setState(() {
                        _selectedSubject = v ?? 'Tất cả môn';
                        _expandedStudentIds.clear();
                      }),
                      items: [
                        const DropdownMenuItem(
                          value: 'Tất cả môn',
                          child: Text('Tất cả môn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        ...availableSubjects.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // 2. Expand all / Collapse all button (For Homeroom/multi-subject view)
              if (!isSubjectClass && currentStudentIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (allExpanded) {
                        _expandedStudentIds.clear();
                      } else {
                        _expandedStudentIds.addAll(currentStudentIds);
                      }
                    });
                  },
                  icon: Icon(
                    allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                    size: 15,
                    color: const Color(0xFF1565C0),
                  ),
                  label: Text(
                    allExpanded ? 'Thu gọn tất cả' : 'Mở rộng tất cả',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Process Grades (Semester, Search, Subject Filter) ───────────────
  List<Grade> _processGrades(List<Grade> grades) {
    List<Grade> list;

    // 1. Filter by semester
    if (_selectedSemester == 'Cả năm') {
      list = _calculateAnnualGrades(grades);
    } else {
      final sem = _selectedSemester == 'HK1' ? 1 : 2;
      list = grades.where((g) => g.semester == sem).toList();
    }

    // 2. Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((g) => g.studentName.toLowerCase().contains(q)).toList();
    }

    // 3. Filter by selected subject (if not 'Tất cả môn')
    if (_selectedSubject != 'Tất cả môn') {
      list = list.where((g) => g.subjectName == _selectedSubject).toList();
    }

    return list;
  }

  List<Grade> _calculateAnnualGrades(List<Grade> allGrades) {
    final Map<String, List<Grade>> grouped = {};
    for (var g in allGrades) {
      final key = '${g.studentId}_${g.subjectCode}';
      grouped.putIfAbsent(key, () => []).add(g);
    }

    final List<Grade> annualGrades = [];
    grouped.forEach((key, list) {
      Grade? hk1 = list.firstWhere((g) => g.semester == 1, orElse: () => list.first);
      Grade? hk2 = list.firstWhere((g) => g.semester == 2, orElse: () => list.first);

      double annualScore = 0;
      bool hasHk1 = list.any((g) => g.semester == 1);
      bool hasHk2 = list.any((g) => g.semester == 2);

      if (hasHk1 && hasHk2) {
        annualScore = (hk1.averageScore + hk2.averageScore * 2) / 3;
      } else if (hasHk1) {
        annualScore = hk1.averageScore;
      } else if (hasHk2) {
        annualScore = hk2.averageScore;
      }

      final base = hasHk2 ? hk2 : hk1;
      annualGrades.add(
        Grade(
          id: base.id,
          studentId: base.studentId,
          studentName: base.studentName,
          className: base.className,
          subjectCode: base.subjectCode,
          subjectName: base.subjectName,
          semester: 0,
          attendanceScore: hk1.averageScore,
          midtermScore: hk2.averageScore,
          finalScore: annualScore,
          averageScore: annualScore,
          letterGrade: _getLetterGrade(annualScore),
          academicYear: base.academicYear,
        ),
      );
    });

    return annualGrades;
  }

  String _getLetterGrade(double score) {
    if (score >= 9.0) return 'Xuất sắc';
    if (score >= 8.0) return 'Giỏi';
    if (score >= 6.5) return 'Khá';
    if (score >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  // ── Grade List ──────────────────────────────────────────────────────
  Widget _buildGradeList(List<Grade> grades, bool isTeacher, bool isAdmin) {
    final Map<int, List<Grade>> grouped = {};
    for (final g in grades) {
      grouped.putIfAbsent(g.studentId, () => []).add(g);
    }

    var studentIds = grouped.keys.toList();
    if (_sortBy == 'Tên học sinh') {
      studentIds.sort((a, b) {
        final nameA = grouped[a]!.first.studentName.split(' ').last;
        final nameB = grouped[b]!.first.studentName.split(' ').last;
        return nameA.compareTo(nameB);
      });
    } else {
      final isDesc = _sortBy == 'GPA: Cao - Thấp';
      studentIds.sort((a, b) {
        final avgA = grouped[a]!.fold<double>(0.0, (s, g) => s + g.averageScore) / grouped[a]!.length;
        final avgB = grouped[b]!.fold<double>(0.0, (s, g) => s + g.averageScore) / grouped[b]!.length;
        return isDesc ? avgB.compareTo(avgA) : avgA.compareTo(avgB);
      });
    }

    final isSubjectClass = isTeacher && !_isCurrentClassHomeroom;

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        itemCount: studentIds.length,
        itemBuilder: (context, index) {
          final sId = studentIds[index];
          final studentGrades = grouped[sId]!;
          final studentName = studentGrades.first.studentName;
          final className = studentGrades.first.className;

          final avgGpa = studentGrades.fold<double>(0.0, (sum, g) => sum + g.averageScore) /
              studentGrades.length;

          final isExpanded = _expandedStudentIds.contains(sId);

          return _buildStudentAccordionCard(
            studentId: sId,
            studentName: studentName,
            className: className,
            avgGpa: avgGpa,
            grades: studentGrades,
            isExpanded: isExpanded,
            isSubjectClass: isSubjectClass,
          );
        },
      ),
    );
  }

  // ── Accordion Card for Student (User Requirement) ───────────────────
  Widget _buildStudentAccordionCard({
    required int studentId,
    required String studentName,
    required String className,
    required double avgGpa,
    required List<Grade> grades,
    required bool isExpanded,
    required bool isSubjectClass,
  }) {
    final gpaColor = _getGpaColor(avgGpa);
    final letterGrade = _getLetterGrade(avgGpa);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? gpaColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isExpanded ? gpaColor : Colors.black).withOpacity(isExpanded ? 0.1 : 0.03),
            blurRadius: isExpanded ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Clickable Header (Tap to Expand / Collapse)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isExpanded) {
                    _expandedStudentIds.remove(studentId);
                  } else {
                    _expandedStudentIds.add(studentId);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: gpaColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: gpaColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + Class & Subject count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildPill(className, const Color(0xFF1565C0)),
                              const SizedBox(width: 6),
                              _buildPill(letterGrade, gpaColor),
                              const SizedBox(width: 6),
                              if (!isSubjectClass)
                                Text(
                                  '${grades.length} môn',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // GPA Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: gpaColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            avgGpa.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: gpaColor,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ĐTB',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: gpaColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Expand/Collapse Chevron Icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? gpaColor : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // In Subject Class: Show single subject row directly without deep nesting
            if (isSubjectClass) ...[
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: _buildSubjectRow(grades.first),
              ),
            ],

            // In Homeroom / Multi-Subject: Accordion expansion body
            if (!isSubjectClass && isExpanded) ...[
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Môn học',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _selectedSemester == 'Cả năm' ? 'HK1' : 'CC',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _selectedSemester == 'Cả năm' ? 'HK2' : 'GK',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _selectedSemester == 'Cả năm' ? 'T.Kết' : 'CK',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'TB',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Xếp loại',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Grade Rows
                    ...grades.map((g) => _buildSubjectRow(g)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Subject Grade Row ───────────────────────────────────────────────
  Widget _buildSubjectRow(Grade grade) {
    final avgColor = _getGpaColor(grade.averageScore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.subjectName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  grade.subjectCode,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              grade.attendanceScore.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            child: Text(
              grade.midtermScore.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            child: Text(
              grade.finalScore.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: avgColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                grade.averageScore.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: avgColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                color: avgColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: avgColor.withOpacity(0.2), width: 0.8),
              ),
              child: Text(
                grade.letterGrade,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: avgColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill Helper ─────────────────────────────────────────────────────
  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải bảng điểm',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF1565C0), size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có dữ liệu điểm phù hợp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vui lòng thử chọn học kỳ hoặc lớp khác',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Color based on GPA ──────────────────────────────────────────────
  Color _getGpaColor(double score) {
    if (score >= 9.0) return const Color(0xFF1565C0);
    if (score >= 8.0) return const Color(0xFF059669);
    if (score >= 6.5) return const Color(0xFFD97706);
    if (score >= 5.0) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }
}
