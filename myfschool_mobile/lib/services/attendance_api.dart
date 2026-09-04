import 'dart:convert';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/services/api_client.dart';

class AttendanceApi {
  static final AttendanceApi instance = AttendanceApi._init();
  AttendanceApi._init();

  static const String _endpoint = '${ApiClient.baseUrl}/attendance';

  /// Lấy danh sách điểm danh của học sinh hiện tại (/me)
  Future<List<AttendanceRecord>> getMyAttendance() async {
    try {
      final uri = Uri.parse('$_endpoint/me');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy tóm tắt tỷ lệ chuyên cần của học sinh hiện tại (/me/summary)
  Future<AttendanceSummary?> getMyAttendanceSummary() async {
    try {
      final uri = Uri.parse('$_endpoint/me/summary');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return AttendanceSummary.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// [Teacher/Admin] Ghi nhận điểm danh
  Future<bool> recordAttendance({
    required int studentId,
    required int classId,
    int? subjectId,
    required DateTime attendanceDate,
    int? slotNumber,
    required String status,
    String? note,
  }) async {
    try {
      final uri = Uri.parse(_endpoint);
      final response = await ApiClient.instance.post(
        uri,
        body: jsonEncode({
          'studentId': studentId,
          'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          'attendanceDate': attendanceDate.toIso8601String().split('T')[0],
          if (slotNumber != null) 'slotNumber': slotNumber,
          'status': status,
          if (note != null) 'note': note,
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
