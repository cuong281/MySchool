import 'dart:convert';
import 'package:myfschools/models/grade.dart';
import 'package:myfschools/services/api_client.dart';

class GradeController {

  static const String _endpoint = '${ApiClient.baseUrl}/grades';

  // GET /api/grades
  static Future<List<Grade>> getAllGrades() async {
    final uri = Uri.parse(_endpoint);
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getAllGrades lỗi: ${response.statusCode}');
  }

  // GET /api/grades/me
  static Future<List<Grade>> getMyGrades() async {
    final uri = Uri.parse('$_endpoint/me');
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getMyGrades lỗi: ${response.statusCode}');
  }

  // GET /api/grades/{id}
  static Future<Grade> getGradeById(int id) async {
    final uri = Uri.parse('$_endpoint/$id');
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode == 200) {
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy ID $id');
    }
    throw Exception('getGradeById lỗi: ${response.statusCode}');
  }

  // GET /api/grades/user/{userId}
  static Future<List<Grade>> getGradesByUser(int userId) async {
    final uri = Uri.parse('$_endpoint/user/$userId');
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getGradesByUser lỗi: ${response.statusCode}');
  }

  static Future<List<Grade>> getGradesByClass(int classId) async {
    final uri = Uri.parse('$_endpoint/class/$classId');
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getGradesByClass lỗi: ${response.statusCode}');
  }

  // POST /api/grades
  static Future<Grade> addGrade(Grade grade) async {
    final uri  = Uri.parse(_endpoint);
    final body = jsonEncode(grade.toJson());

    final response = await ApiClient.instance.post(
      uri,
      body: body,
    );

    if (response.statusCode == 201) {
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Dữ liệu bị trùng lặp');
    }
    throw Exception('addGrade lỗi ${response.statusCode}: ${response.body}');
  }

  // PUT /api/grades/{id}
  static Future<Grade> updateGrade(int id, Grade grade) async {
    final uri  = Uri.parse('$_endpoint/$id');
    final body = jsonEncode(grade.toJson());

    final response = await ApiClient.instance.put(
      uri,
      body: body,
    );

    if (response.statusCode == 200) {
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy Grade ID $id');
    }
    throw Exception('updateGrade lỗi: ${response.statusCode}');
  }

  // DELETE /api/grades/{id}
  static Future<bool> deleteGrade(int id) async {
    final uri = Uri.parse('$_endpoint/$id');

    final response = await ApiClient.instance.delete(uri);

    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy ID $id');
    }
    throw Exception('deleteGrade lỗi: ${response.statusCode}');
  }
}