import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../services/user_session.dart';
import '../untils/app_color.dart';
import 'contact_detail_screen.dart';
import 'chat_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _allTeachers = [];
  List<Contact> _schoolInfo = [];
  bool _isLoading = true;

  // Teacher phone privacy toggle state
  bool _myPhonePublic = false;
  bool _isUpdatingPrivacy = false;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubject = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = UserSession.instance.currentUser;
    final teachers = await ContactService.instance.getTeachers();

    // Group teachers by ID to avoid duplicate cards for multi-subject assignments
    final Map<String, Contact> groupedMap = {};
    for (var teacher in teachers) {
      if (groupedMap.containsKey(teacher.id)) {
        final existing = groupedMap[teacher.id]!;
        final isHm = existing.isHomeroom || teacher.isHomeroom;
        final mergedSubject = (existing.subject.isNotEmpty && teacher.subject.isNotEmpty && !existing.subject.contains(teacher.subject))
            ? '${existing.subject}, ${teacher.subject}'
            : (existing.subject.isNotEmpty ? existing.subject : teacher.subject);
        groupedMap[teacher.id] = Contact(
          id: existing.id,
          userId: existing.userId ?? teacher.userId,
          name: existing.name,
          email: existing.email.isNotEmpty ? existing.email : teacher.email,
          phoneNumber: existing.phoneNumber.isNotEmpty ? existing.phoneNumber : teacher.phoneNumber,
          role: isHm ? 'GV Chủ nhiệm' : (existing.role.isNotEmpty ? existing.role : teacher.role),
          subject: mergedSubject,
          avatarUrl: existing.avatarUrl.isNotEmpty ? existing.avatarUrl : teacher.avatarUrl,
          isTeacher: true,
          isHomeroom: isHm,
          isPhonePublic: existing.isPhonePublic || teacher.isPhonePublic,
          status: existing.status,
        );
      } else {
        groupedMap[teacher.id] = teacher;
      }
    }

    final schoolInfo = await ContactService.instance.getSchoolInfo();

    // Find logged in teacher's current phone privacy setting
    if (user != null && user.isTeacher) {
      final currentTeacherId = user.teacherId?.toString();
      final myRecord = teachers.firstWhere(
        (t) => t.id == currentTeacherId,
        orElse: () => Contact(id: '', name: '', email: '', role: '', isPhonePublic: false),
      );
      _myPhonePublic = myRecord.isPhonePublic;
    }

    if (mounted) {
      setState(() {
        _allTeachers = groupedMap.values.toList();
        _schoolInfo = schoolInfo;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePhonePrivacy(bool value) async {
    setState(() => _isUpdatingPrivacy = true);
    final success = await ContactService.instance.updatePhonePrivacy(value);
    if (mounted) {
      setState(() {
        _isUpdatingPrivacy = false;
        if (success) {
          _myPhonePublic = value;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                value ? Icons.check_circle : Icons.visibility_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value
                      ? 'Đã bật: Học sinh có thể xem số điện thoại của bạn.'
                      : 'Đã tắt: Số điện thoại của bạn hiện được ẩn đối với học sinh.',
                ),
              ),
            ],
          ),
          backgroundColor: value ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMessageDialog(Contact contact) {
    if (contact.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            targetUserId: contact.userId!,
            targetName: contact.name,
            targetRole: contact.role,
            targetAvatar: contact.avatarUrl,
          ),
        ),
      );
      return;
    }

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: Color(0xFFF26B21)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nhắn tin cho ${contact.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tin nhắn sẽ được gửi đến hòm thư liên lạc của giáo viên (${contact.email}).',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung cần trao đổi...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF26B21),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gửi tin nhắn đến giáo viên ${contact.name} thành công!'),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _callPhone(String phone) {
    _copyToClipboard(phone, 'số điện thoại');
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final isStudent = user?.isStudent ?? true;
    final isTeacher = user?.isTeacher ?? false;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTeacher
              ? 'Danh bạ Đồng nghiệp'
              : (isAdmin ? 'Danh bạ Toàn trường' : 'Danh sách Giáo viên'),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF26B21),
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: const Color(0xFFF26B21),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(text: isTeacher ? 'Đồng nghiệp' : 'Giáo viên'),
            const Tab(text: 'Nhà trường'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26B21)))
          : TabBarView(
              controller: _tabController,
              children: [
                if (isStudent)
                  _buildStudentTeacherView()
                else if (isTeacher)
                  _buildTeacherColleagueView()
                else
                  _buildAdminTeacherView(),
                _buildSchoolInfoView(),
              ],
            ),
    );
  }

  // =========================================================================
  // 1. STUDENT VIEW
  // =========================================================================
  Widget _buildStudentTeacherView() {
    // Separate homeroom and subject teachers
    Contact? homeroom;
    final List<Contact> subjectTeachers = [];

    for (var teacher in _allTeachers) {
      if (teacher.isHomeroom && homeroom == null) {
        homeroom = teacher;
      } else {
        subjectTeachers.add(teacher);
      }
    }

    return RefreshIndicator(
      color: const Color(0xFFF26B21),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Homeroom Teacher Card (Pinned prominently on top)
          if (homeroom != null) ...[
            const Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 6),
                Text(
                  'Giáo viên Chủ nhiệm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildHomeroomCard(homeroom),
            const SizedBox(height: 20),
          ],

          // Subject Teachers Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giáo viên Bộ môn (${subjectTeachers.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'Học kỳ hiện tại',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (subjectTeachers.isEmpty && homeroom == null)
            _buildEmptyState('Chưa có danh sách giáo viên phụ trách lớp của bạn.')
          else
            ...subjectTeachers.map((t) => _buildSubjectTeacherCard(t)),
        ],
      ),
    );
  }

  Widget _buildHomeroomCard(Contact contact) {
    final hasPhone = contact.phoneNumber.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'GV CHỦ NHIỆM LỚP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFB45309)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(contact, size: 56, borderColor: const Color(0xFFF59E0B)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                          ),
                          if (contact.subject.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Bộ môn: ${contact.subject}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Color(0xFFB45309)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  contact.email,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (hasPhone)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Text(
                                  contact.phoneNumber,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.lock_outline, size: 13, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  'SĐT: Riêng tư (Ẩn bởi GV)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8, color: Color(0xFFFDE68A)),
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: Icons.mail_outline,
                      label: 'Gửi Email',
                      color: const Color(0xFF2563EB),
                      onTap: () => _copyToClipboard(contact.email, 'email'),
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Nhắn tin',
                      color: const Color(0xFFF26B21),
                      onTap: () => _showMessageDialog(contact),
                    ),
                    if (hasPhone)
                      _buildActionButton(
                        icon: Icons.phone_in_talk,
                        label: 'Gọi điện',
                        color: const Color(0xFF16A34A),
                        onTap: () => _callPhone(contact.phoneNumber),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectTeacherCard(Contact contact) {
    final hasPhone = contact.phoneNumber.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(contact, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              if (contact.subject.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    contact.subject,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.email,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 3),
                          if (hasPhone)
                            Text(
                              'SĐT: ${contact.phoneNumber}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.lock_outline, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  'SĐT: Ẩn theo cài đặt riêng tư',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyToClipboard(contact.email, 'email'),
                      icon: const Icon(Icons.mail_outline, size: 15, color: Color(0xFF2563EB)),
                      label: const Text('Email', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showMessageDialog(contact),
                      icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFFF26B21)),
                      label: const Text('Nhắn tin', style: TextStyle(fontSize: 12, color: Color(0xFFF26B21))),
                    ),
                    if (hasPhone) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _callPhone(contact.phoneNumber),
                        icon: const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF16A34A)),
                        label: const Text('Gọi', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TEACHER COLLEAGUE VIEW (with Phone Privacy Switch & Subject Filters)
  // =========================================================================
  Widget _buildTeacherColleagueView() {
    // Extract unique subjects for filtering
    final Set<String> subjects = {'Tất cả'};
    for (var t in _allTeachers) {
      if (t.subject.isNotEmpty) {
        for (var s in t.subject.split(',')) {
          final trimmed = s.trim();
          if (trimmed.isNotEmpty) subjects.add(trimmed);
        }
      }
    }

    final filtered = _allTeachers.where((t) {
      final matchesQuery = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery) ||
          t.subject.toLowerCase().contains(_searchQuery) ||
          t.email.toLowerCase().contains(_searchQuery);

      final matchesSubject = _selectedSubject == 'Tất cả' ||
          t.subject.toLowerCase().contains(_selectedSubject.toLowerCase());

      return matchesQuery && matchesSubject;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFFF26B21),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Phone Privacy Config Card
          _buildPhonePrivacyCard(),
          const SizedBox(height: 14),

          // 2. Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm đồng nghiệp theo tên, môn...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFF26B21), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF26B21), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Subject Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subjects.map((sub) {
                final isSelected = _selectedSubject == sub;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(sub),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF26B21),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFF26B21) : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSubject = sub);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Colleagues Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh bạ Giáo viên (${filtered.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                'Nội bộ trường',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 5. List
          if (filtered.isEmpty)
            _buildEmptyState('Không tìm thấy đồng nghiệp phù hợp với bộ lọc.')
          else
            ...filtered.map((t) => _buildColleagueCard(t)),
        ],
      ),
    );
  }

  Widget _buildPhonePrivacyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _myPhonePublic ? const Color(0xFF86EFAC) : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _myPhonePublic ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _myPhonePublic ? Icons.phone_enabled : Icons.phone_locked,
                  color: _myPhonePublic ? const Color(0xFF16A34A) : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quyền riêng tư Số điện thoại',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cho phép học sinh xem số điện thoại của tôi',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (_isUpdatingPrivacy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF26B21)),
                )
              else
                Switch(
                  value: _myPhonePublic,
                  activeColor: const Color(0xFFF26B21),
                  activeTrackColor: const Color(0xFFFFD7BA),
                  onChanged: _togglePhonePrivacy,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _myPhonePublic
                        ? 'Học sinh trong các lớp bạn giảng dạy hiện có thể thấy số điện thoại của bạn.'
                        : 'Mặc định ẩn số điện thoại đối với học sinh để bảo vệ riêng tư ngoài giờ.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColleagueCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(contact, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              if (contact.isHomeroom)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'GVCN',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  contact.subject.isNotEmpty ? contact.subject : 'Giáo viên',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  contact.email,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (contact.phoneNumber.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  contact.phoneNumber,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, thickness: 0.6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyToClipboard(contact.email, 'email'),
                      icon: const Icon(Icons.mail_outline, size: 14, color: Color(0xFF2563EB)),
                      label: const Text('Email', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                    ),
                    if (contact.phoneNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _callPhone(contact.phoneNumber),
                        icon: const Icon(Icons.phone_in_talk, size: 14, color: Color(0xFF16A34A)),
                        label: const Text('Gọi nội bộ', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. ADMIN VIEW (Full Teacher Directory & Management Actions)
  // =========================================================================
  Widget _buildAdminTeacherView() {
    final filtered = _allTeachers.where((t) {
      return _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery) ||
          t.subject.toLowerCase().contains(_searchQuery) ||
          t.email.toLowerCase().contains(_searchQuery);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFFF26B21),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Admin Stats Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản lý Đội ngũ Giáo viên',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng số: ${_allTeachers.length} cán bộ / giáo viên',
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF26B21),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Toàn quyền',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm giáo viên theo tên, môn, email...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFF26B21), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List of Teachers for Admin
          if (filtered.isEmpty)
            _buildEmptyState('Không có dữ liệu giáo viên phù hợp.')
          else
            ...filtered.map((t) => _buildAdminTeacherCard(t)),
        ],
      ),
    );
  }

  Widget _buildAdminTeacherCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(contact, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Môn: ${contact.subject.isNotEmpty ? contact.subject : "Chưa gán"}',
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey[700], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Email: ${contact.email}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            'SĐT: ${contact.phoneNumber.isNotEmpty ? contact.phoneNumber : "(Chưa cập nhật)"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, thickness: 0.6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chức năng phân công cho giáo viên ${contact.name}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_ind_outlined, size: 14, color: Color(0xFF2563EB)),
                      label: const Text('Phân công', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFF475569)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chỉnh sửa hồ sơ giáo viên ${contact.name}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF475569)),
                      label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. SCHOOL INFO VIEW
  // =========================================================================
  Widget _buildSchoolInfoView() {
    return ListView.separated(
      itemCount: _schoolInfo.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = _schoolInfo[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF2EB),
              radius: 24,
              child: const Icon(Icons.school, color: Color(0xFFF26B21)),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(
                color: Color(0xFFF26B21),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  contact.subject,
                  style: TextStyle(color: Colors.blueGrey[800], fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Email: ${contact.email} • Hotline: ${contact.phoneNumber}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailScreen(contact: contact),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildAvatar(Contact contact, {double size = 48, Color? borderColor}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF2EB),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      child: contact.avatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(contact.avatarUrl, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name.trim()[0].toUpperCase() : 'G',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF26B21),
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
