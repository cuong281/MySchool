import 'dart:convert';
import 'package:myfschools/services/api_client.dart';

class ReportApi {
  static final ReportApi instance = ReportApi._internal();
  ReportApi._internal();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>?> getAdminDashboard() async {
    final uri = Uri.parse('${ApiClient.baseUrl}/reports/admin/dashboard');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTeacherHomeroomDashboard() async {
    final uri = Uri.parse('${ApiClient.baseUrl}/reports/teacher/homeroom');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTeacherSubjectStats(int classId, int subjectId) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/reports/teacher/subject-stats?classId=$classId&subjectId=$subjectId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    return null;
  }
}
