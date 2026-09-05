import 'dart:convert';
import 'package:myfschools/services/api_client.dart';

class ReportApi {
  static ReportApi instance = ReportApi._internal();
  ReportApi._internal() : _client = ApiClient.instance;
  ReportApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<Map<String, dynamic>?> getAdminDashboard({String? academicYear, int? semester}) async {
    final queryParams = <String, String>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      queryParams['academicYear'] = academicYear;
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }

    final baseUri = Uri.parse('${ApiClient.baseUrl}/reports/admin/dashboard');
    final uri = queryParams.isEmpty ? baseUri : baseUri.replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTeacherHomeroomDashboard({String? academicYear, int? semester}) async {
    final queryParams = <String, String>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      queryParams['academicYear'] = academicYear;
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }

    final baseUri = Uri.parse('${ApiClient.baseUrl}/reports/teacher/homeroom');
    final uri = queryParams.isEmpty ? baseUri : baseUri.replace(queryParameters: queryParams);
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
