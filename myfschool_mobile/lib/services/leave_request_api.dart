import 'dart:convert';
import 'package:myfschools/services/api_client.dart';

class LeaveRequestApi {
  static LeaveRequestApi instance = LeaveRequestApi._init();
  LeaveRequestApi._init();
  LeaveRequestApi();

  static const String _endpoint = '${ApiClient.baseUrl}/leave-requests';

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
      final uri = Uri.parse(_endpoint);
      final response = await ApiClient.instance.post(
        uri,
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

  /// Lấy danh sách đơn của user hiện tại (/me).
  Future<List<Map<String, dynamic>>> getMyRequests() async {
    try {
      final uri = Uri.parse('$_endpoint/me');
      final response = await ApiClient.instance.get(uri);

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

  /// Lấy danh sách đơn của một user.
  Future<List<Map<String, dynamic>>> getRequestsByUser(int userId) async {
    try {
      final uri = Uri.parse('$_endpoint/user/$userId');
      final response = await ApiClient.instance.get(uri);

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
      final uri = Uri.parse(_endpoint);
      final response = await ApiClient.instance.get(uri);

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
    String status, [
    dynamic processedByUserIdOrNote,
    String? adminNote,
  ]) async {
    try {
      final uri = Uri.parse('$_endpoint/$requestId/status');
      String? note;
      if (processedByUserIdOrNote is String) {
        note = processedByUserIdOrNote;
      } else if (adminNote != null) {
        note = adminNote;
      }

      final response = await ApiClient.instance.patch(
        uri,
        body: jsonEncode({
          'status': status,
          if (note != null) 'adminNote': note,
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
