import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/leave_request_api.dart';
import '../services/user_session.dart';
import 'create_request_screen.dart';

class AdminRequestListScreen extends StatefulWidget {
  const AdminRequestListScreen({super.key});

  @override
  State<AdminRequestListScreen> createState() => _AdminRequestListScreenState();
}

class _AdminRequestListScreenState extends State<AdminRequestListScreen>
    with TickerProviderStateMixin {
  static const orange = Color(0xFFF26B21);
  static const orangeLight = Color(0xFFFFF3EC);
  static const text = Color(0xFF1C1C1E);
  static const hint = Color(0xFF8E8E93);
  static const bg = Color(0xFFF2F3F5);

  late AnimationController _entryCtrl;
  late TabController _tabController;
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  List<Map<String, dynamic>> _myRequests = [];
  bool _isLoading = true;

  // Filters
  String _selectedStatus = 'Tất cả'; // Tất cả, Chờ duyệt, Đã duyệt, Từ chối

  bool get _isTeacher => UserSession.instance.currentUser?.isTeacher ?? true;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadRequests();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final data = await LeaveRequestApi.instance.getAllRequests();
    _allRequests = data;
    _applyFilter();
    final myData = await LeaveRequestApi.instance.getMyRequests();
    _myRequests = myData;
    setState(() {
      _isLoading = false;
    });
    _entryCtrl.forward(from: 0);
  }

  void _applyFilter() {
    setState(() {
      _filteredRequests = _allRequests.where((r) {
        if (_selectedStatus != 'Tất cả') {
          final s = r['status'] ?? 'Chờ duyệt';
          if (s != _selectedStatus) return false;
        }
        return true;
      }).toList();
    });
  }

  bool _canProcessRequest(Map<String, dynamic> request) {
    final isTeacherReq = request['role'] == 'TEACHER' || request['teacherId'] != null;
    // Homeroom teacher processes student leave requests
    return !isTeacherReq;
  }

  Future<void> _updateStatus(int id, String status, [String? note]) async {
    HapticFeedback.mediumImpact();
    final success = await LeaveRequestApi.instance.updateStatus(id, status, note);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Đã duyệt'
                ? 'Đã duyệt đơn xin phép thành công'
                : 'Đã từ chối đơn xin phép',
          ),
          backgroundColor:
              status == 'Đã duyệt' ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi cập nhật trạng thái đơn'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(int id) async {
    final noteCtrl = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Từ chối đơn xin phép',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vui lòng nhập ghi chú / lý do từ chối (bắt buộc):',
                style: TextStyle(fontSize: 13, color: text),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do từ chối...',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: hint)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final trimmed = noteCtrl.text.trim();
                if (trimmed.isEmpty) {
                  setDialogState(
                    () => errorText = 'Vui lòng nhập lý do từ chối (không được để trống)',
                  );
                  return;
                }
                Navigator.pop(ctx);
                _updateStatus(id, 'Từ chối', trimmed);
              },
              child: const Text('Từ chối'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(int id, String name) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Duyệt đơn xin phép',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          name.isNotEmpty
              ? 'Bạn có chắc chắn muốn duyệt đơn xin phép của $name?'
              : 'Bạn có chắc chắn muốn duyệt đơn xin phép này?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: hint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(id, 'Đã duyệt');
            },
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> request) {
    final id =
        (request['id'] ?? request['requestId'] ?? request['requestID'] ?? 0) as int;
    final status = request['status'] ?? 'Chờ duyệt';
    final requestType = request['requestType'] ?? '';
    final studentCode = (request['studentCode'] ?? '').toString();
    final studentName = (request['studentName'] ?? '').toString();
    final className = (request['className'] ?? '').toString();
    final fromDate = _formatDate(request['fromDate']);
    final toDate = _toDateFormatted(request['toDate']);
    final reason = request['reason'] ?? '';
    final adminNote = (request['adminNote'] ?? '').toString();
    final canProcess = _canProcessRequest(request) && status == 'Chờ duyệt';
    final isTeacherReq = request['role'] == 'TEACHER' || request['teacherId'] != null;
    final displayName = isTeacherReq
        ? (request['teacherName'] ?? request['studentName'] ?? '').toString()
        : studentName;

    Color statusColor;
    switch (status) {
      case 'Đã duyệt':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Từ chối':
        statusColor = const Color(0xFFE53935);
        break;
      default:
        statusColor = orange;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chi tiết đơn xin nghỉ',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: text,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Đối tượng', isTeacherReq ? 'Giáo viên (TEACHER)' : 'Học sinh (STUDENT)'),
            if (!isTeacherReq && className.isNotEmpty) _buildDetailRow('Lớp', className),
            if (!isTeacherReq && studentCode.isNotEmpty) _buildDetailRow('Mã số (MSHS)', studentCode),
            if (displayName.isNotEmpty) _buildDetailRow('Họ và tên', displayName),
            _buildDetailRow('Loại đơn', requestType),
            _buildDetailRow('Thời gian nghỉ', '$fromDate → $toDate'),
            _buildDetailRow('Lý do', reason),
            if (adminNote.isNotEmpty) _buildDetailRow('Ghi chú xử lý', adminNote),
            const SizedBox(height: 20),
            if (canProcess)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(color: Color(0xFFE53935)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRejectDialog(id);
                      },
                      child: const Text(
                        'Từ chối',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showApproveDialog(id, displayName);
                      },
                      child: const Text(
                        'Duyệt',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: hint, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _toDateFormatted(String? dateStr) {
    return _formatDate(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quản lý đơn',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: orange,
          unselectedLabelColor: hint,
          indicatorColor: orange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Duyệt đơn'),
            Tab(text: 'Đơn của tôi'),
          ],
        ),
      ),
      floatingActionButton: (_tabController.index == 1)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                );
                _loadRequests();
              },
              backgroundColor: orange,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tạo đơn',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentReviewTab(),
          _buildMyRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildStudentReviewTab() {
    return Column(
      children: [
        _buildStatusFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: orange))
              : _filteredRequests.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      color: orange,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(_filteredRequests[index], index);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMyRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: orange));
    }
    if (_myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: orangeLight, shape: BoxShape.circle),
                child: const Icon(Icons.edit_calendar_rounded, size: 36, color: orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa có đơn xin nghỉ nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bấm "Tạo đơn mới" để gửi đơn xin nghỉ phép lên Ban giám hiệu',
                style: TextStyle(fontSize: 13, color: hint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                  );
                  _loadRequests();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Tạo đơn mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: orange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final req = _myRequests[index];
          return _buildMyRequestCard(req, index);
        },
      ),
    );
  }

  Widget _buildMyRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'Chờ duyệt';
    final requestType = request['requestType'] ?? 'Xin nghỉ phép';
    final fromDate = _formatDate(request['fromDate']);
    final toDate = _toDateFormatted(request['toDate']);
    final reason = request['reason'] ?? '';
    final adminNote = (request['adminNote'] ?? '').toString();

    Color statusColor;
    switch (status) {
      case 'Đã duyệt':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Từ chối':
        statusColor = const Color(0xFFE53935);
        break;
      default:
        statusColor = orange;
    }

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) {
        final delay = (index * 0.08).clamp(0.0, 0.5);
        final t = Curves.easeOutCubic.transform(
          ((_entryCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showDetailSheet(request),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ĐƠN CỦA TÔI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          requestType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$fromDate → $toDate',
                          style: const TextStyle(color: hint, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lý do: $reason',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                        if (adminNote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: status == 'Từ chối'
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Phản hồi từ BGH: $adminNote',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: status == 'Từ chối'
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterBar() {
    final statusList = ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Từ chối'];
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusList.length,
        itemBuilder: (context, index) {
          final s = statusList[index];
          final isSelected = _selectedStatus == s;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = s;
                _applyFilter();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? orange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  s,
                  style: TextStyle(
                    color: isSelected ? Colors.white : text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        'Chưa có đơn nào phù hợp',
        style: TextStyle(color: hint),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final id =
        (request['id'] ?? request['requestId'] ?? request['requestID'] ?? 0) as int;
    final status = request['status'] ?? 'Chờ duyệt';
    final requestType = request['requestType'] ?? '';
    final studentCode = (request['studentCode'] ?? '').toString();
    final studentName = (request['studentName'] ?? '').toString();
    final className = (request['className'] ?? '').toString();
    final fromDate = _formatDate(request['fromDate']);
    final toDate = _toDateFormatted(request['toDate']);
    final reason = request['reason'] ?? '';
    final adminNote = (request['adminNote'] ?? '').toString();
    final canProcess = _canProcessRequest(request);

    Color statusColor;
    switch (status) {
      case 'Đã duyệt':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Từ chối':
        statusColor = const Color(0xFFE53935);
        break;
      default:
        statusColor = orange;
    }

    // Build top line: STUDENT · 10A1 · MSHS: HS2025001 or TEACHER · Giáo viên
    final isTeacherReq = request['role'] == 'TEACHER' || request['teacherId'] != null;
    final roleTag = isTeacherReq ? 'TEACHER' : 'STUDENT';
    final roleBgColor = isTeacherReq ? const Color(0xFFE0F2FE) : orangeLight;
    final roleTextColor = isTeacherReq ? const Color(0xFF0284C7) : orange;
    final displayName = isTeacherReq
        ? (request['teacherName'] ?? request['studentName'] ?? '').toString()
        : studentName;
    final codePart = studentCode.isNotEmpty ? 'MSHS: $studentCode' : '';
    final classPart = className.isNotEmpty ? className : '';
    final subInfo = isTeacherReq
        ? 'Giáo viên'
        : [
            if (classPart.isNotEmpty) classPart,
            if (codePart.isNotEmpty) codePart,
          ].join(' · ');

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, __) {
        final delay = (index * 0.08).clamp(0.0, 0.5);
        final t = Curves.easeOutCubic.transform(
          ((_entryCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showDetailSheet(request),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Tag & Status Row: STUDENT · 10A1 · MSHS: HS2025001 or TEACHER · Giáo viên
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    roleTag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: roleTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subInfo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),

                            // 2. Name
                            if (displayName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],

                            // 3. Request Type & Date
                            const SizedBox(height: 6),
                            Text(
                              requestType.isNotEmpty
                                  ? requestType
                                  : (isTeacherReq ? 'Xin nghỉ phép' : 'Xin nghỉ học'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$fromDate → $toDate',
                              style: const TextStyle(color: hint, fontSize: 13),
                            ),

                            // 4. Reason
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Lý do: $reason',
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),

                            // 5. Admin Note if present
                            if (adminNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: status == 'Từ chối'
                                      ? const Color(0xFFFFEBEE)
                                      : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Ghi chú: $adminNote',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: status == 'Từ chối'
                                        ? const Color(0xFFC62828)
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Action Buttons: Only show for pending requests with process permission
                      if (status == 'Chờ duyệt' && canProcess)
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: bg, width: 1.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _showRejectDialog(id),
                                  child: const Text(
                                    'Từ chối',
                                    style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Container(width: 1.5, height: 40, color: bg),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _showApproveDialog(id, displayName),
                                  child: const Text(
                                    'Duyệt',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
