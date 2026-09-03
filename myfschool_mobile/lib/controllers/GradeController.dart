import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfschools/models/grade.dart';

class GradeController {

  // ─ASE URL
  // Khớp với @RequestMapping("/api/grades") trong GradeController.java
  static const String _baseUrl =
      'http://10.0.2.2:8080/api/grades';

  // Header: Jackson (Spring Boot) tự parse khi nhận Content-Type: application/json
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept':       'application/json',
  };

  // GET /api/grades
  // Spring: @GetMapping → getAll() → service.getAll() → repo.findAllWithComputed()

  static Future<List<Grade>> getAllGrades() async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getAllGrades lỗi: ${response.statusCode}');
  }


  // GET /api/grades/{id}
  static Future<Grade> getGradeById(int id) async {
    final uri = Uri.parse('$_baseUrl/$id');     // ID nằm trong path
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy ID $id');
    }
    throw Exception('getGradeById lỗi: ${response.statusCode}');
  }


  // GET /api/grades/user/{userId}
  // Endpoint mới — tìm tất cả điểm của 1 học sinh theo UserID
  static Future<List<Grade>> getGradesByUser(int userId) async {
    final uri = Uri.parse('$_baseUrl/user/$userId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getGradesByUser lỗi: ${response.statusCode}');
  }

  static Future<List<Grade>> getGradesByClass(int classId) async {
    final uri = Uri.parse('$_baseUrl/class/$classId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => Grade.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('getGradesByClass lỗi: ${response.statusCode}');
  }


  // POST /api/grades
  // THAY ĐỔI: Server trả về Grade object đầy đủ thay vì {gradeID:7}
  static Future<Grade> addGrade(Grade grade) async {
    final uri  = Uri.parse(_baseUrl);
    // grade.toJson() KHÔNG gửi gradeID (null → Spring biết đây là INSERT)
    final body = jsonEncode(grade.toJson());

    final response = await http.post(
      uri,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201) {
      // Spring trả 201 Created + Grade object đầy đủ (GradeID + computed columns)
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      // 409 Conflict: học sinh đã có điểm môn này
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Dữ liệu bị trùng lặp');
    }
    throw Exception('addGrade lỗi ${response.statusCode}: ${response.body}');
  }


  // PUT /api/grades/{id}
  // Trả về: Grade object với computed columns mới (AverageScore, GPA4...)

  static Future<Grade> updateGrade(int id, Grade grade) async {
    final uri  = Uri.parse('$_baseUrl/$id');    // ID trong path
    final body = jsonEncode(grade.toJson());

    final response = await http.put(
      uri,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      // Spring trả Grade đã cập nhật với computed columns mới từ DB
      return Grade.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy Grade ID $id');
    }
    throw Exception('updateGrade lỗi: ${response.statusCode}');
  }


  // DELETE /api/grades/{id}

  static Future<bool> deleteGrade(int id) async {
    final uri = Uri.parse('$_baseUrl/$id');     // ID trong path

    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Không tìm thấy ID $id');
    }
    throw Exception('deleteGrade lỗi: ${response.statusCode}');
  }
}