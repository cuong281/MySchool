import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/leave_request_api.dart';
import '../services/user_session.dart';

class AdminRequestListScreen extends StatefulWidget {
  const AdminRequestListScreen({super.key});

  @override
  State<AdminRequestListScreen> createState() => _AdminRequestListScreenState();
}

class _AdminRequestListScreenState extends State<AdminRequestListScreen>
    with SingleTickerProviderStateMixin {
  static const orange = Color(0xFFF26B21);
  static const orangeLight = Color(0xFFFFF3EC);
  static const text = Color(0xFF1C1C1E);
  static const hint = Color(0xFF8E8E93);
  static const bg = Color(0xFFF2F3F5);

  late AnimationController _entryCtrl;
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tất cả'; // Tất cả, Chờ duyệt, Đã duyệt, Từ chối

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadRequests();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final data = await LeaveRequestApi.instance.getAllRequests();
    _allRequests = data;
    _applyFilter();
    setState(() {
      _isLoading = false;
    });
    _entryCtrl.forward(from: 0);
  }

  void _applyFilter() {
    setState(() {
      if (_selectedStatus == 'Tất cả') {
        _filteredRequests = List.from(_allRequests);
      } else {
        _filteredRequests = _allRequests.where((r) {
          final s = r['status'] ?? 'Chờ duyệt';
          return s == _selectedStatus;
        }).toList();
      }
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    HapticFeedback.mediumImpact();
    final user = UserSession.instance.currentUser;
    if (user == null || user.id == null) return;

    final success =
        await LeaveRequestApi.instance.updateStatus(id, status, user.id!);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái đơn: $status'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi cập nhật trạng thái'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quản lý đơn xin phép',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: orange))
                : _filteredRequests.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có đơn nào phù hợp',
                          style: TextStyle(color: hint),
                        ),
                      )
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
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusList = ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Từ chối'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 12),
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
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? orange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
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

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final id =
        (request['id'] ?? request['requestId'] ?? request['requestID'] ?? 0)
            as int;
    final status = request['status'] ?? 'Chờ duyệt';
    final requestType = request['requestType'] ?? '';
    final studentCode = (request['studentCode'] ?? '').toString();
    final studentName = (request['studentName'] ?? '').toString();
    final fromDate = _formatDate(request['fromDate']);
    final toDate = _formatDate(request['toDate']);
    final reason = request['reason'] ?? '';

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
              child: Column(
                children: [
                  Padding(
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
                                color: orangeLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'STUDENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                studentCode.isNotEmpty
                                    ? 'MSHS: $studentCode'
                                    : studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
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
                        if (studentName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          requestType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$fromDate -> $toDate',
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
                            reason,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'Chờ duyệt')
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: bg, width: 1.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _updateStatus(id, 'Từ chối'),
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
                              onPressed: () => _updateStatus(id, 'Đã duyệt'),
                              child: const Text(
                                'Đồng ý',
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
        );
      },
    );
  }
}
