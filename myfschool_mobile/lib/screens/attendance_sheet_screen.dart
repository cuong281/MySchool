import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfschools/models/attendance_sheet_model.dart';
import 'package:myfschools/services/attendance_api.dart';

class AttendanceSheetScreen extends StatefulWidget {
  final int classId;
  final String? className;
  final int? subjectId;
  final String? subjectName;
  final int slotNumber;
  final String attendanceDate; // yyyy-MM-dd

  const AttendanceSheetScreen({
    super.key,
    required this.classId,
    this.className,
    this.subjectId,
    this.subjectName,
    required this.slotNumber,
    required this.attendanceDate,
  });

  @override
  State<AttendanceSheetScreen> createState() => _AttendanceSheetScreenState();
}

class _AttendanceSheetScreenState extends State<AttendanceSheetScreen> {
  static const _blue = Color(0xFF1A3C6E);
  static const _orange = Color(0xFFF26B21);
  static const _bg = Color(0xFFF0F4F8);
  static const _cardBg = Colors.white;
  static const _border = Color(0xFFE5E7EB);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  AttendanceSheetModel? _sheet;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSheetData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSheetData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await AttendanceApi.instance.getAttendanceSheet(
        widget.classId,
        subjectId: widget.subjectId,
        slotNumber: widget.slotNumber,
        date: widget.attendanceDate,
      );

      if (mounted) {
        setState(() {
          _sheet = data;
          _isLoading = false;
          if (data == null) {
            _errorMessage = 'Không thể tải danh sách điểm danh cho lớp này.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải dữ liệu: $e';
        });
      }
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

  void _markAllPresent() {
    if (_sheet == null || !_sheet!.canEdit) return;

    setState(() {
      for (final student in _sheet!.students) {
        // If student has approved leave, leave them as EXCUSED_ABSENCE unless already overridden
        if (student.hasApprovedLeave && !student.overrideLeave) {
          student.currentStatus = 'EXCUSED_ABSENCE';
        } else {
          student.currentStatus = 'PRESENT';
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đánh dấu Có mặt (giữ nguyên Có phép cho học sinh có đơn)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onStatusSelected(AttendanceSheetStudentModel student, String newStatus) async {
    if (_sheet == null || !_sheet!.canEdit) return;

    if (student.hasApprovedLeave && newStatus != 'EXCUSED_ABSENCE' && !student.overrideLeave) {
      final confirmed = await _showOverrideDialog(student, newStatus);
      if (!confirmed) return;
    }

    setState(() {
      student.currentStatus = newStatus;
    });
  }

  Future<bool> _showOverrideDialog(
    AttendanceSheetStudentModel student,
    String targetStatus,
  ) async {
    final reasonController = TextEditingController();
    String? localError;

    String statusLabel = 'Có mặt';
    if (targetStatus == 'UNEXCUSED_ABSENCE') statusLabel = 'Không phép';
    if (targetStatus == 'LATE') statusLabel = 'Đi muộn';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Xác nhận ghi đè',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Học sinh ${student.studentName} (${student.studentCode}) đã có đơn xin nghỉ phép được phê duyệt.',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    if (student.leaveReason != null && student.leaveReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          'Lý do nghỉ trong đơn: ${student.leaveReason}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Bạn có chắc chắn muốn chuyển thành "$statusLabel"? Vui lòng nhập lý do ghi đè (3 - 150 ký tự):',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLength: 150,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do ghi đè (VD: Học sinh vẫn đến lớp học bù...)',
                        errorText: localError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final text = reasonController.text.trim();
                    if (text.length < 3 || text.length > 150) {
                      setDialogState(() {
                        localError = 'Lý do ghi đè phải từ 3 đến 150 ký tự';
                      });
                      return;
                    }
                    student.overrideLeave = true;
                    student.overrideReason = text;
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Xác nhận ghi đè'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _editStudentNote(AttendanceSheetStudentModel student) async {
    if (_sheet == null || !_sheet!.canEdit) return;

    final noteController = TextEditingController(text: student.note ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Ghi chú cho ${student.studentName}'),
          content: TextField(
            controller: noteController,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú thêm cho học sinh...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                student.note = noteController.text.trim();
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Lưu ghi chú'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      setState(() {});
    }
  }

  Future<void> _saveAttendance() async {
    if (_sheet == null || !_sheet!.canEdit || _isSaving) return;

    // Check if there are unmarked students
    final unmarked = _sheet!.students.where((s) => s.currentStatus == null).length;
    if (unmarked > 0) {
      final cont = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Chưa điểm danh hết'),
          content: Text(
            'Hiện còn $unmarked học sinh chưa được chọn trạng thái điểm danh. Bạn có muốn tiếp tục lưu?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Kiểm tra lại'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Vẫn lưu'),
            ),
          ],
        ),
      );
      if (cont != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    final items = _sheet!.students
        .where((s) => s.currentStatus != null)
        .map((s) => AttendanceBatchItem(
              studentId: s.studentId,
              status: s.currentStatus!,
              note: s.note,
              overrideLeave: s.overrideLeave,
              overrideReason: s.overrideReason,
            ))
        .toList();

    final req = AttendanceBatchRequest(
      classId: _sheet!.classId,
      subjectId: _sheet!.subjectId,
      slotNumber: _sheet!.slotNumber,
      attendanceDate: _sheet!.attendanceDate,
      items: items,
    );

    final res = await AttendanceApi.instance.recordBatchAttendance(req);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Lưu điểm danh thành công!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (res['conflict'] != null) {
      final conflict = res['conflict'] as LeaveConflictError;
      // Show conflict popup and allow teacher to override right here
      final student = _sheet!.students.firstWhere(
        (s) => s.studentId == conflict.studentId,
        orElse: () => _sheet!.students.first,
      );
      await _showOverrideDialog(student, student.currentStatus ?? 'PRESENT');
      // Prompt user to tap save again after override
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật lý do ghi đè. Vui lòng bấm [Lưu điểm danh] lại.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Không thể lưu'),
          content: Text(res['message'] ?? 'Đã xảy ra lỗi khi lưu điểm danh.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          widget.className != null
              ? 'Điểm danh - ${widget.className}'
              : 'Phiếu điểm danh',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_sheet != null && _sheet!.canEdit)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tất cả có mặt',
              onPressed: _markAllPresent,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadSheetData,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _sheet != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _blue),
            SizedBox(height: 16),
            Text('Đang tải danh sách học sinh...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    if (_errorMessage != null || _sheet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Không tìm thấy dữ liệu điểm danh',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                onPressed: _loadSheetData,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredStudents = _sheet!.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return s.studentName.toLowerCase().contains(query) ||
          s.studentCode.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Header summary info card
        _buildHeaderCard(),

        // Lockdown banner if not editable
        if (!_sheet!.canEdit) _buildLockdownBanner(),

        // Search and stats bar
        _buildSearchAndStatsBar(filteredStudents.length),

        // Student list
        Expanded(
          child: filteredStudents.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy học sinh nào',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final student = filteredStudents[index];
                    return _buildStudentCard(student);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final s = _sheet!;
    final timeRange = (s.startTime != null && s.endTime != null)
        ? '${s.startTime} - ${s.endTime}'
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  'Tiết ${s.slotNumber}',
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (timeRange.isNotEmpty)
                Text(
                  timeRange,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              const Spacer(),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDisplayDate(s.attendanceDate),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.subjectName ?? 'Môn học',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lớp: ${s.className}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sĩ số: ${s.totalStudents}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockdownBanner() {
    final s = _sheet!;
    IconData icon = Icons.lock_outline;
    Color bgColor = Colors.amber.shade50;
    Color borderColor = Colors.amber.shade200;
    Color textColor = Colors.amber.shade900;
    String message = 'Buổi học này đang ở chế độ chỉ xem.';

    if (s.lockReason == 'NO_SCHEDULE') {
      icon = Icons.event_busy;
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      textColor = Colors.orange.shade900;
      message = 'Tiết học này không có trong thời khóa biểu của lớp (Chỉ xem).';
    } else if (s.lockReason == 'NOT_STARTED') {
      icon = Icons.schedule;
      message = 'Chưa tới giờ học. Tiết học bắt đầu lúc ${s.startTime ?? ''}. Bạn chưa thể điểm danh.';
    } else if (s.lockReason == 'EXPIRED_PAST_DAY') {
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade800;
      message = 'Tiết học thuộc ngày trong quá khứ đã khóa sổ. Dữ liệu chỉ ở chế độ xem.';
    } else if (s.lockReason == 'FUTURE_DATE') {
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade800;
      message = 'Buổi học ở ngày trong tương lai. Bạn chưa thể điểm danh.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndStatsBar(int matchCount) {
    if (_sheet == null) return const SizedBox.shrink();

    int present = 0;
    int excused = 0;
    int unexcused = 0;
    int late = 0;

    for (final s in _sheet!.students) {
      if (s.currentStatus == 'PRESENT') present++;
      if (s.currentStatus == 'EXCUSED_ABSENCE') excused++;
      if (s.currentStatus == 'UNEXCUSED_ABSENCE') unexcused++;
      if (s.currentStatus == 'LATE') late++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          // Quick stats chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniPill('Có mặt', present, Colors.green),
              _buildMiniPill('Có phép', excused, Colors.blue),
              _buildMiniPill('Không phép', unexcused, Colors.red),
              _buildMiniPill('Đi muộn', late, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          // Search box
          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc mã HS...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _cardBg,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.shade900, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 11, color: color.shade900, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(AttendanceSheetStudentModel student) {
    final canEdit = _sheet?.canEdit ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: student.hasApprovedLeave ? Colors.blue.shade200 : _border,
          width: student.hasApprovedLeave ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Code, Leave Chip, Note Action
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${student.studentCode})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: Icon(
                    student.note != null && student.note!.isNotEmpty
                        ? Icons.comment
                        : Icons.add_comment_outlined,
                    size: 18,
                    color: student.note != null && student.note!.isNotEmpty
                        ? _blue
                        : Colors.grey.shade500,
                  ),
                  tooltip: 'Ghi chú',
                  onPressed: () => _editStudentNote(student),
                ),
            ],
          ),

          // Row 2: Approved leave notice if any
          if (student.hasApprovedLeave) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 12, color: Colors.blue.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'Đơn nghỉ phép #${student.leaveRequestId ?? ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (student.overrideLeave) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Đã ghi đè',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (student.leaveReason != null && student.leaveReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Lý do: ${student.leaveReason}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
              ),
          ],

          if (student.note != null && student.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ghi chú: ${student.note}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],

          const SizedBox(height: 8),

          // Row 3: Status buttons (Có mặt / Có phép / Không phép / Đi muộn)
          Row(
            children: [
              _buildStatusButton(student, 'PRESENT', 'Có mặt', Colors.green, canEdit),
              const SizedBox(width: 6),
              _buildStatusButton(student, 'EXCUSED_ABSENCE', 'Có phép', Colors.blue, canEdit),
              const SizedBox(width: 6),
              _buildStatusButton(student, 'UNEXCUSED_ABSENCE', 'Không phép', Colors.red, canEdit),
              const SizedBox(width: 6),
              _buildStatusButton(student, 'LATE', 'Đi muộn', Colors.orange, canEdit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    AttendanceSheetStudentModel student,
    String statusKey,
    String label,
    MaterialColor color,
    bool canEdit,
  ) {
    final isSelected = student.currentStatus == statusKey;

    return Expanded(
      child: GestureDetector(
        onTap: canEdit ? () => _onStatusSelected(student, statusKey) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color.shade600 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.shade700 : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canEdit = _sheet?.canEdit ?? false;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          border: const Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canEdit ? _blue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: canEdit && !_isSaving ? _saveAttendance : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  canEdit ? 'Lưu điểm danh' : 'Đang ở chế độ xem',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
