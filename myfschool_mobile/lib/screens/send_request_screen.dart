import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/leave_request_api.dart';
import '../services/user_session.dart';
import 'create_request_screen.dart';

class SendRequestScreen extends StatefulWidget {
  const SendRequestScreen({super.key});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen>
    with SingleTickerProviderStateMixin {
  static const orange = Color(0xFFF26B21);
  static const orangeLight = Color(0xFFFFF3EC);
  static const text = Color(0xFF1C1C1E);
  static const hint = Color(0xFF8E8E93);
  static const bg = Color(0xFFF2F3F5);

  late AnimationController _entryCtrl;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

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
    final userId = UserSession.instance.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await LeaveRequestApi.instance.getRequestsByUser(userId);
    setState(() {
      _requests = data;
      _isLoading = false;
    });
    _entryCtrl.forward(from: 0);
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy - HH:mm').format(date);
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
          'Đơn xin phép',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                );
                _loadRequests();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: orangeLight,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: orange.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_rounded, size: 22, color: orange),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  color: orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_requests[index], index);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, size: 40, color: orange),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có đơn nào',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bấm + để tạo đơn xin phép mới',
            style: TextStyle(fontSize: 13, color: hint),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
              );
              _loadRequests();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [orange, Color(0xFFFF9A50)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Tạo đơn mới',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'Chờ duyệt';
    final requestType = request['requestType'] ?? '';
    final fromDate = _formatDate(request['fromDate']);
    final toDate = _formatDate(request['toDate']);
    final reason = request['reason'] ?? '';
    final createdAt = _formatDateTime(request['createdAt']);

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Đã duyệt':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Từ chối':
        statusColor = const Color(0xFFE53935);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = orange;
        statusIcon = Icons.schedule_rounded;
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
            child: _cardContent(
              requestType,
              fromDate,
              toDate,
              reason,
              createdAt,
              status,
              statusColor,
              statusIcon,
            ),
          ),
        );
      },
    );
  }

  Widget _cardContent(
    String requestType,
    String fromDate,
    String toDate,
    String reason,
    String createdAt,
    String status,
    Color statusColor,
    IconData statusIcon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    requestType.contains('dài')
                        ? Icons.calendar_month_rounded
                        : Icons.event_busy_rounded,
                    size: 17,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requestType,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gửi lúc: $createdAt',
                        style: const TextStyle(fontSize: 10.5, color: hint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _infoChip(Icons.event_outlined, 'Từ ngày', fromDate),
                    const SizedBox(width: 10),
                    _infoChip(Icons.event_outlined, 'Đến ngày', toDate),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lý do:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hint),
                      ),
                      const SizedBox(height: 4),
                      Text(reason, style: const TextStyle(fontSize: 13, color: text, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: orange),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: hint, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
