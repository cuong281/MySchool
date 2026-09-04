import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:myfschools/services/user_session.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/auth';

  /// Dang nhap bang so dien thoai + mat khau.
  /// Luu JWT access token, refresh token va user profile vao UserSession.
  Future<Map<String, dynamic>?> login(String phoneNumber, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl/login');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await UserSession.instance.setUser(data);
        return data;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Lam moi access token bang refresh token hien tai.
  Future<bool> refreshToken() async {
    try {
      final currentRefresh = UserSession.instance.refreshToken;
      if (currentRefresh == null) return false;

      final uri = Uri.parse('$_baseUrl/refresh-token');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': currentRefresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null) {
          await UserSession.instance.updateTokens(newAccess, newRefresh);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('RefreshToken error: $e');
      return false;
    }
  }

  /// Dang xuat: goi backend thu hoi refresh token va xoa local session.
  Future<void> signOut() async {
    try {
      final currentRefresh = UserSession.instance.refreshToken;
      if (currentRefresh != null) {
        final uri = Uri.parse('$_baseUrl/logout');
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refreshToken': currentRefresh}),
        );
      }
    } catch (_) {
      // Ignore network error during logout
    } finally {
      await UserSession.instance.clear();
    }
  }
}