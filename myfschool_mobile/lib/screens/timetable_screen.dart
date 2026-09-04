import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfschools/models/schedule_model.dart';
import 'package:myfschools/models/school_class_model.dart';
import 'package:myfschools/services/schedule_api.dart';
import 'package:myfschools/services/school_class_api.dart';
import 'package:myfschools/services/user_session.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const _orange = Color(0xFFF26B21);
  static const _blue = Color(0xFF1A3C6E);
  static const _border = Color(0xFFE5E7EB);
  static const _bg = Color(0xFFF0F4F8);

  late DateTime currentWeekStart;
  late DateTime selectedDate;
  bool isLoading = false;
  List<ScheduleDayModel> weeklySchedule = [];
  List<SchoolClassModel> _classes = [];
  int? _selectedClassId; // null = My Schedule (Teacher/Student)
  String _selectedLabel = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    selectedDate = now;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = UserSession.instance.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isTeacher = user?.isTeacher ?? false;

    if (isAdmin || isTeacher) {
      final classes = await SchoolClassApi.instance.getAllClasses();
      if (mounted) {
        setState(() {
          _classes = classes;
          if (isAdmin && _classes.isNotEmpty) {
            _selectedClassId = _classes.first.id;
            _selectedLabel = 'Lớp ${_classes.first.className}';
          } else if (isTeacher) {
            _selectedClassId = null;
            _selectedLabel = 'Lịch dạy của tôi';
          }
        });
      }
    }
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    List<ScheduleDayModel> data;
    if (_selectedClassId != null) {
      data = await ScheduleApi.instance.getScheduleByClass(_selectedClassId!);
    } else {
      data = await ScheduleApi.instance.getMySchedule();
    }

    if (mounted) {
      setState(() {
        weeklySchedule = data;
        isLoading = false;
      });
    }
  }

  void _previousWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      selectedDate = currentWeekStart;
    });
  }

  void _nextWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      selectedDate = currentWeekStart;
    });
  }

  List<DateTime> _getCurrentWeekDates() =>
      List.generate(7, (i) => currentWeekStart.add(Duration(days: i)));

  String _getBackendDayString(int weekday) {
    const days = [
      'ALL_ZERO',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return days[weekday];
  }

  List<SchedulePeriodModel> _getPeriodsForDate(DateTime date) {
    final backendDayStr = _getBackendDayString(date.weekday);
    final dayData = weeklySchedule.firstWhere(
      (day) => day.dayOfWeek == backendDayStr,
      orElse: () => ScheduleDayModel(dayOfWeek: '', periods: []),
    );
    return dayData.periods;
  }

  String _getHeaderTitle() {
    final user = UserSession.instance.currentUser;
    if (user?.isAdmin ?? false) {
      return 'Lịch học các lớp';
    }
    if (user?.isTeacher ?? false) {
      return _selectedClassId == null ? 'Lịch giảng dạy' : 'Thời khóa biểu';
    }
    return 'Lịch học';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekBar(),
          _buildDaySelector(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = UserSession.instance.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isTeacher = user?.isTeacher ?? false;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE85D04), Color(0xFFF26B21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getHeaderTitle(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if ((isAdmin || isTeacher) && _classes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildRoleDropdown(isAdmin, isTeacher),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('dd/MM').format(currentWeekStart)} - ${DateFormat('dd/MM/yyyy').format(currentWeekStart.add(const Duration(days: 6)))}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderButtonSmall(
                text: 'Hôm nay',
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
                    selectedDate = now;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(bool isAdmin, bool isTeacher) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int?>(
        value: _selectedClassId,
        dropdownColor: const Color(0xFFE85D04),
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
        hint: Text(
          _selectedLabel.isNotEmpty ? _selectedLabel : 'Chọn lớp',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onChanged: (v) {
          setState(() {
            _selectedClassId = v;
            if (v == null) {
              _selectedLabel = 'Lịch dạy của tôi';
            } else {
              final found = _classes.where((c) => c.id == v);
              _selectedLabel = found.isNotEmpty ? 'Lớp ${found.first.className}' : 'Lớp';
            }
            _fetchSchedule();
          });
        },
        items: [
          if (isTeacher)
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'Lịch dạy của tôi',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ..._classes.map((c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(
                  'Lớp ${c.className}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousWeek,
            icon: const Icon(Icons.chevron_left_rounded, color: _blue),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(currentWeekStart),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextWeek,
            icon: const Icon(Icons.chevron_right_rounded, color: _blue),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final weekDates = _getCurrentWeekDates();
    final today = DateTime.now();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDates.map((date) {
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          final hasSlots = _getPeriodsForDate(date).isNotEmpty;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? _blue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 2),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? _orange
                              : Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: hasSlots ? 5 : 0,
                    height: hasSlots ? 5 : 0,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _orange),
            SizedBox(height: 12),
            Text(
              'Đang tải lịch...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final periods = _getPeriodsForDate(selectedDate);
    if (periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: _orange, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có tiết học trong ngày này',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chọn các ngày từ Thứ 2 đến Thứ 6 để xem lịch',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final period = periods[index];
        final hasClass = period.className != null && period.className!.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tiết ${period.slotNumber}',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period.startTime.length >= 5 ? period.startTime.substring(0, 5) : period.startTime,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      period.endTime.length >= 5 ? period.endTime.substring(0, 5) : period.endTime,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      children: [
                        Expanded(
                          child: Text(
                            period.subjectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _blue,
                            ),
                          ),
                        ),
                        if (hasClass)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Lớp ${period.className}',
                              style: const TextStyle(
                                color: Color(0xFF3730A3),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (period.teacherName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 15, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              period.teacherName,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    if (period.roomName != null && period.roomName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 15, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            period.roomName!,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderButtonSmall extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _HeaderButtonSmall({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
