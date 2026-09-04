import 'dart:convert';
import 'package:myfschools/models/schedule_model.dart';
import 'package:myfschools/services/api_client.dart';

class ScheduleApi {
  static final ScheduleApi instance = ScheduleApi._init();
  ScheduleApi._init();

  static const String _baseUrl = '${ApiClient.baseUrl}/schedules';

  /// Lấy lịch của người dùng hiện tại (/me)
  /// - Học sinh: trả về thời khóa biểu lớp của học sinh
  /// - Giáo viên: trả về lịch giảng dạy của giáo viên (kèm className)
  /// - Admin: trả về lịch lớp mặc định
  Future<List<ScheduleDayModel>> getMySchedule() async {
    try {
      final uri = Uri.parse('$_baseUrl/me');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ScheduleDayModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get my schedule error: $e');
      return [];
    }
  }

  /// Lấy lịch giảng dạy của giáo viên theo teacherId
  Future<List<ScheduleDayModel>> getTeacherSchedule(int teacherId) async {
    try {
      final uri = Uri.parse('$_baseUrl/teacher/$teacherId');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ScheduleDayModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get teacher schedule error: $e');
      return [];
    }
  }

  /// Lấy lịch học theo lớp (ClassID)
  Future<List<ScheduleDayModel>> getScheduleByClass(int classId) async {
    try {
      final uri = Uri.parse('$_baseUrl/class/$classId');
      final response = await ApiClient.instance.get(uri);

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

  /// Lấy lịch học sinh theo UserID (chỉ dùng cho backward compatibility)
  Future<List<ScheduleDayModel>> getStudentSchedule([String? mockUserId]) async {
    if (mockUserId == null) {
      return getMySchedule();
    }
    try {
      final uri = Uri.parse('$_baseUrl/user/$mockUserId');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ScheduleDayModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get student schedule error: $e');
      return [];
    }
  }
}
