import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschools/controllers/GradeController.dart';
import 'package:myfschools/models/grade.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/school_class_api.dart';
import 'package:myfschools/services/user_session.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Grade>> _gradesFuture;
  late AnimationController _animCtrl;
  String _selectedSemester = 'HK1';
  String _searchQuery = '';
  String _sortBy = 'Tên học sinh'; // 'Tên học sinh', 'GPA: Cao - Thấp', 'GPA: Thấp - Cao'
  List<SchoolClassModel> _classes = [];
  int? _selectedClassId;
  String _selectedClassName = 'Tất cả lớp';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  Future<void> _loadInitialData() async {
    final user = UserSession.instance.currentUser;
    if (user?.role == 'Admin') {
      final classes = await SchoolClassApi.instance.getAllClasses();
      setState(() {
        _classes = classes;
      });
    }
    _loadGrades();
  }

  void _loadGrades() {
    final user = UserSession.instance.currentUser;
    if (user == null) return;
    
    if (user == null) return;
    
    if (user.role == 'Admin') {
      if (_selectedClassId == null) {
        _gradesFuture = GradeController.getAllGrades();
      } else {
        _gradesFuture = GradeController.getGradesByClass(_selectedClassId!);
      }
    } else {
      // Dùng ID thật từ UserSession thay vì username
      _gradesFuture = GradeController.getGradesByUser(user.id!);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _loadGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1565C0).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                if (UserSession.instance.currentUser?.role == 'Admin') _buildAdminTools(),
                _buildSemesterFilter(),
                Expanded(
                  child: FutureBuilder<List<Grade>>(
                    future: _gradesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
                      }
                      if (snapshot.hasError) return _buildError(snapshot.error.toString());

                      final grades = snapshot.data ?? [];
                      final filtered = _processGrades(grades);
                      if (filtered.isEmpty) return _buildEmpty();

                      return _buildGradeList(filtered);
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
  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                color: Colors.white.withOpacity(0.15),
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
                  'Bang diem',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ket qua hoc tap',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Admin Tools ──────────────────────────────────────────────────
  Widget _buildAdminTools() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Tìm tên học sinh...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF1565C0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E5EA)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedClassId,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF1A3C6E)),
                hint: Text(_selectedClassName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A3C6E))),
                onChanged: (v) {
                  setState(() {
                    _selectedClassId = v;
                    _selectedClassName = v == null ? 'Tất cả' : (_classes.firstWhere((c) => c.id == v).className);
                    _loadGrades();
                  });
                },
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Tất cả', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  ..._classes.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.className, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              icon: const Icon(Icons.sort_rounded, size: 20, color: Color(0xFF1565C0)),
              onChanged: (v) => setState(() => _sortBy = v!),
              items: ['Tên học sinh', 'GPA: Cao - Thấp', 'GPA: Thấp - Cao']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))))
                  .toList(),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: semesters.map((sem) {
          final isActive = _selectedSemester == sem;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedSemester = sem);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1565C0) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    sem,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF757575),
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

  // ── Helper: Process grades (Filter & Sort) ──────────────────────────
  List<Grade> _processGrades(List<Grade> grades) {
    // 1. Filter by semester or handle 'Cả năm'
    if (_selectedSemester == 'Cả năm') {
      return _calculateAnnualGrades(grades);
    }

    final sem = _selectedSemester == 'HK1' ? 1 : 2;
    var filtered = grades.where((g) => g.semester == sem).toList();

    // 2. Filter by search query (Admin only)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((g) => g.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  List<Grade> _calculateAnnualGrades(List<Grade> allGrades) {
    // Group by student and subject code
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

      // Create a virtual grade object for display
      final base = hasHk2 ? hk2 : hk1;
      annualGrades.add(Grade(
        id: base.id,
        studentId: base.studentId,
        studentName: base.studentName,
        className: base.className,
        subjectCode: base.subjectCode,
        subjectName: base.subjectName,
        semester: 0, // 0 for annual
        attendanceScore: hk1.averageScore, // Repurpose columns for display
        midtermScore: hk2.averageScore,     // Repurpose columns for display
        finalScore: annualScore,
        averageScore: annualScore,
        letterGrade: _getLetterGrade(annualScore),
        academicYear: base.academicYear,
      ));
    });

    // Filter by search query (Admin only)
    if (_searchQuery.isNotEmpty) {
      return annualGrades
          .where((g) => g.studentName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return annualGrades;
  }

  String _getLetterGrade(double score) {
    if (score >= 9.0) return 'Xuat sac';
    if (score >= 8.0) return 'Gioi';
    if (score >= 6.5) return 'Kha';
    if (score >= 5.0) return 'Trung binh';
    return 'Yeu';
  }

  // ── Grade List ──────────────────────────────────────────────────────
  Widget _buildGradeList(List<Grade> grades) {
    // 1. Group
    final Map<int, List<Grade>> grouped = {};
    for (final g in grades) {
      final sId = g.studentId;
      grouped.putIfAbsent(sId, () => []).add(g);
    }

    // 2. Sort Groups
    var studentIds = grouped.keys.toList();
    if (_sortBy == 'Tên học sinh') {
      studentIds.sort((a, b) => grouped[a]!.first.studentName.compareTo(grouped[b]!.first.studentName));
    } else {
      final isDesc = _sortBy == 'GPA: Cao - Thấp';
      studentIds.sort((a, b) {
        final avgA = grouped[a]!.fold<double>(0.0, (s, g) => s + g.averageScore) / grouped[a]!.length;
        final avgB = grouped[b]!.fold<double>(0.0, (s, g) => s + g.averageScore) / grouped[b]!.length;
        return isDesc ? avgB.compareTo(avgA) : avgA.compareTo(avgB);
      });
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: studentIds.length,
        itemBuilder: (context, index) {
          final studentId = studentIds[index];
          final studentGrades = grouped[studentId]!;
          final studentName = studentGrades.first.studentName;
          final className = studentGrades.first.className;

          final avgGpa = studentGrades.fold<double>(0.0, (sum, g) => sum + g.averageScore) / studentGrades.length;

          return AnimatedBuilder(
            animation: _animCtrl,
            builder: (_, __) {
              final delay = (index * 0.1).clamp(0.0, 0.5);
              final t = Curves.easeOutCubic.transform(((_animCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
              return Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: _buildStudentCard(studentId.toString(), studentName, className, avgGpa, studentGrades)),
              );
            },
          );
        },
      ),
    );
  }

  // ── Student Card ────────────────────────────────────────────────────
  Widget _buildStudentCard(
    String studentId,
    String studentName,
    String className,
    double avgGpa,
    List<Grade> grades,
  ) {
    final gpaColor = _getGpaColor(avgGpa);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gpaColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Student Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gpaColor.withOpacity(0.08), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gpaColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_rounded, color: gpaColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _buildTag(studentId, const Color(0xFF1565C0)),
                          const SizedBox(width: 6),
                          _buildTag(className, const Color(0xFF2E7D32)),
                        ],
                      ),
                    ],
                  ),
                ),
                // GPA Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: gpaColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gpaColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        avgGpa.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TB',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grades Table
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('Mon hoc',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                      Expanded(
                          child: Text(_selectedSemester == 'Cả năm' ? 'HK1' : 'CC',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                      Expanded(
                          child: Text(_selectedSemester == 'Cả năm' ? 'HK2' : 'GK',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                      Expanded(
                          child: Text(_selectedSemester == 'Cả năm' ? 'T.Kết' : 'CK',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                      Expanded(
                          child: Text('TB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                      const Expanded(
                          flex: 2,
                          child: Text('Xep loai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF757575)))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Grade Rows
                ...grades.map((g) => _buildGradeRow(g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grade Row ───────────────────────────────────────────────────────
  Widget _buildGradeRow(Grade grade) {
    final avgColor = _getGpaColor(grade.averageScore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE0E0E0).withOpacity(0.5),
            width: 0.5,
          ),
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
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  grade.subjectCode,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Expanded(
            child: Text(
              grade.midtermScore.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Expanded(
            child: Text(
              grade.finalScore.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: avgColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                grade.averageScore.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: avgColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              decoration: BoxDecoration(
                color: avgColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: avgColor.withOpacity(0.3), width: 1),
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

  // ── Tag Widget ──────────────────────────────────────────────────────
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFE53935), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Khong the ket noi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thu lai'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.school_rounded,
                color: Color(0xFF1565C0), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chua co du lieu diem',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diem se duoc cap nhat sau',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: GPA color ───────────────────────────────────────────────
  Color _getGpaColor(double score) {
    if (score >= 9.0) return const Color(0xFF1565C0);
    if (score >= 8.0) return const Color(0xFF2E7D32);
    if (score >= 6.5) return const Color(0xFFEF6C00);
    if (score >= 5.0) return const Color(0xFFFF8F00);
    return const Color(0xFFE53935);
  }
}
