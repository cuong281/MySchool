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
  int? _selectedClassId;
  String _selectedClassName = 'Chọn lớp';

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
    if (user?.role == 'Admin') {
      final classes = await SchoolClassApi.instance.getAllClasses();
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first.id;
          _selectedClassName = _classes.first.className;
        }
      });
    }
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => isLoading = true);

    final user = UserSession.instance.currentUser;
    final userId = user?.id?.toString() ?? '1';
    
    List<ScheduleDayModel> data;
    if (user?.role == 'Admin' && _selectedClassId != null) {
      data = await ScheduleApi.instance.getScheduleByClass(_selectedClassId!);
    } else {
      data = await ScheduleApi.instance.getStudentSchedule(userId);
    }

    setState(() {
      weeklySchedule = data;
      isLoading = false;
    });
  }

  void _previousWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      selectedDate = currentWeekStart;
      _fetchSchedule();
    });
  }

  void _nextWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      selectedDate = currentWeekStart;
      _fetchSchedule();
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
                        const Text(
                          'Lịch học',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (UserSession.instance.currentUser?.role == 'Admin') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<int?>(
                              value: _selectedClassId,
                              dropdownColor: const Color(0xFFF26B21),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
                              hint: Text(_selectedClassName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                              onChanged: (v) {
                                setState(() {
                                  _selectedClassId = v;
                                  _selectedClassName = _classes.firstWhere((c) => c.id == v).className;
                                  _fetchSchedule();
                                });
                              },
                              items: _classes.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.className, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                              )).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
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

  // Moved _HeaderButtonSmall to the end of file

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
            Text('Đang tải lịch học...'),
          ],
        ),
      );
    }

    final periods = _getPeriodsForDate(selectedDate);
    if (periods.isEmpty) {
      return const Center(
        child: Text(
          'Không có lịch học',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final period = periods[index];
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
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      period.startTime.substring(0, 5),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      period.endTime.substring(0, 5),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.subjectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 15, color: Colors.grey),
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
