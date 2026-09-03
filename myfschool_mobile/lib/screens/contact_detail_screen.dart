import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../untils/app_color.dart';
import '../services/user_session.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;
  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final currentUser = UserSession.instance.currentUser;
    final isStudent = currentUser?.role == 'Student' || currentUser?.role == 'STUDENT';
    final hidePhone = isStudent && contact.isTeacher;

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
          'Danh sách chi tiết',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50],
                ),
                child: contact.avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.network(contact.avatarUrl, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person, size: 80, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 20),
            // Name
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF26B21),
              ),
            ),
            const SizedBox(height: 4),
            // Email (small)
            Text(
              contact.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            // Role / Subject
            Text(
              '${contact.role}: ${contact.subject}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 40),
            // Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin liên lạc',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFFF26B21), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (contact.phoneNumber.isNotEmpty && !hidePhone) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFFF26B21), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              contact.phoneNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
