import 'package:myfschools/models/user_model.dart';

/// Singleton lưu trữ thông tin user đang đăng nhập.
class UserSession {
  static final UserSession instance = UserSession._internal();
  UserSession._internal();

  UserModel? currentUser;

  /// Lưu thông tin user từ API response.
  void setUser(Map<String, dynamic> data) {
    currentUser = UserModel.fromMap(data);
  }

  /// Tên đầy đủ theo format "LastName FirstName".
  String get fullName {
    if (currentUser == null) return '';
    final last = currentUser!.lastName;
    final first = currentUser!.firstName;
    return '$last $first'.trim();
  }

  /// Xóa session khi đăng xuất.
  void clear() {
    currentUser = null;
  }
}
