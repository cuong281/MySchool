import 'dart:convert';
import 'package:myfschools/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton lưu trữ thông tin user và JWT tokens.
class UserSession {
  static final UserSession instance = UserSession._internal();
  UserSession._internal();

  UserModel? currentUser;
  String? accessToken;
  String? refreshToken;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  /// Lưu thông tin user và tokens từ API response.
  Future<void> setUser(Map<String, dynamic> data) async {
    currentUser = UserModel.fromMap(data);
    accessToken = data['accessToken'] as String?;
    refreshToken = data['refreshToken'] as String?;

    await _saveToPreferences(data);
  }

  /// Cập nhật tokens khi refresh token thành công.
  Future<void> updateTokens(String newAccessToken, String? newRefreshToken) async {
    accessToken = newAccessToken;
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      refreshToken = newRefreshToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString('refreshToken', newRefreshToken);
      }
    } catch (_) {}
  }

  /// Tên đầy đủ theo format "LastName FirstName".
  String get fullName {
    if (currentUser == null) return '';
    final last = currentUser!.lastName;
    final first = currentUser!.firstName;
    return '$last $first'.trim();
  }

  /// Xóa session và tokens khi đăng xuất.
  Future<void> clear() async {
    currentUser = null;
    accessToken = null;
    refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userData');
    } catch (_) {}
  }

  /// Khôi phục session từ SharedPreferences khi khởi động app.
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAccess = prefs.getString('accessToken');
      final storedRefresh = prefs.getString('refreshToken');
      final userDataStr = prefs.getString('userData');

      if (storedAccess != null && storedAccess.isNotEmpty && userDataStr != null) {
        accessToken = storedAccess;
        refreshToken = storedRefresh;
        currentUser = UserModel.fromMap(jsonDecode(userDataStr) as Map<String, dynamic>);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _saveToPreferences(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (accessToken != null) await prefs.setString('accessToken', accessToken!);
      if (refreshToken != null) await prefs.setString('refreshToken', refreshToken!);
      await prefs.setString('userData', jsonEncode(data));
    } catch (_) {}
  }
}
