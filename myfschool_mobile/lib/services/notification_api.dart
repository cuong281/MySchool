import 'dart:convert';
import 'package:myfschools/models/notification_model.dart';
import 'package:myfschools/services/api_client.dart';

class NotificationApi {
  static final NotificationApi instance = NotificationApi._init();
  NotificationApi._init();

  static const String _endpoint = '${ApiClient.baseUrl}/notifications';

  /// Lấy danh sách thông báo của người dùng hiện tại (/me)
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final uri = Uri.parse('$_endpoint/me');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final uri = Uri.parse('$_endpoint/me/unread-count');
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<bool> markAsRead(int notificationId) async {
    try {
      final uri = Uri.parse('$_endpoint/$notificationId/read');
      final response = await ApiClient.instance.patch(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<bool> markAllAsRead() async {
    try {
      final uri = Uri.parse('$_endpoint/me/read-all');
      final response = await ApiClient.instance.patch(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Đăng ký FCM Device Token
  Future<bool> registerDeviceToken(String token, [String deviceType = 'ANDROID']) async {
    try {
      final uri = Uri.parse('$_endpoint/fcm-token');
      final response = await ApiClient.instance.post(
        uri,
        body: jsonEncode({
          'deviceToken': token,
          'deviceType': deviceType,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Hủy đăng ký FCM Device Token khi logout
  Future<bool> unregisterDeviceToken(String token) async {
    try {
      final uri = Uri.parse('$_endpoint/fcm-token?deviceToken=$token');
      final response = await ApiClient.instance.delete(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
