import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<ConversationItem> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final list = await MessageService.instance.getConversations();
    if (mounted) {
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('dd/MM').format(dt);
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('admin') || r.contains('quản trị')) return const Color(0xFF7C3AED);
    if (r.contains('giáo viên') || r.contains('teacher')) return const Color(0xFFF26B21);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.targetName.toLowerCase().contains(_searchQuery) ||
          c.targetRole.toLowerCase().contains(_searchQuery) ||
          c.lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF26B21), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFF26B21),
              onRefresh: _loadConversations,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26B21)))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: filtered.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 76, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final convo = filtered[index];
                            return _buildConversationTile(convo);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, size: 48, color: Color(0xFFF26B21)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hộp thư tin nhắn trống',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn có thể vào mục "Danh bạ" để tìm giáo viên hoặc đồng nghiệp và bắt đầu trò chuyện.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ConversationItem convo) {
    final hasUnread = convo.unreadCount > 0;
    final roleColor = _getRoleColor(convo.targetRole);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFF2EB),
            child: convo.targetAvatar.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(convo.targetAvatar, fit: BoxFit.cover),
                  )
                : Text(
                    convo.targetName.isNotEmpty ? convo.targetName.trim()[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Color(0xFFF26B21), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              convo.targetName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              convo.targetRole,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                convo.lastMessage.isNotEmpty ? convo.lastMessage : '(Tin nhắn trống)',
                style: TextStyle(
                  color: hasUnread ? Colors.black87 : Colors.grey[600],
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(convo.lastMessageTime),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? const Color(0xFFF26B21) : Colors.grey[400],
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF26B21),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${convo.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              targetUserId: convo.targetUserId,
              targetName: convo.targetName,
              targetRole: convo.targetRole,
              targetAvatar: convo.targetAvatar,
            ),
          ),
        );
        _loadConversations();
      },
    );
  }
}
