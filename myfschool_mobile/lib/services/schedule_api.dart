import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfschools/models/schedule_model.dart';
import 'package:myfschools/services/user_session.dart';

class ScheduleApi {
  static final ScheduleApi instance = ScheduleApi._init();
  ScheduleApi._init();

  static const String _baseUrl = 'http://10.0.2.2:8080/api/schedules';

  Future<List<ScheduleDayModel>> getStudentSchedule([String? mockUserId]) async {
    try {
      final user = UserSession.instance.currentUser;
      final userId = mockUserId ?? user?.id?.toString() ?? '1';
      final uri = Uri.parse('$_baseUrl/user/$userId');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('Schedule API Status: ${response.statusCode}');
      print('Schedule API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ScheduleDayModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get schedule error: $e');
      return [];
    }
  }

  Future<List<ScheduleDayModel>> getScheduleByClass(int classId) async {
    try {
      final uri = Uri.parse('$_baseUrl/class/$classId');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ScheduleDayModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get schedule by class error: $e');
      return [];
    }
  }
}
