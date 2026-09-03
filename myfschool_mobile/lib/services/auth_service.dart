import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/auth';

  /// Dang nhap bang so dien thoai + mat khau
  /// Tra ve Map user info neu thanh cong, null neu that bai
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
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    // Logic for sign out if needed (e.g., clear session)
  }
}