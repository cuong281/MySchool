import 'dart:convert';
import '../models/contact_model.dart';
import 'api_client.dart';

class ContactService {
  static final ContactService instance = ContactService._init();
  ContactService._init();

  static const String _baseUrl = '${ApiClient.baseUrl}/contacts';

  Future<List<Contact>> getTeachers([int? userId]) async {
    try {
      final uri = userId != null
          ? Uri.parse('$_baseUrl/user/$userId')
          : Uri.parse('$_baseUrl/me');

      final response = await ApiClient.instance.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((item) => Contact.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  Future<bool> updatePhonePrivacy(bool isPhonePublic) async {
    try {
      final uri = Uri.parse('$_baseUrl/me/phone-privacy');
      final response = await ApiClient.instance.patch(
        uri,
        body: jsonEncode({'isPhonePublic': isPhonePublic}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating phone privacy: $e');
      return false;
    }
  }

  Future<List<Contact>> getSchoolInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Contact(
        id: 'school_1',
        name: 'FPT School - Hà Nội',
        email: 'fptschool@fpt.edu.vn',
        phoneNumber: '024 7300 1866',
        role: 'Nhà trường',
        subject: 'Phòng đào tạo & Tuyển sinh',
        isTeacher: false,
      ),
      Contact(
        id: 'school_2',
        name: 'Phòng Công tác học sinh',
        email: 'cths@fpt.edu.vn',
        phoneNumber: '024 7300 1868',
        role: 'Nhà trường',
        subject: 'Hỗ trợ tâm lý & Học đường',
        isTeacher: false,
      ),
    ];
  }
}
