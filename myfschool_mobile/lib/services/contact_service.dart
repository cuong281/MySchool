import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact_model.dart';

class ContactService {
  static final ContactService instance = ContactService._init();
  ContactService._init();

  static const String _baseUrl = 'http://10.0.2.2:8080/api/contacts';

  Future<List<Contact>> getTeachers(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/user/$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList
            .map((item) => Contact(
                  id: (item['teacherId'] ?? '').toString(),
                  name: item['fullName'] ?? '',
                  email: item['email'] ?? '',
                  phoneNumber: item['phone'] ?? '',
                  role: 'Giáo viên',
                  subject: item['subjectName'] ?? '',
                  avatarUrl: item['avatarUrl'] ?? '',
                  isTeacher: true,
                ))
            .toList();
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  Future<List<Contact>> getSchoolInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Contact(
        id: 'school_1',
        name: 'FPT School - Hà Nội',
        email: 'fptschool@fpt.edu.vn',
        role: 'Nhà trường',
        subject: 'Phòng đào tạo',
        isTeacher: false,
      ),
      Contact(
        id: 'school_2',
        name: 'Phòng Công tác sinh viên',
        email: 'ctsv@fpt.edu.vn',
        role: 'Nhà trường',
        subject: 'Hỗ trợ sinh viên',
        isTeacher: false,
      ),
    ];
  }
}
