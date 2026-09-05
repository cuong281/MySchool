import 'dart:convert';
import 'package:myfschools/models/teacher_assignment_model.dart';
import 'package:myfschools/services/api_client.dart';

class TeacherAssignmentApi {
  static final TeacherAssignmentApi instance = TeacherAssignmentApi._init();
  TeacherAssignmentApi._init();

  static const String _endpoint = '${ApiClient.baseUrl}/teachers/me/assignments';

  Future<List<TeacherAssignmentModel>> getMyAssignments() async {
    try {
      final uri = Uri.parse(_endpoint);
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => TeacherAssignmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get teacher assignments error: $e');
      return [];
    }
  }
}
