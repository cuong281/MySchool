import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../services/user_session.dart';
import '../untils/app_color.dart';
import 'contact_detail_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _teachers = [];
  List<Contact> _schoolInfo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = UserSession.instance.currentUser;
    final teachers = await ContactService.instance.getTeachers(user?.id ?? 0);
    
    // Group teachers by ID to avoid duplicates
    final Map<String, Contact> groupedMap = {};
    for (var teacher in teachers) {
      if (groupedMap.containsKey(teacher.id)) {
        final existing = groupedMap[teacher.id]!;
        if (!existing.subject.contains(teacher.subject)) {
          groupedMap[teacher.id] = Contact(
            id: existing.id,
            name: existing.name,
            email: existing.email,
            phoneNumber: existing.phoneNumber,
            role: existing.role,
            subject: '${existing.subject} + ${teacher.subject}',
            avatarUrl: existing.avatarUrl,
            isTeacher: existing.isTeacher,
          );
        }
      } else {
        groupedMap[teacher.id] = teacher;
      }
    }

    final schoolInfo = await ContactService.instance.getSchoolInfo();
    if (mounted) {
      setState(() {
        _teachers = groupedMap.values.toList();
        _schoolInfo = schoolInfo;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Danh sách liên lạc',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF26B21),
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: const Color(0xFFF26B21),
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Giáo viên'),
            Tab(text: 'Nhà trường'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26B21)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContactList(_teachers),
                _buildContactList(_schoolInfo),
              ],
            ),
    );
  }

  Widget _buildContactList(List<Contact> contacts) {
    return ListView.separated(
      itemCount: contacts.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            contact.name,
            style: const TextStyle(
              color: Color(0xFFF26B21),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              contact.subject,
              style: TextStyle(
                color: Colors.blueGrey[800],
                fontSize: 14,
              ),
            ),
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
        );
      },
    );
  }
}
