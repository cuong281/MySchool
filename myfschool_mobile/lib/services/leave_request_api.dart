import 'dart:convert';

import 'package:http/http.dart' as http;

class LeaveRequestApi {
  static final LeaveRequestApi instance = LeaveRequestApi._init();
  LeaveRequestApi._init();

  static const String _baseUrl = 'http://10.0.2.2:8080/api/leave-requests';

  /// Tạo đơn xin phép mới.
  /// Trả về `null` nếu thành công, hoặc chuỗi lỗi nếu thất bại.
  Future<String?> createRequest({
    required int userId,
    required String requestType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'requestType': requestType,
          'fromDate': _formatDate(fromDate),
          'toDate': _formatDate(toDate),
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) return null;

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));
      return data['error'] ??
          data['message'] ??
          'Lỗi không xác định (${response.statusCode})';
    } catch (e) {
      return 'Lỗi kết nối: $e';
    }
  }

  /// Lấy danh sách đơn của một user.
  Future<List<Map<String, dynamic>>> getRequestsByUser(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/$userId');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(decodedBody);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// [Admin] Lấy toàn bộ danh sách đơn.
  Future<List<Map<String, dynamic>>> getAllRequests() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// [Admin] Cập nhật trạng thái đơn.
  Future<bool> updateStatus(
    int requestId,
    String status,
    int processedByUserId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/$requestId/status');
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'processedByUserId': processedByUserId,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
