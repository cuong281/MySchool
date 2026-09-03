import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/leave_request_api.dart';
import '../services/user_session.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen>
    with SingleTickerProviderStateMixin {
  int _selectedType = 0;
  late AnimationController _entryCtrl;
  final TextEditingController _reasonController = TextEditingController();

  DateTime _fromDate = DateTime.now().add(const Duration(days: 1));
  DateTime _toDate = DateTime.now().add(const Duration(days: 1));

  static const _orange = Color(0xFFF26B21);
  static const _orangeLight = Color(0xFFFFF3EC);
  static const _text = Color(0xFF1C1C1E);
  static const _hint = Color(0xFF8E8E93);
  static const _bg = Color(0xFFF2F3F5);
  static const _white = Colors.white;
  static const _divider = Color(0xFFE6E6E6);

  final List<_RequestType> _types = const [
    _RequestType(
      icon: Icons.event_busy_rounded,
      title: 'Xin nghỉ học',
      subtitle: 'Nghỉ trong ngày',
    ),
    _RequestType(
      icon: Icons.calendar_month_rounded,
      title: 'Xin nghỉ học dài ngày',
      subtitle: 'Nghỉ nhiều ngày',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month, now.day);
    final initial = isFrom ? _fromDate : _toDate;
    final safeInitial = initial.isBefore(earliest) ? earliest : initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: earliest,
      lastDate: DateTime(now.year + 1, 12, 31),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_selectedType == 0) {
            _toDate = picked;
          }
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          if (picked.isBefore(_fromDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ngày kết thúc không được trước ngày bắt đầu'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            _toDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    HapticFeedback.mediumImpact();

    final reason = _reasonController.text.trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_fromDate.isBefore(today)) {
      _showError('Ngày bắt đầu không được trước ngày hôm nay');
      return;
    }

    if (_toDate.isBefore(_fromDate)) {
      _showError('Ngày kết thúc không được trước ngày bắt đầu');
      return;
    }

    if (reason.isEmpty) {
      _showError('Vui lòng nhập lý do nghỉ học');
      return;
    }

    if (reason.length < 10) {
      _showError('Lý do phải có ít nhất 10 ký tự');
      return;
    }

    final userId = UserSession.instance.currentUser?.id;
    if (userId == null) {
      _showError('Chưa đăng nhập, vui lòng đăng nhập lại');
      return;
    }

    final errorMsg = await LeaveRequestApi.instance.createRequest(
      userId: userId,
      requestType: _types[_selectedType].title,
      fromDate: _fromDate,
      toDate: _toDate,
      reason: reason,
    );

    if (errorMsg != null) {
      _showError(errorMsg);
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 40, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi đơn thành công!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _text),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn ${_types[_selectedType].title.toLowerCase()} đã được gửi và đang chờ duyệt.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _hint, height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      _animEntry(0.0, _buildSemesterBanner()),
                      const SizedBox(height: 16),
                      _animEntry(0.08, _buildSectionLabel('Loại đơn')),
                      const SizedBox(height: 10),
                      _animEntry(0.1, _buildTypeSelector()),
                      const SizedBox(height: 20),
                      _animEntry(0.18, _buildSectionLabel('Thời gian')),
                      const SizedBox(height: 10),
                      _animEntry(0.2, _buildDateRow()),
                      const SizedBox(height: 20),
                      _animEntry(0.28, _buildSectionLabel('Lý do')),
                      const SizedBox(height: 10),
                      _animEntry(0.3, _buildReasonBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomButtons(),
          ),
        ],
      ),
    );
  }

  Widget _animEntry(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(
          ((_entryCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: _text),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tạo đơn',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _text, letterSpacing: 0.2),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _orange.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_edu_rounded, size: 14, color: _orange),
                  SizedBox(width: 5),
                  Text('Lịch sử', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_orange, Color(0xFFFF9A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _orange.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Học kỳ hiện tại',
                style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2),
              Text(
                'Kỳ 2  -  2025 / 2026',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Đang học',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_orange, Color(0xFFFF9A50)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _text, letterSpacing: 0.2),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: List.generate(_types.length, (i) {
        final t = _types[i];
        final sel = _selectedType == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _types.length - 1 ? 10 : 0),
            child: _TypeCard(
              type: t,
              selected: sel,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedType = i;
                  if (i == 0) {
                    _toDate = _fromDate;
                  }
                });
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateRow() {
    final bool isSingleDay = _selectedType == 0;
    return Row(
      children: [
        Expanded(
          child: _DateBox(
            label: 'Từ ngày',
            value: _formatDate(_fromDate),
            onTap: () => _pickDate(isFrom: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Expanded(
          child: _DateBox(
            label: 'Đến ngày',
            value: _formatDate(_toDate),
            onTap: isSingleDay ? null : () => _pickDate(isFrom: false),
            enabled: !isSingleDay,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonBox() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orange.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: _orange.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _orangeLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: _orange.withOpacity(0.15))),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: _orange),
                SizedBox(width: 6),
                Text('Nội dung đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _orange)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _text, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Nhập lý do nghỉ học...',
                hintStyle: TextStyle(fontSize: 13, color: _hint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Icon(
                  _reasonController.text.length >= 10
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 12,
                  color: _reasonController.text.length >= 10
                      ? const Color(0xFF4CAF50)
                      : _hint,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_reasonController.text.length} / 10 ký tự tối thiểu',
                  style: TextStyle(
                    fontSize: 11,
                    color: _reasonController.text.length >= 10
                        ? const Color(0xFF4CAF50)
                        : _hint.withOpacity(0.8),
                    fontWeight: _reasonController.text.length >= 10
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, -4)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedType = 0;
                _fromDate = DateTime.now().add(const Duration(days: 1));
                _toDate = DateTime.now().add(const Duration(days: 1));
                _reasonController.clear();
              });
            },
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider),
              ),
              child: const Icon(Icons.refresh_rounded, size: 22, color: _hint),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _submitRequest,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_orange, Color(0xFFFF9A50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _orange.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Gửi đơn',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
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
}

class _RequestType {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RequestType({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _TypeCard extends StatelessWidget {
  final _RequestType type;
  final bool selected;
  final VoidCallback onTap;

  static const _orange = Color(0xFFF26B21);
  static const _orangeLight = Color(0xFFFFF3EC);
  static const _text = Color(0xFF1C1C1E);
  static const _hint = Color(0xFF8E8E93);
  static const _divider = Color(0xFFE6E6E6);

  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _orangeLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _orange : _divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _orange.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? _orange : const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(type.icon, size: 18, color: selected ? Colors.white : _hint),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _orange : Colors.transparent,
                    border: Border.all(
                      color: selected ? _orange : const Color(0xFFCFCFD4),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              type.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _orange : _text,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(type.subtitle, style: const TextStyle(fontSize: 10.5, color: _hint)),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  static const _orange = Color(0xFFF26B21);
  static const _orangeLight = Color(0xFFFFF3EC);
  static const _text = Color(0xFF1C1C1E);

  const _DateBox({
    required this.label,
    required this.value,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (enabled && onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 6),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _orange.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _orange.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _text),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _orangeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.expand_more_rounded, size: 16, color: _orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
