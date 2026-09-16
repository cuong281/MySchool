import 'dart:convert';
import 'package:myfschools/models/attendance.dart';
import 'package:myfschools/models/attendance_summary.dart';
import 'package:myfschools/models/attendance_sheet_model.dart';
import 'package:myfschools/models/attendance_history_model.dart';
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

  /// Lấy bảng danh sách điểm danh của lớp theo tiết/ngày (Side-effect free)
  Future<AttendanceSheetModel?> getAttendanceSheet(
    int classId, {
    int? subjectId,
    required int slotNumber,
    String? date,
  }) async {
    try {
      final params = <String, String>{
        'slotNumber': slotNumber.toString(),
      };
      if (subjectId != null) params['subjectId'] = subjectId.toString();
      if (date != null && date.isNotEmpty) params['attendanceDate'] = date;

      final uri = Uri.parse('$_endpoint/class/$classId/sheet').replace(queryParameters: params);
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return AttendanceSheetModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ghi nhận điểm danh hàng loạt (Batch)
  Future<Map<String, dynamic>> recordBatchAttendance(AttendanceBatchRequest req) async {
    try {
      final uri = Uri.parse('$_endpoint/batch');
      final response = await ApiClient.instance.post(
        uri,
        body: jsonEncode(req.toJson()),
      );

      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        String message = 'Lưu điểm danh thành công';
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
        return {
          'success': true,
          'message': message,
          'data': decoded,
        };
      } else if (response.statusCode == 409) {
        final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        return {
          'success': false,
          'conflict': LeaveConflictError.fromJson(map),
          'message': map['message'] ?? 'Học sinh có đơn nghỉ phép được duyệt.',
        };
      } else {
        final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        return {
          'success': false,
          'status': response.statusCode,
          'message': map['message'] ?? 'Không thể lưu điểm danh (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi kết nối: $e',
      };
    }
  }

  /// Lấy lịch sử và thống kê chuyên cần của một lớp
  Future<AttendanceClassHistoryModel?> getClassAttendanceHistory(
    int classId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) params['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) params['endDate'] = endDate;

      final uri = Uri.parse('$_endpoint/class/$classId/history').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return AttendanceClassHistoryModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// [Teacher/Admin] Ghi nhận điểm danh đơn lẻ
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
