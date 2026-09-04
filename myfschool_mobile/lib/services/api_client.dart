import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfschools/services/user_session.dart';

/// Centralized API client automatically attaching Bearer tokens
/// and handling 401 token refresh retry flow.
class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  static const String baseUrl = 'http://10.0.2.2:8080/api';

  Completer<bool>? _refreshCompleter;

  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    final token = UserSession.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _sendWithRetry(() => http.get(uri, headers: _buildHeaders(headers)));
  }

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _sendWithRetry(() => http.post(uri, headers: _buildHeaders(headers), body: body));
  }

  Future<http.Response> put(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _sendWithRetry(() => http.put(uri, headers: _buildHeaders(headers), body: body));
  }

  Future<http.Response> patch(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _sendWithRetry(() => http.patch(uri, headers: _buildHeaders(headers), body: body));
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _sendWithRetry(() => http.delete(uri, headers: _buildHeaders(headers), body: body));
  }

  static const Duration timeoutDuration = Duration(seconds: 15);

  Future<http.Response> _sendWithRetry(Future<http.Response> Function() requestFn) async {
    var response = await requestFn().timeout(timeoutDuration);

    // If unauthorized and we have a refresh token, try refreshing once
    if (response.statusCode == 401 && UserSession.instance.refreshToken != null) {
      final refreshed = await _performRefreshToken();
      if (refreshed) {
        // Retry original request with newly acquired access token
        response = await requestFn().timeout(timeoutDuration);
      }
    }

    return response;
  }

  Future<bool> _performRefreshToken() async {
    // If a refresh is already in progress, wait for its result
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final currentRefresh = UserSession.instance.refreshToken;
      if (currentRefresh == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final uri = Uri.parse('$baseUrl/auth/refresh-token');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': currentRefresh}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newAccess != null) {
          await UserSession.instance.updateTokens(newAccess, newRefresh);
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      // Refresh failed -> clear session to force re-login
      await UserSession.instance.clear();
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      await UserSession.instance.clear();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
